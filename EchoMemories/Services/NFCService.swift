import Foundation
import CoreNFC

/// Handles reading and writing NDEF URL records on NFC tags (e.g. Timeskey NTAG215/216).
/// Background open is handled by iOS when the tag contains our URL; this service is for
/// foreground write (register garment) and foreground read (scan to find garment).
final class NFCService: NSObject {
    static let shared = NFCService()

    private var writeContinuation: CheckedContinuation<Void, Error>?
    private var writeURL: String?
    private var readContinuation: CheckedContinuation<String?, Error>?
    private var session: NFCNDEFReaderSession?

    private override init() {
        super.init()
    }

    // MARK: - Write URL to tag

    /// Writes a single NDEF URI record to the tag. Hold phone to tag when prompted.
    func writeURLToTag(_ url: String) async throws {
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCError.notSupported
        }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            writeContinuation = cont
            writeURL = url
            session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
            session?.alertMessage = "Hold your iPhone near the NFC tag to write the garment link."
            session?.begin()
        }
    }

    // MARK: - Read URL from tag (foreground)

    /// Reads the first NDEF URI from the tag. Returns the URL string or nil if no URI record.
    func readURLFromTag() async throws -> String? {
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCError.notSupported
        }
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String?, Error>) in
            readContinuation = cont
            session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
            session?.alertMessage = "Hold your iPhone near the NFC tag."
            session?.begin()
        }
    }

    private func invalidateSession(_ message: String? = nil) {
        if let msg = message {
            session?.invalidate(errorMessage: msg)
        } else {
            session?.invalidate()
        }
        session = nil
    }
}

// MARK: - NFCNDEFReaderSessionDelegate

extension NFCService: NFCNDEFReaderSessionDelegate {
    /// Required by the protocol; unused when `didDetect` is implemented (read-write session).
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {}

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            invalidateSession("No tag found.")
            return
        }

        session.connect(to: tag) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.invalidateSession("Connection failed. Try again.")
                if self.writeContinuation != nil {
                    self.writeContinuation?.resume(throwing: error)
                    self.writeContinuation = nil
                }
                if self.readContinuation != nil {
                    self.readContinuation?.resume(throwing: error)
                    self.readContinuation = nil
                }
                return
            }

            if let url = self.writeURL, let cont = self.writeContinuation {
                self.performWrite(url: url, tag: tag, session: session) { result in
                    self.writeURL = nil
                    self.writeContinuation = nil
                    switch result {
                    case .success:
                        session.alertMessage = "Done! You can tap this tag to open this garment."
                        self.invalidateSession()
                        cont.resume()
                    case .failure(let err):
                        self.invalidateSession("Write failed. Hold tag steady.")
                        cont.resume(throwing: err)
                    }
                }
                return
            }

            if self.readContinuation != nil {
                tag.queryNDEFStatus { status, _, error in
                    if let error = error {
                        self.invalidateSession("Read failed.")
                        self.readContinuation?.resume(throwing: error)
                        self.readContinuation = nil
                        return
                    }
                    switch status {
                    case .readOnly, .readWrite:
                        tag.readNDEF { message, error in
                            if let error = error {
                                self.invalidateSession("Read failed.")
                                self.readContinuation?.resume(throwing: error)
                            } else if let msg = message, let record = msg.records.first {
                                let urlString = self.parseURI(from: record)
                                self.invalidateSession()
                                self.readContinuation?.resume(returning: urlString)
                            } else {
                                self.invalidateSession()
                                self.readContinuation?.resume(returning: nil)
                            }
                            self.readContinuation = nil
                        }
                    case .notSupported:
                        self.invalidateSession("Tag not supported or empty.")
                        self.readContinuation?.resume(returning: nil)
                        self.readContinuation = nil
                    @unknown default:
                        self.invalidateSession()
                        self.readContinuation?.resume(returning: nil)
                        self.readContinuation = nil
                    }
                }
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        self.session = nil
        if (writeContinuation != nil) || (readContinuation != nil) {
            let nfcError = error as? NFCReaderError
            if nfcError?.code == .readerSessionInvalidationErrorUserCanceled {
                writeContinuation?.resume(throwing: NFCError.cancelled)
                readContinuation?.resume(throwing: NFCError.cancelled)
            } else {
                writeContinuation?.resume(throwing: error)
                readContinuation?.resume(throwing: error)
            }
            writeContinuation = nil
            readContinuation = nil
            writeURL = nil
        }
    }

    private func performWrite(url: String, tag: NFCNDEFTag, session: NFCNDEFReaderSession, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let payload = NFCNDEFPayload.wellKnownTypeURIPayload(string: url) else {
            completion(.failure(NFCError.badPayload))
            return
        }
        let message = NFCNDEFMessage(records: [payload])
        tag.writeNDEF(message) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    /// Parses NDEF Well Known Type URI record. First byte is prefix code (0x00 = no abbreviation).
    private func parseURI(from record: NFCNDEFPayload) -> String? {
        guard record.typeNameFormat == .nfcWellKnown,
              record.type == Data([0x55]), // "U"
              record.payload.count > 0 else { return nil }
        let payload = record.payload
        let uriData = payload.suffix(from: payload.index(after: payload.startIndex))
        return String(data: Data(uriData), encoding: .utf8)
    }
}

enum NFCError: LocalizedError {
    case notSupported
    case cancelled
    case badPayload

    var errorDescription: String? {
        switch self {
        case .notSupported: return "NFC is not available on this device."
        case .cancelled: return "Scan cancelled."
        case .badPayload: return "Could not create tag payload."
        }
    }
}

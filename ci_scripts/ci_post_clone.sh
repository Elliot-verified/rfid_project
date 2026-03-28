#!/bin/bash
# Xcode Cloud: create Config/Secrets.xcconfig from workflow environment variables.
# In App Store Connect → Xcode Cloud → Workflow → Environment variables, add (mark sensitive):
#   SUPABASE_URL, SUPABASE_ANON_KEY, optional PUBLIC_SHARE_BASE_URL
#
# When both URL and key are set, we always overwrite Secrets.xcconfig so a stale or
# accidentally committed file cannot block injection (fixes "set" but URL does not parse).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$ROOT/Config"
mkdir -p "$CONFIG_DIR"

# Strip CR — pasted ASC / web values sometimes include \r and break URL parsing in the app.
SUPABASE_URL="$(printf '%s' "${SUPABASE_URL:-}" | tr -d '\r')"
SUPABASE_ANON_KEY="$(printf '%s' "${SUPABASE_ANON_KEY:-}" | tr -d '\r')"
PUBLIC_SHARE_BASE_URL="$(printf '%s' "${PUBLIC_SHARE_BASE_URL:-}" | tr -d '\r')"

if [[ -z "$SUPABASE_URL" ]] || [[ -z "$SUPABASE_ANON_KEY" ]]; then
  if [[ -f "$CONFIG_DIR/Secrets.xcconfig" ]]; then
    echo "Config/Secrets.xcconfig present; leaving as-is (workflow env vars not both set)."
    exit 0
  fi
  echo "Note: SUPABASE_URL and/or SUPABASE_ANON_KEY not set. TestFlight builds will have empty Supabase config unless you add Config/Secrets.xcconfig locally or set these env vars in Xcode Cloud."
  exit 0
fi

escape_for_xcconfig_string() {
  # Double-quoted xcconfig value: escape \ and "
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

{
  printf 'SUPABASE_URL = "%s"\n' "$(escape_for_xcconfig_string "$SUPABASE_URL")"
  printf 'SUPABASE_ANON_KEY = "%s"\n' "$(escape_for_xcconfig_string "$SUPABASE_ANON_KEY")"
  if [[ -n "$PUBLIC_SHARE_BASE_URL" ]]; then
    printf 'PUBLIC_SHARE_BASE_URL = "%s"\n' "$(escape_for_xcconfig_string "$PUBLIC_SHARE_BASE_URL")"
  else
    printf 'PUBLIC_SHARE_BASE_URL =\n'
  fi
} > "$CONFIG_DIR/Secrets.xcconfig"

echo "Wrote Config/Secrets.xcconfig from Xcode Cloud environment variables."

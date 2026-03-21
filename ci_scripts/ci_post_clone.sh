#!/bin/bash
# Xcode Cloud: create Config/Secrets.xcconfig from workflow environment variables.
# In App Store Connect → Xcode Cloud → Workflow → Environment variables, add (mark sensitive):
#   SUPABASE_URL, SUPABASE_ANON_KEY, optional PUBLIC_SHARE_BASE_URL

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$ROOT/Config"
mkdir -p "$CONFIG_DIR"

# Skip if local Secrets already present (e.g. committed test double — should not happen)
if [[ -f "$CONFIG_DIR/Secrets.xcconfig" ]]; then
  echo "Config/Secrets.xcconfig already exists; not overwriting."
  exit 0
fi

if [[ -z "${SUPABASE_URL:-}" ]] || [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
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
  if [[ -n "${PUBLIC_SHARE_BASE_URL:-}" ]]; then
    printf 'PUBLIC_SHARE_BASE_URL = "%s"\n' "$(escape_for_xcconfig_string "$PUBLIC_SHARE_BASE_URL")"
  else
    printf 'PUBLIC_SHARE_BASE_URL =\n'
  fi
} > "$CONFIG_DIR/Secrets.xcconfig"

echo "Wrote Config/Secrets.xcconfig from Xcode Cloud environment variables."

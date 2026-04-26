#!/usr/bin/env bash
#
# gog-reauth.sh — Interactive GOG OAuth re-authorization for headless servers
#
# Usage: sudo ./gog-reauth.sh [email] [services]
#   email    — Google account email (default: mgossman71@gmail.com)
#   services — Comma-separated services (default: gmail,calendar,sheets,drive)
#
# Example:
#   sudo ./gog-reauth.sh
#   sudo ./gog-reauth.sh mgossman71@gmail.com gmail,calendar,drive
#
# Notes:
#   - Uses --remote flow (no local browser needed)
#   - Sets GOG_KEYRING_PASSWORD="" to match OpenClaw's config
#   - Handles immutable keyring files (chattr +i protection)
#   - After re-auth, restart the gateway: openclaw gateway restart
#

set -euo pipefail

export GOG_KEYRING_PASSWORD=""

EMAIL="${1:-mgossman71@gmail.com}"
SERVICES="${2:-gmail,calendar,sheets,drive}"
KEYRING_DIR="/root/.config/gogcli/keyring"

echo "============================================"
echo "  GOG OAuth Re-Authorization (Headless)"
echo "============================================"
echo ""
echo "  Account:  ${EMAIL}"
echo "  Services: ${SERVICES}"
echo "  Keyring:  blank passphrase"
echo ""

# --- Step 1: Unlock immutable keyring files ---
echo "[Step 1] Unlocking keyring files..."
for f in "${KEYRING_DIR}"/token:*"${EMAIL}"* 2>/dev/null; do
    if [[ -f "${f}" ]]; then
        chattr -i "${f}" 2>/dev/null && echo "  Unlocked: $(basename "${f}")" || true
    fi
done
echo ""

# --- Step 2: Remove old token ---
echo "[Step 2] Removing old token (if any)..."
gog auth remove "${EMAIL}" 2>/dev/null && echo "  Removed." || echo "  No existing token found."
echo ""

# --- Step 3: Generate the auth URL ---
echo "[Step 3] Generating auth URL..."
echo ""

STEP1_OUTPUT=$(gog auth add "${EMAIL}" --services "${SERVICES}" --remote --step 1 2>&1)

# Extract the auth URL
AUTH_URL=$(echo "${STEP1_OUTPUT}" | grep -oP '(?<=auth_url\s)https://\S+')

if [[ -z "${AUTH_URL}" ]]; then
    echo "ERROR: Failed to extract auth URL from gog output."
    echo "Raw output:"
    echo "${STEP1_OUTPUT}"
    exit 1
fi

echo "--------------------------------------------"
echo "  Open this URL in a browser on your"
echo "  phone or another PC:"
echo "--------------------------------------------"
echo ""
echo "${AUTH_URL}"
echo ""
echo "--------------------------------------------"
echo ""
echo "  1. Authorize with Google"
echo "  2. Click 'Continue'"
echo "  3. The page will FAIL to load — that's OK"
echo "  4. Copy the FULL URL from your browser's"
echo "     address bar (starts with http://127.0.0.1...)"
echo ""

# --- Step 4: Wait for user to paste the callback URL ---
echo "[Step 4] Paste the callback URL below and press Enter:"
echo ""
read -r CALLBACK_URL

if [[ -z "${CALLBACK_URL}" ]]; then
    echo "ERROR: No URL provided. Aborting."
    exit 1
fi

# Basic validation
if [[ "${CALLBACK_URL}" != *"oauth2/callback"* ]]; then
    echo "WARNING: That URL doesn't look like an OAuth callback."
    echo "Expected a URL containing 'oauth2/callback'."
    read -p "Continue anyway? (y/N): " CONFIRM
    if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# --- Step 5: Exchange the code ---
echo ""
echo "[Step 5] Exchanging auth code..."
echo ""

gog auth add "${EMAIL}" --services "${SERVICES}" --remote --step 2 --auth-url "${CALLBACK_URL}"

EXCHANGE_EXIT=$?

echo ""

if [[ ${EXCHANGE_EXIT} -eq 0 ]]; then
    echo "============================================"
    echo "  Auth exchange completed!"
    echo "============================================"
else
    echo "============================================"
    echo "  ERROR: Auth exchange failed (exit ${EXCHANGE_EXIT})"
    echo "  The auth code may have expired (5 min limit)."
    echo "  Re-run this script to try again."
    echo "============================================"
    exit 1
fi

# --- Step 6: Verify ---
echo ""
echo "[Step 6] Verifying..."
echo ""
gog auth list

# --- Step 7: Re-lock keyring files ---
echo ""
echo "[Step 7] Locking keyring files (immutable)..."
for f in "${KEYRING_DIR}"/token:*"${EMAIL}"*; do
    if [[ -f "${f}" ]]; then
        chattr +i "${f}" && echo "  Locked: $(basename "${f}")" || echo "  WARN: Could not lock $(basename "${f}")"
    fi
done

echo ""
echo "============================================"
echo "  Done! Tokens are verified and locked."
echo ""
echo "  Next step: restart the OpenClaw gateway"
echo "    openclaw gateway restart"
echo "============================================"

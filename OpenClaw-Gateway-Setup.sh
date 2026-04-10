#!/usr/bin/env bash
# ==============================================================================
# OpenClaw Gateway - Root Systemd Setup Script
# ==============================================================================
# Sets up the systemd user session for root so that native OpenClaw CLI
# commands (openclaw gateway start/stop/restart/status) work correctly
# on headless servers where root is the primary user.
#
# Problem: OpenClaw uses systemctl --user internally, which requires a
#          D-Bus session bus and XDG_RUNTIME_DIR. These are not available
#          by default when running as root on headless servers.
#
# Usage:   chmod +x setup-openclaw-gateway-root.sh
#          ./setup-openclaw-gateway-root.sh
#
# Prerequisites:
#   - OpenClaw already installed (openclaw --version works)
#   - Running as root
#   - systemd-based Linux distribution
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------- Pre-flight checks ----------

if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root."
    exit 1
fi

if ! command -v openclaw &>/dev/null; then
    error "OpenClaw is not installed or not in PATH."
    error "Install it first: curl -fsSL https://openclaw.ai/install.sh | bash"
    exit 1
fi

OPENCLAW_VERSION=$(openclaw --version 2>/dev/null | head -1 || echo "unknown")
info "OpenClaw version: ${OPENCLAW_VERSION}"

# ---------- Step 1: Ensure systemd-logind is running ----------

info "Checking systemd-logind..."
if ! systemctl is-active --quiet systemd-logind 2>/dev/null; then
    warn "systemd-logind is not running. Enabling..."
    systemctl enable --now systemd-logind
    sleep 2
    if systemctl is-active --quiet systemd-logind; then
        info "systemd-logind started successfully."
    else
        error "Failed to start systemd-logind. Cannot proceed."
        exit 1
    fi
else
    info "systemd-logind is already running."
fi

# ---------- Step 2: Enable linger for root ----------

info "Enabling loginctl linger for root..."
loginctl enable-linger root
info "Linger enabled."

# ---------- Step 3: Create runtime directory ----------

RUNTIME_DIR="/run/user/0"
info "Setting up runtime directory: ${RUNTIME_DIR}"
mkdir -p "${RUNTIME_DIR}"
chmod 700 "${RUNTIME_DIR}"

# ---------- Step 4: Set environment variables for current session ----------

export XDG_RUNTIME_DIR="${RUNTIME_DIR}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${RUNTIME_DIR}/bus"

info "Environment variables set for current session."

# ---------- Step 5: Persist environment variables in shell profiles ----------

BASHRC="/root/.bashrc"
PROFILE="/root/.profile"

ENV_BLOCK='# --- OpenClaw Gateway: systemd user session for root ---
export XDG_RUNTIME_DIR=/run/user/0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/0/bus
# --- End OpenClaw Gateway ---'

add_env_to_file() {
    local target="$1"
    if [[ -f "$target" ]] && grep -q "OpenClaw Gateway: systemd user session" "$target" 2>/dev/null; then
        warn "Environment block already present in ${target}, skipping."
    else
        echo "" >> "$target"
        echo "$ENV_BLOCK" >> "$target"
        info "Environment variables added to ${target}."
    fi
}

add_env_to_file "$BASHRC"
add_env_to_file "$PROFILE"

# ---------- Step 6: Verify systemctl --user works ----------

info "Testing systemctl --user..."
if systemctl --user status &>/dev/null; then
    info "systemctl --user is operational."
else
    # Sometimes the user manager needs a moment after linger is enabled
    warn "systemctl --user not ready yet. Waiting 5 seconds..."
    sleep 5
    if systemctl --user status &>/dev/null; then
        info "systemctl --user is operational after retry."
    else
        error "systemctl --user still not working."
        error "Try logging out and back in, then run: openclaw gateway install"
        exit 1
    fi
fi

# ---------- Step 7: Clean up any stale user-level service ----------

USER_SERVICE_DIR="/root/.config/systemd/user"
if [[ -f "${USER_SERVICE_DIR}/openclaw-gateway.service" ]]; then
    warn "Found existing user-level service. Stopping and removing..."
    systemctl --user stop openclaw-gateway.service 2>/dev/null || true
    systemctl --user disable openclaw-gateway.service 2>/dev/null || true
    rm -f "${USER_SERVICE_DIR}/openclaw-gateway.service"
    systemctl --user daemon-reload
    info "Stale user-level service cleaned up."
fi

# ---------- Step 8: Clean up any stale system-level service ----------

SYSTEM_SERVICE="/etc/systemd/system/openclaw-gateway.service"
if [[ -f "$SYSTEM_SERVICE" ]]; then
    warn "Found system-level service at ${SYSTEM_SERVICE}. Removing to avoid conflicts..."
    systemctl stop openclaw-gateway.service 2>/dev/null || true
    systemctl disable openclaw-gateway.service 2>/dev/null || true
    rm -f "$SYSTEM_SERVICE"
    systemctl daemon-reload
    info "Stale system-level service cleaned up."
fi

# ---------- Step 9: Kill any lingering gateway processes ----------

info "Checking for lingering gateway processes..."
if pgrep -f "openclaw.*gateway" &>/dev/null; then
    warn "Found running gateway processes. Killing..."
    pkill -f "openclaw.*gateway" || true
    sleep 2
    info "Lingering processes cleaned up."
else
    info "No lingering gateway processes found."
fi

# ---------- Step 10: Install gateway via OpenClaw CLI ----------

info "Installing OpenClaw gateway service..."
if openclaw gateway install 2>&1; then
    info "Gateway service installed successfully."
else
    error "Gateway install failed. Check the output above."
    exit 1
fi

# ---------- Step 11: Start the gateway ----------

info "Starting OpenClaw gateway..."
if openclaw gateway start 2>&1; then
    info "Gateway started."
else
    warn "Gateway start returned an error. Checking status..."
fi

sleep 3

# ---------- Step 12: Verify ----------

info "Verifying gateway status..."
openclaw gateway status 2>&1 || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  OpenClaw Gateway Setup Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  Native CLI commands now work as root:"
echo "    openclaw gateway start"
echo "    openclaw gateway stop"
echo "    openclaw gateway restart"
echo "    openclaw gateway status"
echo ""
echo "  View live logs:"
echo "    openclaw logs --follow"
echo "    journalctl --user -u openclaw-gateway.service -f"
echo ""
echo -e "${YELLOW}  NOTE: If you open a new SSH session and commands fail,${NC}"
echo -e "${YELLOW}  source your profile first: source ~/.bashrc${NC}"
echo ""

#!/usr/bin/env bash
# PayPal App Switch Sample Apps — Zero-Config Setup
#
# Clone -> Run -> Payment in under 90 seconds.
#
# Usage: ./setup.sh

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────

GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Banner ────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}================================================${RESET}"
echo -e "${BOLD}${CYAN}  PayPal App Switch Sample Apps${RESET}"
echo -e "${BOLD}${CYAN}================================================${RESET}"
echo ""
echo -e "  Clone -> Run -> Payment in under 90 seconds."
echo ""

# ── Platform selection ────────────────────────────────────────────────────────

echo -e "${BOLD}Which platform?${RESET}"
echo ""
echo "  [1] iOS"
echo "  [2] Android"
echo "  [3] Server only"
echo ""
read -rp "Choose (1/2/3): " CHOICE

case "$CHOICE" in
    1)
        PLATFORM="ios"
        ;;
    2)
        PLATFORM="android"
        ;;
    3)
        PLATFORM="server"
        ;;
    *)
        echo -e "${RED}Invalid choice. Please enter 1, 2, or 3.${RESET}"
        exit 1
        ;;
esac

echo ""

# ── Run platform setup ───────────────────────────────────────────────────────

case "$PLATFORM" in
    ios)
        echo -e "${BOLD}Setting up iOS...${RESET}"
        echo ""

        # Server setup first
        echo -e "${CYAN}--- Server ---${RESET}"
        cd "$SCRIPT_DIR/demo-server"
        npm install --silent 2>/dev/null
        node setup.js

        # iOS setup
        echo -e "${CYAN}--- iOS ---${RESET}"
        cd "$SCRIPT_DIR/direct-api-app-switch/ios"
        make setup

        echo ""
        echo -e "${BOLD}${GREEN}================================================${RESET}"
        echo -e "${BOLD}${GREEN}  iOS Setup Complete${RESET}"
        echo -e "${BOLD}${GREEN}================================================${RESET}"
        echo ""
        echo -e "${BOLD}Quick Start:${RESET}"
        echo -e "  1. Start the server:"
        echo -e "     ${CYAN}cd demo-server && npm start${RESET}"
        echo ""
        echo -e "  2. Edit ${CYAN}direct-api-app-switch/ios/Config.plist${RESET} with your credentials"
        echo ""
        echo -e "  3. Open the Xcode project:"
        echo -e "     ${CYAN}cd direct-api-app-switch/ios && make run${RESET}"
        echo ""
        echo -e "  4. Select ${CYAN}iPhone 16${RESET} simulator, press ${CYAN}Cmd+R${RESET}"
        echo ""
        echo -e "  5. Tap ${CYAN}Pay with PayPal${RESET} to test App Switch"
        echo ""
        ;;

    android)
        echo -e "${BOLD}Setting up Android...${RESET}"
        echo ""

        # Server setup first
        echo -e "${CYAN}--- Server ---${RESET}"
        cd "$SCRIPT_DIR/demo-server"
        npm install --silent 2>/dev/null
        node setup.js

        # Android setup
        echo -e "${CYAN}--- Android ---${RESET}"
        cd "$SCRIPT_DIR/direct-api-app-switch/android"
        bash setup.sh

        echo ""
        echo -e "${BOLD}${GREEN}================================================${RESET}"
        echo -e "${BOLD}${GREEN}  Android Setup Complete${RESET}"
        echo -e "${BOLD}${GREEN}================================================${RESET}"
        echo ""
        echo -e "${BOLD}Quick Start:${RESET}"
        echo -e "  1. Start the server:"
        echo -e "     ${CYAN}cd demo-server && npm start${RESET}"
        echo ""
        echo -e "  2. Open ${CYAN}direct-api-app-switch/android/${RESET} in Android Studio"
        echo ""
        echo -e "  3. Wait for Gradle sync, select a device (API 26+)"
        echo ""
        echo -e "  4. Press ${CYAN}Run${RESET} (Shift+F10)"
        echo ""
        echo -e "  5. Tap ${CYAN}Pay with PayPal${RESET} to test App Switch"
        echo ""
        ;;

    server)
        echo -e "${BOLD}Setting up server...${RESET}"
        echo ""

        cd "$SCRIPT_DIR/demo-server"
        npm install --silent 2>/dev/null
        node setup.js

        echo ""
        echo -e "${BOLD}${GREEN}================================================${RESET}"
        echo -e "${BOLD}${GREEN}  Server Setup Complete${RESET}"
        echo -e "${BOLD}${GREEN}================================================${RESET}"
        echo ""
        echo -e "${BOLD}Quick Start:${RESET}"
        echo -e "  1. Start the server:"
        echo -e "     ${CYAN}cd demo-server && npm start${RESET}"
        echo ""
        echo -e "  2. The server runs on ${CYAN}http://localhost:3000${RESET}"
        echo ""
        echo -e "  3. API endpoints:"
        echo -e "     ${CYAN}POST /api/orders${RESET}        — Create order"
        echo -e "     ${CYAN}POST /api/orders/:id/capture${RESET} — Capture payment"
        echo ""
        ;;
esac

# PayPal App Switch iOS Sample — Zero-Config Setup
#
# Usage:
#   make first-run   — full setup + build + open Xcode (start here)
#   make setup       — create Config.plist from example
#   make build       — build for iPhone simulator
#   make run         — open the Xcode project

# ── Config ────────────────────────────────────────────────────────────────────

PROJECT_DIR  := AppSwitchTest
PROJECT      := $(PROJECT_DIR)/AppSwitchTest.xcodeproj
SCHEME       := AppSwitchTest
CONFIG_FILE  := Config.plist
CONFIG_EXAMPLE := Config.plist.example
DESTINATION  := platform=iOS Simulator,name=iPhone 16,OS=latest
DASHBOARD_URL := https://developer.paypal.com/dashboard/applications/sandbox

# ANSI colors
GREEN  := \033[32m
YELLOW := \033[33m
CYAN   := \033[36m
RED    := \033[31m
BOLD   := \033[1m
RESET  := \033[0m

# ── Targets ───────────────────────────────────────────────────────────────────

.PHONY: setup build run first-run help

help: ## Show available targets
	@echo ""
	@echo "$(BOLD)$(CYAN)PayPal App Switch iOS Sample$(RESET)"
	@echo ""
	@echo "  make first-run  — Full setup + build + open Xcode"
	@echo "  make setup      — Create Config.plist from example"
	@echo "  make build      — Build for iPhone 16 simulator"
	@echo "  make run        — Open the Xcode project"
	@echo ""

setup: ## Copy Config.plist.example to Config.plist and print instructions
	@if [ -f "$(CONFIG_FILE)" ]; then \
		echo "$(GREEN)Config.plist already exists.$(RESET)"; \
	else \
		if [ -f "$(CONFIG_EXAMPLE)" ]; then \
			cp "$(CONFIG_EXAMPLE)" "$(CONFIG_FILE)"; \
			echo "$(GREEN)Created Config.plist from Config.plist.example.$(RESET)"; \
		else \
			echo "$(RED)Config.plist.example not found.$(RESET)"; \
			exit 1; \
		fi; \
	fi
	@echo ""
	@echo "$(BOLD)Next steps:$(RESET)"
	@echo "  1. Open $(CYAN)Config.plist$(RESET) in a text editor"
	@echo "  2. Set $(CYAN)PAYPAL_CLIENT_ID$(RESET) and $(CYAN)PAYPAL_CLIENT_SECRET$(RESET)"
	@echo "     Get credentials at: $(CYAN)$(DASHBOARD_URL)$(RESET)"
	@echo "  3. Run $(CYAN)make build$(RESET) to build the app"
	@echo ""

build: ## Build for iPhone simulator
	@echo "$(BOLD)Building $(SCHEME) for simulator...$(RESET)"
	@xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-configuration Debug \
		build \
		2>&1 | tail -20
	@if [ $$? -eq 0 ]; then \
		echo ""; \
		echo "$(GREEN)Build succeeded.$(RESET)"; \
	else \
		echo ""; \
		echo "$(RED)Build failed. Check the output above.$(RESET)"; \
		exit 1; \
	fi

run: ## Open the Xcode project
	@echo "$(CYAN)Opening Xcode...$(RESET)"
	@open "$(PROJECT)"

first-run: setup build run ## Full setup: config + build + open Xcode
	@echo ""
	@echo "$(BOLD)$(GREEN)iOS setup complete.$(RESET)"
	@echo ""
	@echo "$(BOLD)Quick Start:$(RESET)"
	@echo "  1. The project is open in Xcode"
	@echo "  2. Select the $(CYAN)iPhone 16$(RESET) simulator"
	@echo "  3. Press $(CYAN)Cmd+R$(RESET) to run"
	@echo "  4. Tap $(CYAN)Pay with PayPal$(RESET) to test App Switch"
	@echo ""

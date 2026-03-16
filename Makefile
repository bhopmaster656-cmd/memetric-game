.PHONY: build serve clean install-rojo help

# Default target
help: ## Show this help message
	@echo ""
	@echo "NEON SLICE - Available Commands"
	@echo "==============================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-15s %s\n", $$1, $$2}'
	@echo ""

build: ## Build NeonSlice.rbxlx place file (open in Roblox Studio)
	@echo "Building NeonSlice.rbxlx ..."
	rojo build default.project.json -o NeonSlice.rbxlx
	@echo "[OK] Build complete! Open NeonSlice.rbxlx in Roblox Studio."

serve: ## Start Rojo live sync server (connect from Studio plugin)
	@echo "Starting Rojo server..."
	@echo "Connect from Roblox Studio via the Rojo plugin."
	@echo "Press Ctrl+C to stop."
	@echo ""
	rojo serve

clean: ## Remove built files
	rm -f NeonSlice.rbxlx
	rm -rf build/
	@echo "[OK] Cleaned build artifacts."

install-rojo: ## Install Rojo via Aftman
	aftman install
	@echo "[OK] Rojo installed."

install-plugin: ## Install Rojo plugin into Roblox Studio
	rojo plugin install
	@echo "[OK] Rojo plugin installed in Roblox Studio."

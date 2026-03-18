.PHONY: install build serve clean

# Install Rojo (and any other tools) via Aftman
install:
	aftman install

# Build the Roblox place file
build:
	rojo build default.project.json -o MemetricFishing.rbxlx

# Live-sync with Roblox Studio (keeps Studio in sync while you edit)
serve:
	rojo serve

clean:
	rm -f MemetricFishing.rbxlx

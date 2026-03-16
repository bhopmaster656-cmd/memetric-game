#!/usr/bin/env bash
set -e

echo "======================================="
echo "  NEON SLICE - Build Game File"
echo "======================================="
echo

if ! command -v rojo &> /dev/null; then
    echo "[ERROR] Rojo is not installed or not in PATH."
    echo
    echo "Install Rojo:"
    echo "  1. Download from https://github.com/rojo-rbx/rojo/releases"
    echo "  2. Or install via Aftman: aftman install"
    echo
    exit 1
fi

echo "Building NeonSlice.rbxlx ..."
rojo build default.project.json -o NeonSlice.rbxlx

echo
echo "[OK] Build successful!"
echo "[OK] Open NeonSlice.rbxlx in Roblox Studio to play."
echo

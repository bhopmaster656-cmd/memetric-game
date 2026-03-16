@echo off
echo =======================================
echo   NEON SLICE - Live Sync Server
echo =======================================
echo.

where rojo >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Rojo is not installed or not in PATH.
    echo.
    echo Install Rojo:
    echo   1. Download from https://github.com/rojo-rbx/rojo/releases
    echo   2. Or install via Aftman: aftman install
    echo.
    pause
    exit /b 1
)

echo Starting Rojo server...
echo.
echo Once the server is running:
echo   1. Open Roblox Studio
echo   2. Create a new Baseplate project
echo   3. Click the Rojo plugin button
echo   4. Click Connect
echo   5. Press Play to test!
echo.
echo Press Ctrl+C to stop the server.
echo.

rojo serve

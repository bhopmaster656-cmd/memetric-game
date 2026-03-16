@echo off
echo =======================================
echo   NEON SLICE - Build Game File
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

echo Building NeonSlice.rbxlx ...
rojo build default.project.json -o NeonSlice.rbxlx

if %ERRORLEVEL% equ 0 (
    echo.
    echo [OK] Build successful!
    echo [OK] Open NeonSlice.rbxlx in Roblox Studio to play.
    echo.
) else (
    echo.
    echo [ERROR] Build failed. Check the error messages above.
    echo.
)

pause

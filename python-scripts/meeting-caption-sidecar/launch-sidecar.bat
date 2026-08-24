@echo off
REM Launch Meeting Caption Sidecar from this folder (works with desktop shortcuts too).
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo Virtual environment not found.
    echo Run setup first from PowerShell:
    echo   python -m venv .venv
    echo   .\.venv\Scripts\Activate.ps1
    echo   pip install -r requirements.txt
    pause
    exit /b 1
)

".venv\Scripts\python.exe" sidecar.py
if errorlevel 1 (
    echo.
    echo Sidecar closed with an error. Read the message above.
    pause
)

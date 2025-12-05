@echo off
chcp 65001 >nul
title Test Puppeteer
color 0B
cls
echo.
echo ========================================
echo   Test Puppeteer Installation
echo ========================================
echo.

cd /d "%~dp0"

echo [1] Checking puppeteer-core installation...
call npm list puppeteer-core
if errorlevel 1 (
    echo [ERROR] puppeteer-core not found
    echo Please run: npm install puppeteer-core
    pause
    exit /b 1
)
echo [OK] puppeteer-core is installed
echo.

echo [2] Checking Chrome installation...
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    echo [OK] Chrome found at: C:\Program Files\Google\Chrome\Application\chrome.exe
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    echo [OK] Chrome found at: C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
) else (
    echo [WARN] Chrome not found in default locations
    echo Please install Chrome or set CHROME_PATH environment variable
)
echo.

echo ========================================
echo   Ready to Test!
echo ========================================
echo.
echo Next steps:
echo 1. Restart backend service
echo 2. Submit a Feishu document link
echo 3. Check backend console for Puppeteer logs
echo.
pause



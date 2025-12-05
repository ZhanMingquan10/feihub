@echo off
chcp 65001 >nul
title Install Puppeteer
color 0A
cls
echo.
echo ========================================
echo   Install Puppeteer
echo ========================================
echo.
echo Puppeteer will download Chromium browser
echo This may take a few minutes, please wait...
echo.
pause

cd /d "%~dp0"

echo [1] Installing puppeteer-core...
echo Note: This requires Chrome browser to be installed on your system
echo It will NOT download Chromium automatically
echo.
call npm install puppeteer-core@^24.15.0
if errorlevel 1 (
    echo [ERROR] Puppeteer installation failed
    pause
    exit /b 1
)
echo [OK] Puppeteer installed successfully
echo.

echo ========================================
echo   Installation Complete!
echo ========================================
echo.
echo IMPORTANT: You need to have Chrome browser installed
echo Chrome path: C:\Program Files\Google\Chrome\Application\chrome.exe
echo.
echo If Chrome is installed in a different location, set CHROME_PATH:
echo set CHROME_PATH=C:\Your\Chrome\Path\chrome.exe
echo.
echo You can now restart the backend service
echo.
pause


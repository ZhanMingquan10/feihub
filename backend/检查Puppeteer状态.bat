@echo off
chcp 65001 >nul
title Check Puppeteer Status
color 0B
cls
echo.
echo ========================================
echo   Check Puppeteer Status
echo ========================================
echo.

cd /d "%~dp0"

echo [1] Check puppeteer-core installation...
npm list puppeteer-core 2>nul
if errorlevel 1 (
    echo [ERROR] puppeteer-core not installed
    echo Please run: npm install puppeteer-core
) else (
    echo [OK] puppeteer-core is installed
)
echo.

echo [2] Check Chrome installation...
set CHROME_FOUND=0
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    echo [OK] Chrome found at: C:\Program Files\Google\Chrome\Application\chrome.exe
    set CHROME_FOUND=1
) else (
    if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
        echo [OK] Chrome found at: C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
        set CHROME_FOUND=1
    ) else (
        echo [WARN] Chrome not found in default locations
    )
)

if "%CHROME_PATH%"=="" (
    echo [INFO] CHROME_PATH environment variable not set
) else (
    echo [INFO] CHROME_PATH is set to: %CHROME_PATH%
    if exist "%CHROME_PATH%" (
        echo [OK] Chrome found at CHROME_PATH
        set CHROME_FOUND=1
    ) else (
        echo [ERROR] Chrome not found at CHROME_PATH
    )
)
echo.

if %CHROME_FOUND%==0 (
    echo ========================================
    echo   Chrome Not Found!
    echo ========================================
    echo.
    echo Please install Google Chrome:
    echo https://www.google.com/chrome/
    echo.
    echo Or set CHROME_PATH environment variable
    echo pointing to chrome.exe
    echo.
) else (
    echo ========================================
    echo   Ready to Use Puppeteer!
    echo ========================================
    echo.
    echo Puppeteer should work now
    echo Restart backend service and test
    echo.
)

echo.
echo Press any key to exit...
pause >nul


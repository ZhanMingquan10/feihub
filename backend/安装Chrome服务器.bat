@echo off
chcp 65001 >nul
title Install Chrome for Server
color 0B
cls
echo.
echo ========================================
echo   Chrome Installation Guide
echo ========================================
echo.
echo This script is for LOCAL development
echo For server deployment, see: 服务器部署指南.md
echo.
echo ========================================
echo   Local Development
echo ========================================
echo.
echo For local development on Windows:
echo 1. Download and install Google Chrome
echo    https://www.google.com/chrome/
echo.
echo 2. Chrome will be auto-detected at:
echo    C:\Program Files\Google\Chrome\Application\chrome.exe
echo.
echo 3. If Chrome is installed elsewhere, set environment variable:
echo    set CHROME_PATH=C:\Your\Chrome\Path\chrome.exe
echo.
echo ========================================
echo   Server Deployment (Linux)
echo ========================================
echo.
echo For Ubuntu/Debian server:
echo   sudo apt-get install -y google-chrome-stable
echo.
echo For CentOS/RHEL server:
echo   sudo yum install -y chromium
echo.
echo Then set environment variable:
echo   export CHROME_PATH=/usr/bin/google-chrome-stable
echo.
echo ========================================
echo.
echo See 服务器部署指南.md for detailed instructions
echo.
pause



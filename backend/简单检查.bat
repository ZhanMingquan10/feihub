@echo off
title Simple Check
cd /d "%~dp0"
echo Checking puppeteer-core...
npm list puppeteer-core
echo.
echo Checking Chrome...
dir "C:\Program Files\Google\Chrome\Application\chrome.exe" 2>nul || dir "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" 2>nul || echo Chrome not found
echo.
pause



@echo off
title Backend Logs
color 0A
cls
echo.
echo ========================================
echo   Backend Service Logs
echo ========================================
echo.
echo Please check the backend console window
echo for detailed logs about Puppeteer status
echo.
echo Look for these messages:
echo.
echo [OK] "[爬取] ✅ Puppeteer 可用，将使用 Puppeteer 方案"
echo [ERROR] "[爬取] ⚠️ Puppeteer 不可用，将使用 cheerio 方案"
echo.
echo When you submit a document, you should see:
echo "[爬取] 尝试使用 Puppeteer 获取飞书文档..."
echo "[Puppeteer] 开始获取飞书文档: ..."
echo.
echo ========================================
echo.
pause



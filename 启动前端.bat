@echo off
chcp 65001 >nul
title FeiHub Frontend
color 0A
cls
echo.
echo ========================================
echo   FeiHub 前端服务
echo ========================================
echo.

cd /d "%~dp0"

echo [检查] 检查依赖包...
if not exist node_modules (
    echo 首次运行，正在安装依赖（需要几分钟）...
    call npm install
    if errorlevel 1 (
        echo [错误] 依赖安装失败
        pause
        exit /b 1
    )
    echo [OK] 依赖已安装
) else (
    echo [OK] 依赖已安装
)
echo.

echo ========================================
echo   启动前端开发服务器...
echo ========================================
echo.
echo 前端地址: http://localhost:5173
echo 后端地址: http://localhost:4000
echo.
echo 按 Ctrl+C 停止服务
echo ========================================
echo.

call npm run dev



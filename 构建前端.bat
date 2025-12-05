@echo off
chcp 65001 >nul
title FeiHub 构建前端
color 0A
cls
echo.
echo ========================================
echo   FeiHub 构建前端
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
echo   开始构建前端...
echo ========================================
echo.

call npm run build

if errorlevel 1 (
    echo.
    echo [错误] 构建失败
    pause
    exit /b 1
) else (
    echo.
    echo [成功] 构建完成！
    echo.
    echo 构建输出目录: dist
    echo.
    echo 下一步：将 dist 文件夹上传到服务器
    echo.
)

pause


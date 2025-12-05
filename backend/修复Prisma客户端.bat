@echo off
chcp 65001 >nul
title Fix Prisma Client
color 0A
cls
echo.
echo ========================================
echo   修复 Prisma 客户端
echo ========================================
echo.

cd /d "%~dp0"

echo [步骤 1] 停止可能占用文件的服务...
echo 请确保后端服务已停止（按 Ctrl+C 停止）
echo.
pause

echo [步骤 2] 删除旧的 Prisma 客户端文件...
if exist node_modules\.prisma (
    echo 正在删除 .prisma 目录...
    timeout /t 2 /nobreak >nul
    rmdir /s /q node_modules\.prisma
    if errorlevel 1 (
        echo [警告] 无法删除，可能文件被占用
        echo 请手动关闭所有相关程序后重试
    ) else (
        echo [OK] 已删除
    )
)
echo.

echo [步骤 3] 重新生成 Prisma 客户端...
call npx prisma generate
if errorlevel 1 (
    echo [错误] 生成失败，尝试强制重新安装...
    call npm install @prisma/client --force
    call npx prisma generate
    if errorlevel 1 (
        echo [严重错误] 仍然失败
        echo.
        echo 解决方案：
        echo 1. 关闭所有 Node.js 进程
        echo 2. 关闭 VS Code 或其他编辑器
        echo 3. 以管理员身份运行此脚本
        pause
        exit /b 1
    )
)
echo [OK] Prisma 客户端已生成
echo.

echo ========================================
echo   修复完成！
echo ========================================
echo.
echo 现在可以重新启动后端服务了
echo.
pause



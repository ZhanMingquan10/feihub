@echo off
chcp 65001 >nul
title Simple Start
color 0A
cls
echo.
echo ========================================
echo   最简单启动方式
echo ========================================
echo.

cd /d "%~dp0"

echo [步骤 1] 删除 node_modules 和 package-lock.json...
if exist node_modules (
    rmdir /s /q node_modules
)
if exist package-lock.json (
    del /q package-lock.json
)
echo [OK] 已清理
echo.

echo [步骤 2] 重新安装所有依赖（这需要几分钟）...
call npm install
if errorlevel 1 (
    echo [错误] 依赖安装失败
    pause
    exit /b 1
)
echo [OK] 依赖已安装
echo.

echo [步骤 3] 生成 Prisma 客户端...
call npx prisma generate
if errorlevel 1 (
    echo [错误] Prisma 生成失败
    pause
    exit /b 1
)
echo [OK] Prisma 客户端已生成
echo.

echo [步骤 4] 初始化数据库...
call npx prisma migrate deploy
if errorlevel 1 (
    call npx prisma db push
    if errorlevel 1 (
        echo [警告] 数据库初始化失败，但继续启动
    ) else (
        echo [OK] 数据库已初始化
    )
) else (
    echo [OK] 数据库已就绪
)
echo.

echo ========================================
echo   启动后端服务...
echo ========================================
echo.
echo API: http://localhost:4000
echo Health: http://localhost:4000/health
echo.
echo Press Ctrl+C to stop
echo ========================================
echo.

call npm run dev



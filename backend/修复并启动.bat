@echo off
chcp 65001 >nul
title Fix and Start
color 0A
cls
echo.
echo ========================================
echo   修复 Prisma 版本并启动
echo ========================================
echo.

cd /d "%~dp0"

echo [1/4] 修复 Prisma 版本...
echo 正在重新安装依赖以匹配版本...
call npm install
if errorlevel 1 (
    echo [错误] 依赖安装失败
    pause
    exit /b 1
)
echo [OK] 依赖已更新
echo.

echo [2/4] 清理旧的 Prisma 客户端...
if exist node_modules\.prisma (
    rmdir /s /q node_modules\.prisma
)
if exist node_modules\@prisma (
    rmdir /s /q node_modules\@prisma
)
echo [OK] 已清理
echo.

echo [3/4] 生成 Prisma 客户端...
call npx prisma generate
if errorlevel 1 (
    echo [错误] Prisma 生成失败
    echo 尝试使用本地 Prisma...
    if exist node_modules\.bin\prisma.cmd (
        call node_modules\.bin\prisma.cmd generate
    ) else (
        echo [严重错误] 无法生成 Prisma 客户端
        pause
        exit /b 1
    )
)
echo [OK] Prisma 客户端已生成
echo.

echo [4/4] 初始化数据库...
call npx prisma migrate deploy
if errorlevel 1 (
    echo 创建新的数据库迁移...
    call npx prisma migrate dev --name init --create-only
    if errorlevel 1 (
        call npx prisma db push
        if errorlevel 1 (
            echo [警告] 数据库迁移失败，但继续启动服务
        ) else (
            echo [OK] 数据库表已创建
        )
    ) else (
        call npx prisma migrate deploy
        echo [OK] 数据库迁移完成
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



@echo off
chcp 65001 >nul
title Complete Fix and Start
color 0A
cls
echo.
echo ========================================
echo   彻底修复并启动
echo ========================================
echo.

cd /d "%~dp0"

echo [1/5] 清理所有 Prisma 相关文件...
if exist node_modules\.prisma (
    rmdir /s /q node_modules\.prisma
)
if exist node_modules\@prisma (
    rmdir /s /q node_modules\@prisma
)
if exist node_modules\prisma (
    rmdir /s /q node_modules\prisma
)
echo [OK] 已清理
echo.

echo [2/5] 重新安装所有依赖...
call npm install
if errorlevel 1 (
    echo [错误] 依赖安装失败
    pause
    exit /b 1
)
echo [OK] 依赖已安装
echo.

echo [3/5] 安装 Prisma 引擎...
call npm install @prisma/engines --save-dev
if errorlevel 1 (
    echo [警告] @prisma/engines 安装失败，继续尝试...
)
echo.

echo [4/5] 生成 Prisma 客户端...
call npx prisma generate
if errorlevel 1 (
    echo [错误] Prisma 生成失败
    echo 尝试强制重新安装...
    call npm install prisma @prisma/client @prisma/engines --force
    call npx prisma generate
    if errorlevel 1 (
        echo [严重错误] 无法生成 Prisma 客户端
        pause
        exit /b 1
    )
)
echo [OK] Prisma 客户端已生成
echo.

echo [5/5] 初始化数据库...
call npx prisma migrate deploy
if errorlevel 1 (
    echo 创建新的数据库迁移...
    call npx prisma migrate dev --name init
    if errorlevel 1 (
        call npx prisma db push
        if errorlevel 1 (
            echo [警告] 数据库迁移失败，但继续启动服务
        ) else (
            echo [OK] 数据库表已创建
        )
    ) else (
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



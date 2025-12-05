@echo off
chcp 65001 >nul
title Create Database Tables
color 0A
cls
echo.
echo ========================================
echo   创建数据库表
echo ========================================
echo.

cd /d "%~dp0"

echo [步骤 1] 检查数据库连接...
docker exec feihub-postgres pg_isready -U feihub
if errorlevel 1 (
    echo [错误] 数据库未就绪
    echo 请确保 Docker 容器正在运行
    pause
    exit /b 1
)
echo [OK] 数据库连接正常
echo.

echo [步骤 2] 推送数据库结构（创建表）...
echo 这将在数据库中创建 Document 和 DocumentSubmission 表...
call npx prisma db push --accept-data-loss
if errorlevel 1 (
    echo [错误] 数据库推送失败
    echo.
    echo 尝试使用迁移方式...
    call npx prisma migrate dev --name init
    if errorlevel 1 (
        echo [严重错误] 无法创建数据库表
        echo.
        echo 请检查：
        echo 1. Docker 容器是否运行（docker ps）
        echo 2. .env 文件中的 DATABASE_URL 是否正确
        pause
        exit /b 1
    )
) else (
    echo [OK] 数据库表已创建
)
echo.

echo [步骤 3] 生成 Prisma 客户端...
call npx prisma generate
if errorlevel 1 (
    echo [错误] Prisma 客户端生成失败
    pause
    exit /b 1
)
echo [OK] Prisma 客户端已生成
echo.

echo ========================================
echo   数据库表创建完成！
echo ========================================
echo.
echo 现在可以重新启动后端服务了
echo 或者直接测试提交文档功能
echo.
pause

@echo off
chcp 65001 >nul
title Check Services
color 0B
cls
echo.
echo ========================================
echo   检查服务状态
echo ========================================
echo.

echo [1] 检查 Docker 容器...
docker ps | findstr "feihub"
if errorlevel 1 (
    echo [错误] Docker 容器未运行
    echo 请执行: docker-compose up -d
) else (
    echo [OK] Docker 容器运行中
)
echo.

echo [2] 检查后端 API...
curl -s http://localhost:4000/health
if errorlevel 1 (
    echo [错误] 后端服务未响应
    echo 请检查后端服务是否运行
) else (
    echo.
    echo [OK] 后端服务正常
)
echo.

echo [3] 检查 Redis 连接...
docker exec feihub-redis redis-cli ping
if errorlevel 1 (
    echo [错误] Redis 连接失败
    echo 请检查 Redis 容器是否运行
) else (
    echo [OK] Redis 连接正常
)
echo.

echo [4] 检查 PostgreSQL 连接...
docker exec feihub-postgres pg_isready -U feihub
if errorlevel 1 (
    echo [错误] PostgreSQL 连接失败
    echo 请检查 PostgreSQL 容器是否运行
) else (
    echo [OK] PostgreSQL 连接正常
)
echo.

echo ========================================
echo   检查完成
echo ========================================
echo.
pause



@echo off
chcp 65001 >nul
title Pull Docker Images
color 0B
cls
echo.
echo ========================================
echo   手动拉取 Docker 镜像
echo ========================================
echo.
echo 正在拉取 PostgreSQL 镜像...
echo 这可能需要几分钟，请耐心等待...
echo.
docker pull postgres:15-alpine
if errorlevel 1 (
    echo.
    echo [错误] PostgreSQL 镜像拉取失败
    echo 可能原因：
    echo   1. 网络连接问题
    echo   2. Docker 未正确运行
    echo   3. 需要配置镜像加速器
    echo.
    echo 建议：先配置 Docker 镜像加速器（参考 解决Docker镜像问题.md）
    pause
    exit /b 1
) else (
    echo.
    echo [成功] PostgreSQL 镜像已拉取
)
echo.

echo 正在拉取 Redis 镜像...
echo 这可能需要几分钟，请耐心等待...
echo.
docker pull redis:7-alpine
if errorlevel 1 (
    echo.
    echo [错误] Redis 镜像拉取失败
    pause
    exit /b 1
) else (
    echo.
    echo [成功] Redis 镜像已拉取
)
echo.

echo ========================================
echo   镜像拉取完成！
echo ========================================
echo.
echo 现在可以运行启动脚本了
echo.
pause



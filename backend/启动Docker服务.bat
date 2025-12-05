@echo off
chcp 65001 >nul
title Start Docker Services
color 0A
cls
echo.
echo ========================================
echo   启动 Docker 服务
echo ========================================
echo.

cd /d "%~dp0"

echo [1/3] 检查 Docker 镜像...
docker images | findstr "postgres redis" >nul
if errorlevel 1 (
    echo [警告] 未找到镜像，请先运行 "手动拉取Docker镜像.bat"
    echo.
    echo 是否现在拉取镜像？(Y/N)
    set /p choice=
    if /i "%choice%"=="Y" (
        call "手动拉取Docker镜像.bat"
    ) else (
        echo 已取消
        pause
        exit /b 1
    )
) else (
    echo [OK] 镜像已存在
)
echo.

echo [2/3] 启动 Docker 容器...
docker-compose up -d
if errorlevel 1 (
    echo [错误] 容器启动失败
    echo.
    echo 尝试停止旧容器并重新启动...
    docker-compose down
    docker-compose up -d
    if errorlevel 1 (
        echo [严重错误] 无法启动容器
        echo 请检查：
        echo   1. Docker Desktop 是否正在运行
        echo   2. 端口 5432 和 6379 是否被占用
        pause
        exit /b 1
    )
)
echo [OK] 容器已启动
echo.

echo [3/3] 等待服务就绪...
echo 等待 5 秒让数据库初始化...
timeout /t 5 /nobreak >nul
echo.

echo [检查] 容器状态...
docker ps | findstr "feihub"
echo.

echo ========================================
echo   Docker 服务已启动！
echo ========================================
echo.
echo PostgreSQL: localhost:5432
echo Redis: localhost:6379
echo.
echo 现在可以运行后端服务了
echo.
pause



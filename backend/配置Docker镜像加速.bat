@echo off
chcp 65001 >nul
title Configure Docker Mirror
echo.
echo ========================================
echo   Docker 镜像加速器配置说明
echo ========================================
echo.
echo 由于网络问题，Docker 无法拉取镜像。
echo 请按照以下步骤配置镜像加速器：
echo.
echo 1. 打开 Docker Desktop
echo 2. 点击右上角设置图标（齿轮）
echo 3. 选择 "Docker Engine"
echo 4. 在 JSON 配置中添加以下内容：
echo.
echo {
echo   "registry-mirrors": [
echo     "https://docker.mirrors.ustc.edu.cn",
echo     "https://hub-mirror.c.163.com",
echo     "https://mirror.baidubce.com"
echo   ]
echo }
echo.
echo 5. 点击 "Apply & Restart"
echo 6. 等待 Docker 重启完成
echo 7. 然后重新运行启动脚本
echo.
echo ========================================
echo.
echo 配置完成后，按任意键继续尝试拉取镜像...
pause >nul

echo.
echo 正在尝试拉取镜像...
docker pull postgres:15-alpine
if errorlevel 1 (
    echo [失败] PostgreSQL 镜像拉取失败
) else (
    echo [成功] PostgreSQL 镜像已拉取
)

docker pull redis:7-alpine
if errorlevel 1 (
    echo [失败] Redis 镜像拉取失败
) else (
    echo [成功] Redis 镜像已拉取
)

echo.
echo 如果镜像拉取成功，现在可以运行启动脚本了！
pause



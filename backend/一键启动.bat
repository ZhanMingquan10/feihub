@echo off
chcp 65001 >nul
title FeiHub 后端服务启动
color 0A
echo.
echo ========================================
echo    FeiHub 后端服务 - 一键启动
echo ========================================
echo.

REM 切换到脚本所在目录
cd /d "%~dp0"

REM 检查 .env 文件
if not exist .env (
    echo [1/6] 创建 .env 配置文件...
    (
        echo PORT=4000
        echo NODE_ENV=development
        echo DATABASE_URL="postgresql://feihub:feihub_password@localhost:5432/feihub?schema=public"
        echo REDIS_URL="redis://localhost:6379"
        echo DEEPSEEK_API_KEY=sk-dff2ea5fca7c4829a3c840b2d597ebbb
        echo OPENAI_API_KEY=
        echo CORS_ORIGIN=http://localhost:5173
    ) > .env
    echo [完成] .env 文件已创建
) else (
    echo [跳过] .env 文件已存在
)
echo.

REM 检查 node_modules
if not exist node_modules (
    echo [2/6] 安装依赖包（首次运行，可能需要几分钟）...
    call npm install
    if errorlevel 1 (
        echo.
        echo [错误] 依赖安装失败！
        echo 请检查网络连接，然后重试
        pause
        exit /b 1
    )
    echo [完成] 依赖安装成功
) else (
    echo [跳过] 依赖已安装
)
echo.

REM 启动 Docker
echo [3/6] 启动 Docker 服务（PostgreSQL + Redis）...
echo 正在拉取镜像，可能需要几分钟，请耐心等待...
docker-compose up -d
if errorlevel 1 (
    echo.
    echo [警告] Docker Compose 启动失败
    echo 可能原因：网络问题导致镜像拉取失败
    echo.
    echo [尝试] 重新拉取镜像...
    docker-compose pull
    docker-compose up -d
    if errorlevel 1 (
        echo.
        echo [错误] Docker 启动失败
        echo 建议：
        echo 1. 检查网络连接
        echo 2. 尝试使用 VPN 或代理
        echo 3. 或稍后重试
        echo.
        echo 继续执行后续步骤（数据库功能将不可用）...
    ) else (
        echo [完成] Docker 服务已启动
        echo [等待] 等待数据库就绪（5秒）...
        timeout /t 5 /nobreak >nul
    )
) else (
    echo [完成] Docker 服务已启动
    echo [等待] 等待数据库就绪（5秒）...
    timeout /t 5 /nobreak >nul
)
echo.

REM 生成 Prisma 客户端
echo [4/6] 生成 Prisma 数据库客户端...
echo 如果需要安装 Prisma，请按 Y 确认...
echo y | npx prisma generate
if errorlevel 1 (
    echo [尝试] 使用本地 Prisma...
    if exist node_modules\.bin\prisma.cmd (
        call node_modules\.bin\prisma.cmd generate
    ) else (
        echo [安装] 安装 Prisma...
        call npm install prisma @prisma/client --save-dev
        call npx prisma generate
    )
    if errorlevel 1 (
        echo [错误] Prisma 生成失败
        echo 尝试重新安装依赖...
        call npm install
        call npx prisma generate
        if errorlevel 1 (
            echo [严重错误] Prisma 生成失败，请检查错误信息
            pause
            exit /b 1
        )
    )
)
echo [完成] Prisma 客户端已生成
echo.

REM 运行数据库迁移
echo [5/6] 初始化数据库表结构...
call npx prisma migrate deploy
if errorlevel 1 (
    echo [尝试] 创建新的数据库迁移...
    call npx prisma migrate dev --name init
    if errorlevel 1 (
        echo [警告] 数据库迁移失败，但继续启动服务
        echo 可能原因：数据库连接失败或迁移已存在
    ) else (
        echo [完成] 数据库迁移成功
    )
) else (
    echo [完成] 数据库已就绪
)
echo.

REM 启动服务
echo [6/6] 启动后端服务...
echo.
echo ========================================
echo    后端服务启动中...
echo ========================================
echo.
echo API 地址: http://localhost:4000
echo 健康检查: http://localhost:4000/health
echo 文档列表: http://localhost:4000/api/documents
echo.
echo 按 Ctrl+C 停止服务
echo ========================================
echo.

call npm run dev


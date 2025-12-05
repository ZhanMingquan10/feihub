@echo off
chcp 65001 >nul
echo ========================================
echo FeiHub 后端服务 - 检查并启动
echo ========================================
echo.

REM 检查 .env 文件
if not exist .env (
    echo [步骤1] 创建 .env 配置文件...
    (
        echo PORT=4000
        echo NODE_ENV=development
        echo DATABASE_URL="postgresql://feihub:feihub_password@localhost:5432/feihub?schema=public"
        echo REDIS_URL="redis://localhost:6379"
        echo DEEPSEEK_API_KEY=sk-dff2ea5fca7c4829a3c840b2d597ebbb
        echo OPENAI_API_KEY=
        echo CORS_ORIGIN=http://localhost:5173
    ) > .env
    echo [成功] .env 文件已创建
) else (
    echo [跳过] .env 文件已存在
)
echo.

REM 检查 node_modules
if not exist node_modules (
    echo [步骤2] 安装依赖包（这可能需要几分钟）...
    call npm install
    if errorlevel 1 (
        echo [错误] 依赖安装失败，请检查网络连接
        pause
        exit /b 1
    )
    echo [成功] 依赖安装完成
) else (
    echo [跳过] 依赖已安装
)
echo.

REM 检查 Docker
echo [步骤3] 检查 Docker 服务...
where docker >nul 2>&1
if errorlevel 1 (
    echo [警告] Docker 未安装
    echo 跳过 Docker 启动步骤
    echo 注意：如果没有 Docker，数据库和 Redis 将无法使用
    echo 建议安装 Docker Desktop: https://www.docker.com/products/docker-desktop
    echo.
) else (
    docker ps >nul 2>&1
    if errorlevel 1 (
        echo [警告] Docker 未运行，请启动 Docker Desktop
        echo 跳过 Docker 启动步骤
        echo.
    ) else (
        echo [检查] Docker 正在运行，启动数据库和 Redis...
        docker-compose up -d >nul 2>&1
        if errorlevel 1 (
            echo [警告] Docker Compose 启动失败，可能容器已存在，继续...
        ) else (
            echo [成功] Docker 服务已启动
        )
        echo [等待] 等待数据库就绪（5秒）...
        timeout /t 5 /nobreak >nul
    )
)
echo.

REM 初始化数据库
echo [步骤4] 初始化数据库...
echo [执行] 生成 Prisma 客户端...
call npx prisma generate
if errorlevel 1 (
    echo [错误] Prisma 客户端生成失败
    echo [尝试] 使用 npm run db:generate...
    call npm run db:generate
    if errorlevel 1 (
        echo [错误] Prisma 生成失败，请检查 node_modules 是否正确安装
        echo [建议] 尝试: npm install
        pause
        exit /b 1
    )
) else (
    echo [成功] Prisma 客户端已生成
)
echo.

REM 检查数据库迁移
echo [执行] 运行数据库迁移...
call npx prisma migrate dev --name init
if errorlevel 1 (
    echo [警告] 数据库迁移失败，尝试跳过创建迁移文件...
    call npx prisma migrate deploy
    if errorlevel 1 (
        echo [警告] 数据库迁移可能已存在或数据库未连接，继续启动服务...
    )
)
echo.

echo [步骤5] 启动后端服务...
echo.
echo ========================================
echo 后端服务正在启动...
echo API 地址: http://localhost:4000
echo 健康检查: http://localhost:4000/health
echo.
echo 按 Ctrl+C 停止服务
echo ========================================
echo.

call npm run dev


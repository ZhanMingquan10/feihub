@echo off
chcp 65001 >nul
echo ========================================
echo FeiHub 后端服务 - 简化启动
echo ========================================
echo.

REM 检查 .env
if not exist .env (
    echo 创建 .env 文件...
    (
        echo PORT=4000
        echo NODE_ENV=development
        echo DATABASE_URL="postgresql://feihub:feihub_password@localhost:5432/feihub?schema=public"
        echo REDIS_URL="redis://localhost:6379"
        echo DEEPSEEK_API_KEY=sk-dff2ea5fca7c4829a3c840b2d597ebbb
        echo OPENAI_API_KEY=
        echo CORS_ORIGIN=http://localhost:5173
    ) > .env
    echo .env 文件已创建
)

REM 检查 node_modules
if not exist node_modules (
    echo.
    echo 首次运行，正在安装依赖（可能需要几分钟）...
    call npm install
    if errorlevel 1 (
        echo.
        echo [错误] 依赖安装失败
        echo 请检查网络连接，然后重试
        pause
        exit /b 1
    )
    echo.
    echo 依赖安装完成！
)

REM 尝试启动 Docker（可选）
where docker >nul 2>&1
if not errorlevel 1 (
    docker ps >nul 2>&1
    if not errorlevel 1 (
        echo.
        echo 启动 Docker 服务（数据库和 Redis）...
        docker-compose up -d >nul 2>&1
        timeout /t 3 /nobreak >nul
    )
)

REM 生成 Prisma 客户端
echo.
echo 初始化数据库...
call npx prisma generate
if errorlevel 1 (
    echo [警告] Prisma 生成失败，尝试使用本地安装...
    if exist node_modules\.bin\prisma.cmd (
        call node_modules\.bin\prisma.cmd generate
    )
)

REM 运行迁移
call npx prisma migrate deploy >nul 2>&1
if errorlevel 1 (
    call npx prisma migrate dev --name init --create-only >nul 2>&1
    call npx prisma migrate deploy >nul 2>&1
)

echo.
echo ========================================
echo 启动后端服务...
echo API 地址: http://localhost:4000
echo 健康检查: http://localhost:4000/health
echo.
echo 按 Ctrl+C 停止服务
echo ========================================
echo.

call npm run dev




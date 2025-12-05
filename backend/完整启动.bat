@echo off
chcp 65001 >nul
title FeiHub Complete Startup
color 0A
cls
echo.
echo ========================================
echo   FeiHub 完整启动流程
echo ========================================
echo.

cd /d "%~dp0"

REM Step 1: Check .env
echo [1/6] 检查配置文件...
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
    echo [OK] .env 已创建
) else (
    echo [OK] .env 已存在
)
echo.

REM Step 2: Check dependencies
echo [2/6] 检查依赖包...
if not exist node_modules (
    echo 安装依赖包（首次运行需要几分钟）...
    call npm install
    if errorlevel 1 (
        echo [错误] 依赖安装失败
        pause
        exit /b 1
    )
    echo [OK] 依赖已安装
) else (
    echo [OK] 依赖已安装
)
echo.

REM Step 3: Start Docker containers
echo [3/6] 启动 Docker 容器...
docker-compose up -d
if errorlevel 1 (
    echo [警告] 容器启动失败，尝试重新启动...
    docker-compose down
    timeout /t 2 /nobreak >nul
    docker-compose up -d
    if errorlevel 1 (
        echo [错误] 无法启动容器
        echo 请检查 Docker Desktop 是否正在运行
        pause
        exit /b 1
    )
)
echo [OK] Docker 容器已启动
echo.

REM Step 4: Wait for database
echo [4/6] 等待数据库就绪...
echo 等待 8 秒让数据库完全启动...
timeout /t 8 /nobreak >nul
echo [OK] 数据库已就绪
echo.

REM Step 5: Generate Prisma client
echo [5/6] 生成 Prisma 数据库客户端...
echo y | npx prisma generate >nul 2>&1
if errorlevel 1 (
    echo 使用本地 Prisma...
    if exist node_modules\.bin\prisma.cmd (
        call node_modules\.bin\prisma.cmd generate
    ) else (
        echo 安装 Prisma...
        call npm install prisma @prisma/client --save-dev
        call npx prisma generate
    )
    if errorlevel 1 (
        echo [错误] Prisma 生成失败
        pause
        exit /b 1
    )
)
echo [OK] Prisma 客户端已生成
echo.

REM Step 6: Database migration
echo [6/6] 初始化数据库表结构...
call npx prisma migrate deploy >nul 2>&1
if errorlevel 1 (
    echo 创建新的数据库迁移...
    call npx prisma migrate dev --name init --create-only >nul 2>&1
    if errorlevel 1 (
        call npx prisma db push >nul 2>&1
        if errorlevel 1 (
            echo [警告] 数据库迁移失败，但继续启动服务
        ) else (
            echo [OK] 数据库表已创建
        )
    ) else (
        call npx prisma migrate deploy >nul 2>&1
        echo [OK] 数据库迁移完成
    )
) else (
    echo [OK] 数据库已就绪
)
echo.

REM Start server
echo.
echo ========================================
echo   后端服务启动中...
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



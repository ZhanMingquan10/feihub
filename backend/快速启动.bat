@echo off
chcp 65001 >nul
title FeiHub Backend
color 0A
cls
echo.
echo ========================================
echo   FeiHub Backend Service
echo ========================================
echo.

cd /d "%~dp0"

REM Check .env
if not exist .env (
    echo [1/5] Creating .env file...
    (
        echo PORT=4000
        echo NODE_ENV=development
        echo DATABASE_URL="postgresql://feihub:feihub_password@localhost:5432/feihub?schema=public"
        echo REDIS_URL="redis://localhost:6379"
        echo DEEPSEEK_API_KEY=sk-dff2ea5fca7c4829a3c840b2d597ebbb
        echo OPENAI_API_KEY=
        echo CORS_ORIGIN=http://localhost:5173
    ) > .env
    echo [OK] .env created
) else (
    echo [SKIP] .env exists
)
echo.

REM Check node_modules
if not exist node_modules (
    echo [2/5] Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo [ERROR] npm install failed
        pause
        exit /b 1
    )
    echo [OK] Dependencies installed
) else (
    echo [SKIP] Dependencies installed
)
echo.

REM Start Docker
echo [3/5] Starting Docker services...
docker-compose up -d 2>nul
if errorlevel 1 (
    echo [WARN] Docker start failed, retrying...
    timeout /t 2 /nobreak >nul
    docker-compose pull
    docker-compose up -d
)
timeout /t 5 /nobreak >nul
echo [OK] Docker services started
echo.

REM Generate Prisma
echo [4/5] Generating Prisma client...
echo y | npx prisma generate >nul 2>&1
if errorlevel 1 (
    if exist node_modules\.bin\prisma.cmd (
        call node_modules\.bin\prisma.cmd generate
    ) else (
        call npm install prisma @prisma/client --save-dev
        call npx prisma generate
    )
)
echo [OK] Prisma client generated
echo.

REM Migrate database
echo [5/5] Initializing database...
call npx prisma migrate deploy >nul 2>&1
if errorlevel 1 (
    call npx prisma migrate dev --name init --create-only >nul 2>&1
    call npx prisma migrate deploy >nul 2>&1
)
echo [OK] Database ready
echo.

REM Start server
echo ========================================
echo   Starting backend server...
echo ========================================
echo.
echo API: http://localhost:4000
echo Health: http://localhost:4000/health
echo.
echo Press Ctrl+C to stop
echo ========================================
echo.

call npm run dev



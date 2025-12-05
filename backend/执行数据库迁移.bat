@echo off
chcp 65001 >nul
echo ========================================
echo 执行数据库迁移：添加AI结构化总结字段
echo ========================================
echo.

cd /d "%~dp0"

echo [1/3] 检查 Prisma Schema...
if not exist "prisma\schema.prisma" (
    echo [错误] 未找到 prisma\schema.prisma 文件
    pause
    exit /b 1
)
echo [OK] Prisma Schema 文件存在

echo.
echo [2/3] 生成 Prisma 客户端...
call npx prisma generate
if errorlevel 1 (
    echo [错误] Prisma 客户端生成失败
    pause
    exit /b 1
)
echo [OK] Prisma 客户端已生成

echo.
echo [3/3] 执行数据库迁移...
call npx prisma migrate dev --name add_ai_structured_summary
if errorlevel 1 (
    echo [错误] 数据库迁移失败
    pause
    exit /b 1
)
echo [OK] 数据库迁移成功

echo.
echo ========================================
echo 迁移完成！
echo ========================================
pause



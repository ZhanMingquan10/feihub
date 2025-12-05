@echo off
chcp 65001 >nul
echo ==========================================
echo   清空 FeiHub 测试数据
echo ==========================================
echo.

cd /d "%~dp0"

echo [1/3] 检查 Node.js 和 Prisma...
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js 未安装或未在 PATH 中
    pause
    exit /b 1
)

echo [2/3] 清空数据库记录...
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();(async()=>{try{const d=await p.document.deleteMany({});const s=await p.documentSubmission.deleteMany({});console.log('✅ 已删除',d.count,'条文档记录');console.log('✅ 已删除',s.count,'条提交记录');console.log('✅ 测试数据已清空！');}catch(e){console.error('❌ 错误:',e.message);}finally{await p.$disconnect();}})();"

if errorlevel 1 (
    echo.
    echo ❌ 清空数据失败，请检查：
    echo    1. 数据库连接是否正常
    echo    2. Prisma 是否已初始化
    echo    3. .env 文件配置是否正确
    pause
    exit /b 1
)

echo.
echo [3/3] 验证清空结果...
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();(async()=>{const d=await p.document.count();const s=await p.documentSubmission.count();console.log('📊 当前文档记录数:',d);console.log('📊 当前提交记录数:',s);await p.$disconnect();})();"

echo.
echo ==========================================
echo   清空完成！
echo ==========================================
pause



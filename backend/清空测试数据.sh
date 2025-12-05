#!/bin/bash

echo "=========================================="
echo "  清空 FeiHub 测试数据"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装或未在 PATH 中"
    exit 1
fi

echo "[1/3] 检查环境..."
echo "Node.js 版本: $(node --version)"

echo ""
echo "[2/3] 清空数据库记录..."
node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

(async () => {
  try {
    const deletedDocs = await prisma.document.deleteMany({});
    const deletedSubs = await prisma.documentSubmission.deleteMany({});
    console.log('✅ 已删除', deletedDocs.count, '条文档记录');
    console.log('✅ 已删除', deletedSubs.count, '条提交记录');
    console.log('✅ 测试数据已清空！');
  } catch (error) {
    console.error('❌ 错误:', error.message);
    process.exit(1);
  } finally {
    await prisma.\$disconnect();
  }
})();
"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ 清空数据失败，请检查："
    echo "   1. 数据库连接是否正常"
    echo "   2. Prisma 是否已初始化"
    echo "   3. .env 文件配置是否正确"
    exit 1
fi

echo ""
echo "[3/3] 验证清空结果..."
node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

(async () => {
  const docCount = await prisma.document.count();
  const subCount = await prisma.documentSubmission.count();
  console.log('📊 当前文档记录数:', docCount);
  console.log('📊 当前提交记录数:', subCount);
  await prisma.\$disconnect();
})();
"

echo ""
echo "=========================================="
echo "  清空完成！"
echo "=========================================="



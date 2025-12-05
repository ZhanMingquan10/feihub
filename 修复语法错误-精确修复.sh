#!/bin/bash

# 修复语法错误 - 精确修复第568行

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 查看第568行附近的代码 ==="
sed -n '560,575p' feishu-puppeteer.ts

echo ""
echo "=== 修复语法错误 ==="

# 使用 sed 直接修复第568行
sed -i '568s/continue;/return null;/' feishu-puppeteer.ts

echo "✅ 已修复第568行"

echo ""
echo "=== 验证修复 ==="
sed -n '560,575p' feishu-puppeteer.ts

echo ""
echo "=== 重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "=== 重启服务 ==="
    pm2 restart feihub-backend
    echo ""
    echo "✅✅✅ 修复完成！"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
fi


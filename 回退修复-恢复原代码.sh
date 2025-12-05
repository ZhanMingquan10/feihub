#!/bin/bash

# 回退修复 - 恢复原代码

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：查看备份文件 ==="
ls -la feishu-puppeteer.ts.bak* 2>/dev/null | tail -5

echo ""
echo "=== 第二步：恢复最新的备份 ==="

# 查找最新的备份文件
BACKUP=$(ls -t feishu-puppeteer.ts.bak* 2>/dev/null | head -1)

if [ -z "$BACKUP" ]; then
    echo "❌ 未找到备份文件"
    echo ""
    echo "=== 从 GitHub 恢复 ==="
    cd /www/wwwroot/feihub
    git checkout HEAD -- backend/src/lib/feishu-puppeteer.ts
    echo "✅ 已从 Git 恢复"
else
    echo "找到备份文件: $BACKUP"
    cp "$BACKUP" feishu-puppeteer.ts
    echo "✅ 已恢复备份"
fi

echo ""
echo "=== 第三步：验证恢复 ==="
echo "查看第414行："
sed -n '414p' feishu-puppeteer.ts

echo ""
echo "=== 第四步：重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "=== 重启服务 ==="
    pm2 restart feihub-backend
    echo ""
    echo "✅✅✅ 回退完成！代码已恢复到修复前的状态"
else
    echo ""
    echo "❌ 构建失败，可能需要从 GitHub 拉取原始代码"
    echo ""
    echo "执行以下命令从 GitHub 恢复："
    echo "  cd /www/wwwroot/feihub"
    echo "  git checkout HEAD -- backend/src/lib/feishu-puppeteer.ts"
    echo "  cd backend && npm run build && pm2 restart feihub-backend"
fi


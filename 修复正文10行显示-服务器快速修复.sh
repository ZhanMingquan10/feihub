#!/bin/bash

# 修复正文显示10行 - 服务器快速修复脚本

cd /www/wwwroot/feihub

echo "=== 第一步：检查代码是否包含 10 行限制 ==="
grep -n "WebkitLineClamp" src/App.tsx

if [ $? -ne 0 ]; then
    echo "❌ 代码中没有找到 WebkitLineClamp，需要更新代码"
    
    echo ""
    echo "=== 第二步：拉取最新代码 ==="
    git pull origin main
    
    echo ""
    echo "=== 第三步：再次检查 ==="
    grep -n "WebkitLineClamp" src/App.tsx
    
    if [ $? -ne 0 ]; then
        echo "❌ 拉取后还是没有，需要手动修改"
        echo "请告诉我，我会提供手动修改的命令"
        exit 1
    fi
fi

echo ""
echo "=== 第四步：重新构建前端 ==="
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "=== 第五步：重载 Nginx ==="
    nginx -s reload
    
    echo ""
    echo "✅ 完成！请清除浏览器缓存（Ctrl+Shift+R）后刷新页面"
else
    echo "❌ 构建失败，请检查错误信息"
    exit 1
fi


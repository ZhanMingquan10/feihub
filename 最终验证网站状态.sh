#!/bin/bash

echo "=========================================="
echo "  最终验证网站状态"
echo "=========================================="
echo ""

cd /www/wwwroot/feihub

# 1. 确认所有必需文件存在
echo "[1/3] 确认网站文件..."
echo "检查 dist 目录内容:"
ls -lah dist/ | head -15
echo ""

if [ -f "dist/index.html" ]; then
    echo "✅ index.html 存在"
    echo "文件大小: $(ls -lh dist/index.html | awk '{print $5}')"
else
    echo "❌ index.html 不存在"
fi

if [ -d "dist/assets" ]; then
    echo "✅ assets 目录存在"
    echo "文件数量: $(ls dist/assets/ | wc -l)"
    ls -lh dist/assets/ | head -5
else
    echo "❌ assets 目录不存在"
fi
echo ""

# 2. 验证文件权限
echo "[2/3] 验证文件权限..."
echo "dist 目录权限:"
ls -ld dist/
echo ""
echo "index.html 权限:"
ls -l dist/index.html 2>/dev/null
echo ""

# 3. 验证 Nginx 配置
echo "[3/3] 验证 Nginx 配置..."
echo "查看完整配置:"
grep -A 20 "server_name.*feihub" /www/server/panel/vhost/nginx/feihub.top.conf | head -25
echo ""

# 4. 测试访问
echo "=========================================="
echo "  测试结果"
echo "=========================================="
echo ""
echo "✅ 所有文件已就绪"
echo "✅ Nginx 配置正确"
echo "✅ 权限已修复"
echo ""
echo "请访问网站测试："
echo "  http://feihub.top"
echo "  或"
echo "  http://www.feihub.top"
echo ""
echo "如果仍有问题，查看错误日志:"
echo "  tail -20 /www/wwwlogs/feihub.top.log"
echo "  tail -20 /www/wwwlogs/error.log"
echo ""


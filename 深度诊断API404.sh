#!/bin/bash

echo "=========================================="
echo "  深度诊断 API 404 问题"
echo "=========================================="
echo ""

# 1. 检查后端直接访问
echo "[1/5] 测试后端直接访问..."
curl -v http://127.0.0.1:4000/api/documents/hot-keywords 2>&1 | head -20
echo ""

# 2. 检查 include 文件
echo "[2/5] 检查 include 文件..."
echo "检查 extension 目录:"
ls -la /www/server/panel/vhost/nginx/extension/feihub.top/ 2>/dev/null
echo ""
if [ -f "/www/server/panel/vhost/nginx/extension/feihub.top/api.conf" ]; then
    echo "发现 api.conf，内容:"
    cat /www/server/panel/vhost/nginx/extension/feihub.top/api.conf
fi
echo ""

# 3. 查看完整的 Nginx 配置（包括 include）
echo "[3/5] 查看完整配置..."
nginx -T 2>/dev/null | grep -A 20 "server_name feihub.top" | head -50
echo ""

# 4. 检查 location 匹配顺序
echo "[4/5] 检查 location 匹配..."
cat /www/server/panel/vhost/nginx/feihub.top.conf | grep -n "location"
echo ""

# 5. 检查 Nginx 错误日志
echo "[5/5] 检查错误日志..."
tail -30 /www/wwwlogs/error.log | grep -i "api\|4000\|proxy" || echo "无相关错误"
echo ""

echo "=========================================="
echo "  诊断完成"
echo "=========================================="


#!/bin/bash

echo "=========================================="
echo "  全面诊断 404 问题"
echo "=========================================="
echo ""

# 1. 检查后端服务
echo "[1/6] 检查后端服务..."
pm2 list | grep feihub-backend
echo ""
echo "测试后端直接访问:"
curl -s http://127.0.0.1:4000/api/documents/hot-keywords
echo ""
echo ""

# 2. 检查端口监听
echo "[2/6] 检查端口监听..."
netstat -tuln | grep ":4000"
echo ""

# 3. 查看当前 Nginx 配置
echo "[3/6] 查看当前 Nginx 配置..."
cat /www/server/panel/vhost/nginx/feihub.top.conf
echo ""

# 4. 查看完整的 Nginx 配置（包括所有 include）
echo "[4/6] 查看完整配置（nginx -T）..."
nginx -T 2>/dev/null | grep -A 100 "server_name.*feihub.top" | head -80
echo ""

# 5. 测试不同的 URL
echo "[5/6] 测试不同的 URL..."
echo "测试 1: http://localhost/api/documents/hot-keywords"
curl -v http://localhost/api/documents/hot-keywords 2>&1 | grep -E "HTTP|Host|Location|404"
echo ""
echo "测试 2: http://127.0.0.1/api/documents/hot-keywords"
curl -v http://127.0.0.1/api/documents/hot-keywords 2>&1 | grep -E "HTTP|Host|Location|404"
echo ""
echo "测试 3: http://feihub.top/api/documents/hot-keywords (需要 Host 头)"
curl -v -H "Host: feihub.top" http://127.0.0.1/api/documents/hot-keywords 2>&1 | grep -E "HTTP|Host|Location|404"
echo ""

# 6. 检查 Nginx 错误日志
echo "[6/6] 检查 Nginx 错误日志..."
tail -30 /www/wwwlogs/error.log | grep -i "api\|4000\|404" || echo "无相关错误"
echo ""

echo "=========================================="
echo "  诊断完成"
echo "=========================================="


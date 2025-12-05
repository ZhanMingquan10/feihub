#!/bin/bash

echo "=========================================="
echo "  检查并修复 API 代理"
echo "=========================================="
echo ""

# 1. 检查后端服务状态
echo "[1/5] 检查后端服务状态..."
pm2 list
echo ""

# 2. 检查后端监听的端口
echo "[2/5] 检查后端端口..."
echo "检查端口 3000:"
netstat -tuln | grep ":3000" || echo "❌ 端口 3000 未监听"
echo ""
echo "检查端口 4000:"
netstat -tuln | grep ":4000" || echo "❌ 端口 4000 未监听"
echo ""
echo "检查所有 Node.js 进程监听的端口:"
netstat -tulnp 2>/dev/null | grep node || echo "未找到 Node.js 进程"
echo ""

# 3. 检查后端配置文件
echo "[3/5] 检查后端配置..."
cd /www/wwwroot/feihub/backend
if [ -f ".env" ]; then
    echo "后端 .env 文件中的端口配置:"
    grep -E "PORT|port" .env 2>/dev/null || echo "未找到端口配置"
fi
echo ""
if [ -f "ecosystem.config.js" ]; then
    echo "ecosystem.config.js 中的端口配置:"
    grep -E "PORT|port|3000|4000" ecosystem.config.js 2>/dev/null || echo "未找到端口配置"
fi
echo ""

# 4. 检查 Nginx 配置
echo "[4/5] 检查 Nginx 配置..."
NGINX_CONF="/www/server/panel/vhost/nginx/feihub.top.conf"
echo "查看 API 代理配置:"
grep -A 10 "location /api" "$NGINX_CONF" || echo "❌ 未找到 API 代理配置"
echo ""

# 5. 测试后端 API 直接访问
echo "[5/5] 测试后端 API..."
echo "测试 localhost:3000:"
curl -s http://localhost:3000/api/documents/hot-keywords 2>&1 | head -5
echo ""
echo "测试 localhost:4000:"
curl -s http://localhost:4000/api/documents/hot-keywords 2>&1 | head -5
echo ""

echo "=========================================="
echo "  诊断完成"
echo "=========================================="
echo ""
echo "请根据上面的输出确定："
echo "1. 后端实际监听的端口（3000 或 4000）"
echo "2. Nginx 配置中的代理端口是否正确"
echo ""


#!/bin/bash

echo "=========================================="
echo "  全面检查服务状态"
echo "=========================================="
echo ""

# 1. 检查所有关键服务
echo "[1/6] 检查所有关键服务..."
echo "Nginx 状态:"
systemctl status nginx --no-pager | head -5
echo ""
echo "PM2 服务:"
pm2 list
echo ""
echo "后端服务日志（最近10行）:"
pm2 logs feihub-backend --lines 10 --nostream
echo ""

# 2. 检查前端文件
echo "[2/6] 检查前端文件..."
echo "检查 dist 目录:"
ls -la /www/wwwroot/feihub/dist/ | head -10
echo ""
echo "检查 index.html:"
if [ -f "/www/wwwroot/feihub/dist/index.html" ]; then
    echo "✅ index.html 存在"
    head -5 /www/wwwroot/feihub/dist/index.html
else
    echo "❌ index.html 不存在"
fi
echo ""

# 3. 检查端口监听
echo "[3/6] 检查端口监听..."
echo "端口 80:"
netstat -tuln | grep ":80"
echo ""
echo "端口 4000:"
netstat -tuln | grep ":4000"
echo ""

# 4. 测试不同的访问方式
echo "[4/6] 测试不同的访问方式..."
echo "测试 1: localhost"
curl -I http://localhost/ 2>&1 | head -5
echo ""
echo "测试 2: 127.0.0.1"
curl -I http://127.0.0.1/ 2>&1 | head -5
echo ""
echo "测试 3: 带 Host 头 (feihub.top)"
curl -I -H "Host: feihub.top" http://127.0.0.1/ 2>&1 | head -5
echo ""

# 5. 检查 Nginx 访问日志
echo "[5/6] 检查 Nginx 访问日志..."
tail -20 /www/wwwlogs/access.log 2>/dev/null | tail -5 || echo "无访问日志"
echo ""

# 6. 检查实际访问的 server 块
echo "[6/6] 检查实际匹配的 server 块..."
echo "测试 localhost 匹配的 server:"
curl -v http://localhost/ 2>&1 | grep -i "server\|host" | head -5
echo ""
echo "测试 127.0.0.1 匹配的 server:"
curl -v http://127.0.0.1/ 2>&1 | grep -i "server\|host" | head -5
echo ""

echo "=========================================="
echo "  诊断完成"
echo "=========================================="


#!/bin/bash

echo "=========================================="
echo "  修复默认 server 块"
echo "=========================================="
echo ""

# 1. 备份默认配置
DEFAULT_CONF="/www/server/panel/vhost/nginx/0.default.conf"
cp "$DEFAULT_CONF" "${DEFAULT_CONF}.bak.$(date +%Y%m%d_%H%M%S)"

# 2. 查看当前默认配置
echo "[1/3] 查看当前默认配置..."
cat "$DEFAULT_CONF"
echo ""

# 3. 修复默认配置，添加 API 代理
echo "[2/3] 修复默认配置..."
cat > "$DEFAULT_CONF" << 'EOF'
server
{
    listen 80;
    server_name _;
    index index.html;
    root /www/server/nginx/html;

    # API 代理 - 转发到 feihub.top 的后端
    location /api/ {
        proxy_pass http://127.0.0.1:4000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF

echo "✅ 默认配置已修复"
echo ""

# 4. 测试并重新加载
echo "[3/3] 测试并重新加载..."
nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Nginx 配置测试通过"
    systemctl reload nginx
    echo "✅ Nginx 已重新加载"
else
    echo "❌ Nginx 配置有错误"
    exit 1
fi

# 5. 测试
echo ""
echo "=== 测试 ==="
echo "测试 1: localhost (应该现在可以工作了)"
curl -s http://localhost/api/documents/hot-keywords | head -3
echo ""
echo "测试 2: 127.0.0.1"
curl -s http://127.0.0.1/api/documents/hot-keywords | head -3
echo ""
echo "测试 3: 带 Host 头"
curl -s -H "Host: feihub.top" http://127.0.0.1/api/documents/hot-keywords | head -3
echo ""

echo "=========================================="
echo "  ✅ 修复完成！"
echo "=========================================="
echo ""
echo "现在无论通过 IP、localhost 还是域名访问，API 都应该可以正常工作了"
echo ""


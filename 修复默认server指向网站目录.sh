#!/bin/bash

echo "=========================================="
echo "  修复默认 server 块指向网站目录"
echo "=========================================="
echo ""

DEFAULT_CONF="/www/server/panel/vhost/nginx/0.default.conf"

# 1. 备份
cp "$DEFAULT_CONF" "${DEFAULT_CONF}.bak.website"

# 2. 修复默认配置，指向 feihub 网站目录
echo "[1/3] 修复默认配置..."
cat > "$DEFAULT_CONF" << 'EOF'
server
{
    listen 80;
    server_name _;
    index index.html index.php;
    root /www/wwwroot/feihub/dist;

    # API 代理
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

    # 静态资源目录
    location ~* ^/assets/ {
        root /www/wwwroot/feihub/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # 其他静态文件
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|json)$ {
        root /www/wwwroot/feihub/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # 主 location
    location / {
        root /www/wwwroot/feihub/dist;
        try_files $uri $uri/ /index.html;
        index index.html;
    }
}
EOF

echo "✅ 默认配置已修复，指向 /www/wwwroot/feihub/dist"
echo ""

# 3. 测试并重新加载
echo "[2/3] 测试并重新加载..."
nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Nginx 配置测试通过"
    systemctl reload nginx
    echo "✅ Nginx 已重新加载"
else
    echo "❌ Nginx 配置有错误"
    exit 1
fi

# 4. 测试
echo ""
echo "[3/3] 测试访问..."
echo "测试 1: 127.0.0.1/ (应该返回 index.html)"
curl -I http://127.0.0.1/ 2>&1 | head -5
echo ""
echo "测试 2: 127.0.0.1/api/ (应该返回 API)"
curl -s http://127.0.0.1/api/documents/hot-keywords | head -3
echo ""

echo "=========================================="
echo "  ✅ 修复完成！"
echo "=========================================="
echo ""
echo "现在通过 IP 地址访问应该可以正常显示网站了"
echo "请清除浏览器缓存并刷新（Ctrl+Shift+R）"
echo ""


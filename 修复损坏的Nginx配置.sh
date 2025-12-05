#!/bin/bash

echo "=========================================="
echo "  修复损坏的 Nginx 配置"
echo "=========================================="
echo ""

NGINX_CONF="/www/server/panel/vhost/nginx/feihub.top.conf"

# 1. 备份
echo "[1/3] 备份当前配置..."
cp "$NGINX_CONF" "${NGINX_CONF}.bak.broken.$(date +%Y%m%d_%H%M%S)"
echo "✅ 已备份"
echo ""

# 2. 查看当前配置的问题
echo "[2/3] 查看当前配置..."
cat "$NGINX_CONF"
echo ""

# 3. 重新生成正确的配置
echo "[3/3] 重新生成配置..."
python3 << 'PYEOF'
import re

nginx_conf = "/www/server/panel/vhost/nginx/feihub.top.conf"

with open(nginx_conf, 'r', encoding='utf-8') as f:
    content = f.read()

# 提取 server_name 和 root（保留原有配置）
server_name_match = re.search(r'server_name\s+([^;]+);', content)
server_name = server_name_match.group(1) if server_name_match else "feihub.top www.feihub.top"

root_match = re.search(r'root\s+([^;]+);', content)
root_path = root_match.group(1) if root_match else "/www/wwwroot/feihub/dist"

# 查找 listen 端口
listen_match = re.search(r'listen\s+(\d+);', content)
listen_port = listen_match.group(1) if listen_match else "80"

# 重新构建正确的配置
new_config = f'''server
{{
    listen {listen_port};
    server_name {server_name};
    index index.php index.html index.htm default.php default.htm default.html;
    root {root_path};

    # API 代理
    location /api/ {{
        proxy_pass http://127.0.0.1:4000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }}

    # 静态资源
    location ~* ^/assets/ {{
        root /www/wwwroot/feihub/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }}

    # 其他静态文件
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|json)$ {{
        root /www/wwwroot/feihub/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }}

    # 主 location
    location / {{
        root /www/wwwroot/feihub/dist;
        try_files $uri $uri/ /index.html;
        index index.html;
    }}

    # 其他配置（保留 include 等）
    include /www/server/panel/vhost/nginx/well-known/feihub.top.conf;
    include /www/server/panel/vhost/nginx/extension/feihub.top/*.conf;
}}

'''

with open(nginx_conf, 'w', encoding='utf-8') as f:
    f.write(new_config)

print("✅ 配置已重新生成")
PYEOF

echo ""

# 4. 验证新配置
echo "查看新配置:"
cat "$NGINX_CONF"
echo ""

# 5. 测试并重新加载
echo "测试 Nginx 配置..."
nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Nginx 配置测试通过"
    systemctl reload nginx
    echo "✅ Nginx 已重新加载"
else
    echo "❌ Nginx 配置有错误，查看错误信息："
    nginx -t 2>&1
    exit 1
fi

echo ""
echo "=========================================="
echo "  ✅ 修复完成！"
echo "=========================================="
echo ""
echo "测试 API:"
curl -s http://localhost/api/documents/hot-keywords | head -5
echo ""
echo "请清除浏览器缓存并刷新（Ctrl+Shift+R）"
echo ""


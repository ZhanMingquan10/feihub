#!/bin/bash

echo "=========================================="
echo "  修复默认 server 块的 API 代理"
echo "=========================================="
echo ""

DEFAULT_CONF="/www/server/panel/vhost/nginx/0.default.conf"

# 1. 备份
echo "[1/3] 备份默认配置..."
cp "$DEFAULT_CONF" "${DEFAULT_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
echo "✅ 已备份"
echo ""

# 2. 查看当前默认配置
echo "[2/3] 查看当前默认配置..."
cat "$DEFAULT_CONF"
echo ""

# 3. 修复：在默认 server 块中添加 API 代理
echo "[3/3] 修复默认配置..."
python3 << 'PYEOF'
import re

default_conf = "/www/server/panel/vhost/nginx/0.default.conf"

with open(default_conf, 'r', encoding='utf-8') as f:
    content = f.read()

# 在默认 server 块中添加 API 代理
api_proxy = '''
    # API 代理（用于 IP 地址或 localhost 访问）
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
'''

# 在 root 行之后添加 API 代理
if 'location /api/' not in content:
    content = re.sub(
        r'(root\s+/www/server/nginx/html;)',
        r'\1' + api_proxy,
        content
    )
    print("✅ 已在默认 server 块中添加 API 代理")
else:
    print("✅ 默认 server 块中已有 API 代理")

with open(default_conf, 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF

echo ""

# 4. 查看修复后的配置
echo "查看修复后的默认配置:"
cat "$DEFAULT_CONF"
echo ""

# 5. 测试配置
echo "测试 Nginx 配置..."
nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Nginx 配置测试通过"
    systemctl reload nginx
    echo "✅ Nginx 已重新加载"
else
    echo "❌ Nginx 配置有错误"
    exit 1
fi

# 6. 测试
echo ""
echo "=== 测试 API ==="
echo "测试 1: localhost (应该现在可以工作了)"
curl -s http://localhost/api/documents/hot-keywords | head -3
echo ""
echo "测试 2: IP 地址"
curl -s http://127.0.0.1/api/documents/hot-keywords | head -3
echo ""
echo "测试 3: 域名"
curl -s -H "Host: feihub.top" http://127.0.0.1/api/documents/hot-keywords | head -3
echo ""

echo "=========================================="
echo "  ✅ 修复完成！"
echo "=========================================="
echo ""
echo "现在可以通过以下方式访问 API:"
echo "  - http://feihub.top/api/..."
echo "  - http://IP地址/api/..."
echo "  - http://localhost/api/..."
echo ""


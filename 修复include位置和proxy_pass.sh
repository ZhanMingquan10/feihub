#!/bin/bash

echo "=========================================="
echo "  修复 include 位置和 proxy_pass"
echo "=========================================="
echo ""

NGINX_CONF="/www/server/panel/vhost/nginx/feihub.top.conf"

# 1. 备份
cp "$NGINX_CONF" "${NGINX_CONF}.bak.final2"

# 2. 修复配置
python3 << 'PYEOF'
import re

nginx_conf = "/www/server/panel/vhost/nginx/feihub.top.conf"

with open(nginx_conf, 'r', encoding='utf-8') as f:
    content = f.read()

# 问题1: include 在 location 块内部，需要移除
# 问题2: proxy_pass 可能需要带路径

# 修复 location /api/ 块：移除内部的 include，使用正确的 proxy_pass
api_location = '''    # API 代理
    location ^~ /api/ {
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

# 替换 location /api/ 块，确保移除内部的 include
content = re.sub(
    r'location\s+(?:~\*|^~)?\s*/api/.*?include\s+/www/server/panel/vhost/nginx/extension/feihub\.top/\*\.conf;.*?\}',
    api_location.strip(),
    content,
    flags=re.DOTALL
)

# 如果上面的替换没成功，尝试更简单的替换
if 'location ^~ /api/' not in content or 'include /www/server/panel/vhost/nginx/extension/feihub.top/*.conf' in content.split('location ^~ /api/')[1].split('}')[0] if 'location ^~ /api/' in content else '':
    # 直接替换整个 location /api/ 块
    content = re.sub(
        r'location\s+(?:~\*|^~)?\s*/api/.*?\n\s*\}',
        api_location.strip(),
        content,
        flags=re.DOTALL
    )

# 确保 include 只在 server 块级别，不在 location 块内部
# 移除所有 location 块内部的 include
content = re.sub(
    r'(\s+)(include\s+/www/server/panel/vhost/nginx/extension/feihub\.top/\*\.conf;)',
    r'# \2  # 已移到 server 块级别',
    content
)

# 确保 server 块结束前有 include（如果还没有）
if 'include /www/server/panel/vhost/nginx/extension/feihub.top/*.conf' not in content or content.count('include /www/server/panel/vhost/nginx/extension/feihub.top/*.conf') < 2:
    # 在 server 块结束前添加 include
    content = re.sub(
        r'(\s+)(\})',
        r'\1    include /www/server/panel/vhost/nginx/extension/feihub.top/*.conf;\n\1\2',
        content,
        count=1  # 只替换最后一个 }
    )

with open(nginx_conf, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 配置已修复：")
print("   1. 移除了 location 块内部的 include")
print("   2. 使用 proxy_pass http://127.0.0.1:4000/api/; (带路径)")
PYEOF

echo ""

# 3. 查看修复后的配置
echo "=== 查看修复后的 location /api/ ==="
grep -A 10 "location.*/api" "$NGINX_CONF"
echo ""

# 4. 测试配置
echo "=== 测试配置 ==="
nginx -t
if [ $? -ne 0 ]; then
    echo "❌ 配置有错误"
    exit 1
fi

# 5. 重新加载
echo ""
echo "=== 重新加载 Nginx ==="
systemctl reload nginx

# 6. 测试 API
echo ""
echo "=== 测试 API ==="
echo "测试 1: 直接访问后端"
curl -s http://127.0.0.1:4000/api/documents/hot-keywords | head -3
echo ""
echo "测试 2: 通过 Nginx 代理"
curl -s http://localhost/api/documents/hot-keywords | head -3
echo ""

echo "=========================================="
echo "  ✅ 修复完成！"
echo "=========================================="


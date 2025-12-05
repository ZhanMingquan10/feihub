#!/bin/bash

echo "=========================================="
echo "  清理重复的 API 代理配置"
echo "=========================================="
echo ""

NGINX_CONF="/www/server/panel/vhost/nginx/feihub.top.conf"

# 1. 备份配置
echo "[1/3] 备份配置..."
cp "$NGINX_CONF" "${NGINX_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
echo "✅ 已备份"
echo ""

# 2. 查看当前配置（显示重复情况）
echo "[2/3] 查看当前配置中的重复项..."
grep -n "location /api" "$NGINX_CONF"
echo ""

# 3. 修复配置（移除重复，只保留一个）
echo "[3/3] 修复配置..."
python3 << 'PYEOF'
import re

nginx_conf = "/www/server/panel/vhost/nginx/feihub.top.conf"

with open(nginx_conf, 'r', encoding='utf-8') as f:
    content = f.read()

# 正确的 API 代理配置
api_proxy = '''    # API 代理
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

# 移除所有现有的 location /api/ 配置块
# 匹配从 "location /api/" 开始到下一个 "location" 或 "}" 结束的块
content = re.sub(
    r'location\s+/api/.*?proxy_connect_timeout\s+\d+s;\s*\}',
    '',
    content,
    flags=re.DOTALL
)

# 移除可能残留的空白行
content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)

# 在 location / 之前添加唯一的 API 代理配置
if "location / {" in content:
    # 检查是否已有 location /api/
    if "location /api/" not in content:
        content = re.sub(
            r'(location\s+/\s*\{)',
            api_proxy + r'\1',
            content
        )
else:
    # 如果没有 location /，在 root 之后添加
    if "location /api/" not in content:
        content = re.sub(
            r'(root\s+/www/wwwroot/feihub/dist;)',
            r'\1\n' + api_proxy,
            content
        )

with open(nginx_conf, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 重复配置已清理，只保留一个 API 代理配置")
PYEOF

echo ""

# 4. 验证配置
echo "验证修复后的配置..."
echo "检查 location /api/ 出现次数:"
grep -c "location /api/" "$NGINX_CONF" || echo "0"
echo ""
echo "查看修复后的 API 配置:"
grep -A 10 "location /api" "$NGINX_CONF" | head -12
echo ""

# 5. 测试并重新加载
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

echo ""
echo "=========================================="
echo "  ✅ 修复完成！"
echo "=========================================="
echo ""
echo "测试 API 代理:"
echo "curl http://localhost/api/documents/hot-keywords"
echo ""
echo "请清除浏览器缓存并刷新（Ctrl+Shift+R）"
echo ""


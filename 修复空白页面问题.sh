#!/bin/bash

echo "=========================================="
echo "  修复空白页面问题"
echo "=========================================="
echo ""

cd /www/wwwroot/feihub

# 1. 查看当前的 index.html 内容
echo "[1/5] 查看 index.html 内容..."
cat dist/index.html
echo ""

# 2. 检查 Nginx 配置
echo "[2/5] 检查 Nginx 配置..."
NGINX_CONF="/www/server/panel/vhost/nginx/feihub.top.conf"
if [ -f "$NGINX_CONF" ]; then
    echo "当前 Nginx 配置:"
    cat "$NGINX_CONF"
    echo ""
else
    echo "❌ Nginx 配置文件不存在"
    exit 1
fi

# 3. 检查是否有正确的 location 配置
echo "[3/5] 检查 location 配置..."
if grep -q "location.*assets" "$NGINX_CONF"; then
    echo "✅ 已有 assets location 配置"
else
    echo "⚠️  缺少 assets location 配置，需要添加"
fi

if grep -q "try_files" "$NGINX_CONF"; then
    echo "✅ 已有 try_files 配置"
else
    echo "⚠️  缺少 try_files 配置，需要添加"
fi
echo ""

# 4. 备份并修复 Nginx 配置
echo "[4/5] 备份并修复 Nginx 配置..."
cp "$NGINX_CONF" "${NGINX_CONF}.bak.$(date +%Y%m%d_%H%M%S)"

# 检查配置中是否有完整的 location / 块
if ! grep -q "location / {" "$NGINX_CONF" || ! grep -q "try_files" "$NGINX_CONF"; then
    echo "修复 Nginx 配置..."
    
    # 创建修复后的配置（确保有正确的 location 块）
    python3 << 'PYEOF'
import re

nginx_conf = "/www/server/panel/vhost/nginx/feihub.top.conf"

with open(nginx_conf, 'r', encoding='utf-8') as f:
    content = f.read()

# 检查是否有 location / 块
if "location / {" not in content:
    # 在 root 行后添加 location 块
    content = re.sub(
        r'(root\s+/www/wwwroot/feihub/dist;)',
        r'\1\n\n    location / {\n        try_files $uri $uri/ /index.html;\n    }',
        content
    )
else:
    # 如果已有 location /，确保有 try_files
    if "try_files" not in content:
        content = re.sub(
            r'(location\s+/\s*\{)',
            r'\1\n        try_files $uri $uri/ /index.html;',
            content
        )

# 确保有静态资源缓存配置
if "location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$" not in content:
    # 在 location / 块后添加静态资源配置
    content = re.sub(
        r'(location\s+/\s*\{[^}]*\})',
        r'\1\n\n    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {\n        expires 1y;\n        add_header Cache-Control "public, immutable";\n    }',
        content,
        flags=re.DOTALL
    )

with open(nginx_conf, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Nginx 配置已修复")
PYEOF

else
    echo "✅ Nginx 配置看起来正确"
fi
echo ""

# 5. 测试并重新加载 Nginx
echo "[5/5] 测试并重新加载 Nginx..."
nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Nginx 配置测试通过"
    systemctl reload nginx
    echo "✅ Nginx 已重新加载"
else
    echo "❌ Nginx 配置有错误，恢复备份..."
    cp "${NGINX_CONF}.bak."* "$NGINX_CONF" 2>/dev/null
    nginx -t
fi
echo ""

echo "=========================================="
echo "  ✅ 修复完成！"
echo "=========================================="
echo ""
echo "请刷新浏览器测试（Ctrl+Shift+R 强制刷新）"
echo ""
echo "如果仍有问题，请："
echo "1. 打开浏览器开发者工具（F12）"
echo "2. 查看 Console 标签页的错误信息"
echo "3. 查看 Network 标签页，检查资源是否加载成功"
echo ""


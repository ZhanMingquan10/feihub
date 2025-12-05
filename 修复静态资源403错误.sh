#!/bin/bash

echo "=========================================="
echo "  修复静态资源 403 错误"
echo "=========================================="
echo ""

cd /www/wwwroot/feihub

# 1. 检查文件权限
echo "[1/4] 检查文件权限..."
echo "dist 目录权限:"
ls -ld dist/
echo ""
echo "assets 目录权限:"
ls -ld dist/assets/
echo ""
echo "assets 目录内容:"
ls -la dist/assets/
echo ""

# 2. 修复权限
echo "[2/4] 修复权限..."
chown -R www:www dist/
chmod -R 755 dist/
chmod -R 644 dist/assets/* 2>/dev/null
chmod 755 dist/assets/
echo "✅ 权限已修复"
echo ""

# 3. 检查 Nginx 配置
echo "[3/4] 检查 Nginx 配置..."
NGINX_CONF="/www/server/panel/vhost/nginx/feihub.top.conf"
echo "查看当前配置:"
cat "$NGINX_CONF"
echo ""

# 4. 修复 Nginx 配置
echo "[4/4] 修复 Nginx 配置..."
cp "$NGINX_CONF" "${NGINX_CONF}.bak.$(date +%Y%m%d_%H%M%S)"

python3 << 'PYEOF'
import re

nginx_conf = "/www/server/panel/vhost/nginx/feihub.top.conf"

with open(nginx_conf, 'r', encoding='utf-8') as f:
    content = f.read()

# 确保静态资源 location 配置正确
# 修复策略：确保静态资源 location 在 location / 之前，并且路径正确

static_location = '''    # 静态资源（JS、CSS、图片等）- 必须在 location / 之前
    location ~* ^/assets/.*\\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|json)$ {
        root /www/wwwroot/feihub/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # 其他静态资源
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|json)$ {
        root /www/wwwroot/feihub/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

'''

# 移除可能存在的错误静态资源配置
content = re.sub(r'location\s+~.*assets.*\{[^}]*\}', '', content, flags=re.DOTALL)
content = re.sub(r'location\s+~.*\\.\(js\|css.*\{[^}]*\}', '', content, flags=re.DOTALL)

# 在 location / 之前插入静态资源 location
if "location / {" in content:
    # 检查是否已有静态资源 location
    if "location ~* ^/assets/" not in content:
        content = re.sub(
            r'(location\s+/\s*\{)',
            static_location + r'\1',
            content
        )
else:
    # 如果没有 location /，在 root 之后添加
    if "location ~* ^/assets/" not in content:
        content = re.sub(
            r'(root\s+/www/wwwroot/feihub/dist;)',
            r'\1\n' + static_location,
            content
        )

with open(nginx_conf, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Nginx 配置已修复")
PYEOF

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
echo "验证步骤："
echo "1. 测试静态资源访问:"
echo "   curl -I http://localhost/assets/index-BRYPYr0X.css"
echo ""
echo "2. 清除浏览器缓存并刷新（Ctrl+Shift+R）"
echo ""


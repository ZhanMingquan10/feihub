#!/bin/bash

echo "=========================================="
echo "  修复 MIME 类型错误"
echo "=========================================="
echo ""

NGINX_CONF="/www/server/panel/vhost/nginx/feihub.top.conf"

# 1. 查看当前配置
echo "[1/3] 查看当前配置..."
cat "$NGINX_CONF"
echo ""

# 2. 备份并修复配置
echo "[2/3] 备份并修复配置..."
cp "$NGINX_CONF" "${NGINX_CONF}.bak.$(date +%Y%m%d_%H%M%S)"

# 使用 Python 修复配置
python3 << 'PYEOF'
import re

nginx_conf = "/www/server/panel/vhost/nginx/feihub.top.conf"

with open(nginx_conf, 'r', encoding='utf-8') as f:
    content = f.read()

# 确保静态资源在 try_files 之前处理
# 修复策略：在 location / 之前添加静态资源 location

# 先移除可能存在的错误配置
# 确保 assets 目录的请求不被 try_files 拦截

# 添加静态资源 location（在 location / 之前）
static_location = '''    # 静态资源（必须在 location / 之前）
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|json)$ {
        root /www/wwwroot/feihub/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

'''

# 如果还没有静态资源 location，添加它
if "location ~* \\.(js|css" not in content:
    # 在 location / 之前插入
    if "location / {" in content:
        content = re.sub(
            r'(location\s+/\s*\{)',
            static_location + r'\1',
            content
        )
    else:
        # 如果没有 location /，在 root 之后添加
        content = re.sub(
            r'(root\s+/www/wwwroot/feihub/dist;)',
            r'\1\n' + static_location,
            content
        )

# 确保 location / 中的 try_files 不会拦截静态资源
# try_files 应该只处理非静态资源
if "location / {" in content and "try_files" in content:
    # 确保 try_files 不会拦截 .js 等文件
    # 这个已经在静态资源 location 中处理了，所以这里应该没问题
    pass

with open(nginx_conf, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 配置已修复")
PYEOF

echo ""

# 3. 测试并重新加载
echo "[3/3] 测试并重新加载 Nginx..."
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
echo "请清除浏览器缓存并刷新（Ctrl+Shift+R）"
echo ""


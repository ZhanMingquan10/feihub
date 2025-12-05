#!/bin/bash

echo "=========================================="
echo "  修复 API 代理 404 错误"
echo "=========================================="
echo ""

# 1. 检查后端服务
echo "[1/4] 检查后端服务..."
echo "测试直接访问后端:"
curl -s http://127.0.0.1:4000/api/documents/hot-keywords | head -5
echo ""
echo "检查后端端口:"
netstat -tuln | grep ":4000"
echo ""

# 2. 检查 include 文件是否覆盖配置
echo "[2/4] 检查 include 文件..."
if [ -f "/www/server/panel/vhost/nginx/extension/feihub.top/*.conf" ]; then
    echo "检查 extension 目录:"
    ls -la /www/server/panel/vhost/nginx/extension/feihub.top/ 2>/dev/null || echo "目录不存在或为空"
fi
echo ""

# 3. 检查 Nginx 错误日志
echo "[3/4] 检查 Nginx 错误日志..."
tail -20 /www/wwwlogs/error.log | grep -i "api\|4000\|proxy" || echo "无相关错误"
echo ""

# 4. 修复 proxy_pass 路径问题
echo "[4/4] 修复 proxy_pass 配置..."
NGINX_CONF="/www/server/panel/vhost/nginx/feihub.top.conf"
cp "$NGINX_CONF" "${NGINX_CONF}.bak.proxy"

# 修复 proxy_pass（移除末尾斜杠，避免路径问题）
python3 << 'PYEOF'
import re

nginx_conf = "/www/server/panel/vhost/nginx/feihub.top.conf"

with open(nginx_conf, 'r', encoding='utf-8') as f:
    content = f.read()

# 修复 proxy_pass：如果 location 是 /api/，proxy_pass 应该是 http://127.0.0.1:4000/api
# 注意：location /api/ 匹配 /api/xxx，proxy_pass http://127.0.0.1:4000/api/ 会把 /api/xxx 变成 /api/xxx
# 但如果 proxy_pass 是 http://127.0.0.1:4000/api（无斜杠），会把 /api/xxx 变成 /api/xxx（保持不变）
# 所以应该用 http://127.0.0.1:4000/api/（有斜杠）

# 但更好的方式是使用 rewrite 或者确保路径正确
# 检查当前的 proxy_pass
if 'proxy_pass http://127.0.0.1:4000/api/' in content:
    # 如果 location 是 /api/，proxy_pass 应该是 http://127.0.0.1:4000/api/
    # 这样 /api/documents/hot-keywords 会被代理到 http://127.0.0.1:4000/api/documents/hot-keywords
    # 这是正确的，不需要修改
    print("✅ proxy_pass 配置看起来正确")
else:
    # 修复 proxy_pass
    content = re.sub(
        r'proxy_pass\s+http://127\.0\.0\.1:4000[^;]*;',
        'proxy_pass http://127.0.0.1:4000/api/;',
        content
    )
    print("✅ proxy_pass 已修复")

# 确保 location /api/ 在 include 之前
# 如果 include 在 location /api/ 之前，可能会覆盖配置
# 检查 include 的位置
if 'include /www/server/panel/vhost/nginx/extension' in content:
    include_pos = content.find('include /www/server/panel/vhost/nginx/extension')
    api_pos = content.find('location /api/')
    if api_pos > include_pos:
        print("⚠️  include 在 location /api/ 之前，可能需要调整顺序")
        # 但通常 include 在最后是正常的，因为它是包含其他配置

with open(nginx_conf, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 配置已检查")
PYEOF

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

# 6. 测试 API 代理
echo ""
echo "测试 API 代理..."
echo "测试 1: curl http://localhost/api/documents/hot-keywords"
curl -s http://localhost/api/documents/hot-keywords | head -10
echo ""
echo "测试 2: curl -H 'Host: feihub.top' http://localhost/api/documents/hot-keywords"
curl -s -H 'Host: feihub.top' http://localhost/api/documents/hot-keywords | head -10
echo ""

echo "=========================================="
echo "  诊断完成"
echo "=========================================="
echo ""


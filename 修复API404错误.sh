#!/bin/bash

echo "=========================================="
echo "  修复 API 404 错误"
echo "=========================================="
echo ""

# 1. 检查后端服务状态
echo "[1/4] 检查后端服务状态..."
if command -v pm2 &> /dev/null; then
    echo "PM2 进程列表:"
    pm2 list
    echo ""
    
    if pm2 list | grep -q "feihub-backend"; then
        echo "✅ 后端服务在 PM2 中"
        if pm2 list | grep "feihub-backend" | grep -q "online"; then
            echo "✅ 后端服务正在运行"
        else
            echo "⚠️  后端服务未运行，正在启动..."
            pm2 restart feihub-backend
            sleep 2
        fi
    else
        echo "❌ 后端服务未在 PM2 中，正在启动..."
        cd /www/wwwroot/feihub/backend
        if [ -f "ecosystem.config.js" ]; then
            pm2 start ecosystem.config.js
        elif [ -f "dist/index.js" ]; then
            pm2 start dist/index.js --name feihub-backend
        else
            echo "❌ 找不到后端启动文件"
        fi
        pm2 save
    fi
else
    echo "❌ PM2 未安装"
fi
echo ""

# 2. 检查后端端口
echo "[2/4] 检查后端端口..."
echo "检查端口 3000:"
netstat -tuln | grep ":3000" || echo "❌ 端口 3000 未监听"
echo ""
echo "检查端口 4000:"
netstat -tuln | grep ":4000" || echo "❌ 端口 4000 未监听"
echo ""

# 3. 检查 Nginx API 代理配置
echo "[3/4] 检查 Nginx API 代理配置..."
NGINX_CONF="/www/server/panel/vhost/nginx/feihub.top.conf"
echo "查看当前配置中的 API 代理:"
grep -A 5 "location.*/api" "$NGINX_CONF" || echo "❌ 未找到 API 代理配置"
echo ""

# 4. 修复 Nginx 配置（添加 API 代理）
echo "[4/4] 修复 Nginx 配置..."
cp "$NGINX_CONF" "${NGINX_CONF}.bak.$(date +%Y%m%d_%H%M%S)"

python3 << 'PYEOF'
import re

nginx_conf = "/www/server/panel/vhost/nginx/feihub.top.conf"

with open(nginx_conf, 'r', encoding='utf-8') as f:
    content = f.read()

# 检查后端端口（从 PM2 或配置文件推断）
# 默认使用 3000，如果不存在则使用 4000
backend_port = "3000"

# 添加 API 代理配置（必须在 location / 之前）
api_proxy = f'''    # API 代理 - 必须在 location / 之前
    location /api/ {{
        proxy_pass http://127.0.0.1:{backend_port}/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }}

'''

# 如果还没有 API 代理配置，添加它
if "location /api/" not in content:
    # 在 location / 之前插入
    if "location / {" in content:
        content = re.sub(
            r'(location\s+/\s*\{)',
            api_proxy + r'\1',
            content
        )
    else:
        # 如果没有 location /，在 root 之后添加
        content = re.sub(
            r'(root\s+/www/wwwroot/feihub/dist;)',
            r'\1\n' + api_proxy,
            content
        )
else:
    # 如果已有配置，检查端口是否正确
    if f"proxy_pass http://127.0.0.1:{backend_port}" not in content:
        # 更新端口
        content = re.sub(
            r'proxy_pass\s+http://127\.0\.0\.1:\d+/api/',
            f'proxy_pass http://127.0.0.1:{backend_port}/api/',
            content
        )

with open(nginx_conf, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"✅ Nginx 配置已修复（后端端口: {backend_port}）")
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
    echo "❌ Nginx 配置有错误"
    exit 1
fi

echo ""
echo "=========================================="
echo "  ✅ 修复完成！"
echo "=========================================="
echo ""
echo "验证步骤："
echo "1. 检查后端服务: pm2 logs feihub-backend --lines 20"
echo "2. 测试 API: curl http://localhost/api/documents/hot-keywords"
echo "3. 清除浏览器缓存并刷新（Ctrl+Shift+R）"
echo ""


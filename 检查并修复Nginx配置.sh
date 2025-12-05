#!/bin/bash

# 检查并修复 Nginx 配置

echo "=== 检查 Nginx 配置 ==="

# 查找 Nginx 配置文件（通常在宝塔面板中）
NGINX_CONFIG="/www/server/panel/vhost/nginx/feihub.top.conf"

if [ ! -f "$NGINX_CONFIG" ]; then
    # 尝试其他可能的路径
    NGINX_CONFIG="/www/server/nginx/conf/vhost/feihub.top.conf"
fi

if [ ! -f "$NGINX_CONFIG" ]; then
    echo "⚠️  未找到 Nginx 配置文件，请手动检查"
    echo "可能的路径："
    echo "  /www/server/panel/vhost/nginx/feihub.top.conf"
    echo "  /www/server/nginx/conf/vhost/feihub.top.conf"
    echo ""
    echo "请检查配置中的 root 指令是否指向："
    echo "  root /www/wwwroot/feihub/dist;"
    exit 1
fi

echo "找到配置文件: $NGINX_CONFIG"
echo ""
echo "=== 当前配置 ==="
cat "$NGINX_CONFIG" | grep -A 5 "root"

echo ""
echo "=== 检查 root 路径 ==="
CURRENT_ROOT=$(grep -E "^\s*root\s+" "$NGINX_CONFIG" | head -1 | awk '{print $2}' | tr -d ';')

if [ -z "$CURRENT_ROOT" ]; then
    echo "❌ 未找到 root 配置"
else
    echo "当前 root: $CURRENT_ROOT"
    if [ "$CURRENT_ROOT" = "/www/wwwroot/feihub/dist" ]; then
        echo "✅ root 配置正确"
    else
        echo "⚠️  root 配置不正确，需要修改为: /www/wwwroot/feihub/dist"
        echo ""
        read -p "是否自动修复？(y/n): " confirm
        if [ "$confirm" = "y" ]; then
            # 备份原配置
            cp "$NGINX_CONFIG" "${NGINX_CONFIG}.bak_$(date +%Y%m%d_%H%M%S)"
            
            # 替换 root 路径
            sed -i "s|root\s\+[^;]*;|root /www/wwwroot/feihub/dist;|g" "$NGINX_CONFIG"
            
            echo "✅ 配置已更新"
            echo ""
            echo "=== 更新后的配置 ==="
            cat "$NGINX_CONFIG" | grep -A 5 "root"
            echo ""
            echo "请执行以下命令重载 Nginx："
            echo "  nginx -t && nginx -s reload"
        fi
    fi
fi

echo ""
echo "=== 检查构建文件 ==="
if [ -d "/www/wwwroot/feihub/dist" ]; then
    echo "✅ dist 目录存在"
    echo "文件列表："
    ls -lh /www/wwwroot/feihub/dist/
else
    echo "❌ dist 目录不存在"
fi


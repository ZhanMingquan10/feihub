#!/bin/bash

echo "=========================================="
echo "  修复 Nginx 403 Forbidden 错误"
echo "=========================================="
echo ""

# 1. 检查网站文件是否存在
echo "[1/5] 检查网站文件..."
WEBSITE_DIR="/www/wwwroot/feihub"
if [ -d "$WEBSITE_DIR" ]; then
    echo "✅ 网站目录存在: $WEBSITE_DIR"
    
    # 检查 dist 目录
    if [ -d "$WEBSITE_DIR/dist" ]; then
        echo "✅ dist 目录存在"
        ls -la "$WEBSITE_DIR/dist" | head -5
    else
        echo "❌ dist 目录不存在，需要构建前端"
    fi
    
    # 检查 index.html
    if [ -f "$WEBSITE_DIR/dist/index.html" ]; then
        echo "✅ index.html 存在"
    else
        echo "❌ index.html 不存在"
    fi
else
    echo "❌ 网站目录不存在: $WEBSITE_DIR"
fi
echo ""

# 2. 检查文件权限
echo "[2/5] 检查文件权限..."
if [ -d "$WEBSITE_DIR" ]; then
    echo "当前权限:"
    ls -ld "$WEBSITE_DIR"
    echo ""
    echo "修复权限..."
    chown -R www:www "$WEBSITE_DIR"
    chmod -R 755 "$WEBSITE_DIR"
    if [ -d "$WEBSITE_DIR/dist" ]; then
        chmod -R 644 "$WEBSITE_DIR/dist"/*
        chmod 755 "$WEBSITE_DIR/dist"
    fi
    echo "✅ 权限已修复"
fi
echo ""

# 3. 检查 Nginx 配置
echo "[3/5] 检查 Nginx 配置..."
NGINX_CONF="/www/server/panel/vhost/nginx"
if [ -d "$NGINX_CONF" ]; then
    echo "查找 feihub 相关配置..."
    find "$NGINX_CONF" -name "*feihub*" -o -name "*feihub*" 2>/dev/null | head -5
fi

# 检查默认配置
DEFAULT_CONF="/etc/nginx/sites-enabled/default"
if [ -f "$DEFAULT_CONF" ]; then
    echo "检查默认配置: $DEFAULT_CONF"
    grep -E "root|index" "$DEFAULT_CONF" | head -5
fi
echo ""

# 4. 检查 Nginx 错误日志
echo "[4/5] 检查 Nginx 错误日志..."
NGINX_ERROR_LOG="/www/wwwlogs/error.log"
if [ -f "$NGINX_ERROR_LOG" ]; then
    echo "最近的错误日志:"
    tail -20 "$NGINX_ERROR_LOG"
else
    echo "错误日志文件不存在: $NGINX_ERROR_LOG"
    # 尝试其他位置
    if [ -f "/var/log/nginx/error.log" ]; then
        echo "检查 /var/log/nginx/error.log:"
        tail -20 "/var/log/nginx/error.log"
    fi
fi
echo ""

# 5. 提供修复建议
echo "[5/5] 修复建议..."
echo ""
echo "如果 dist 目录不存在，需要构建前端:"
echo "  cd /www/wwwroot/feihub"
echo "  npm run build"
echo ""
echo "如果权限已修复但仍无法访问，检查 Nginx 配置:"
echo "  1. 确认 root 路径指向: $WEBSITE_DIR/dist"
echo "  2. 确认 index 文件: index.html"
echo "  3. 重新加载 Nginx: systemctl reload nginx"
echo ""

echo "=========================================="
echo "  执行修复操作..."
echo "=========================================="
echo ""

# 自动修复：确保 dist 目录存在且有正确权限
if [ ! -d "$WEBSITE_DIR/dist" ]; then
    echo "⚠️  dist 目录不存在，尝试构建..."
    cd "$WEBSITE_DIR"
    if [ -f "package.json" ]; then
        echo "执行 npm run build..."
        npm run build
    else
        echo "❌ package.json 不存在，无法自动构建"
    fi
fi

# 重新加载 Nginx
echo "重新加载 Nginx 配置..."
systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "✅ Nginx 配置已重新加载"
else
    echo "❌ Nginx 重新加载失败，尝试重启..."
    systemctl restart nginx
fi

echo ""
echo "=========================================="
echo "  ✅ 修复完成！"
echo "=========================================="
echo ""
echo "请刷新浏览器测试。如果仍有问题，请检查："
echo "1. 网站文件是否完整: ls -la $WEBSITE_DIR/dist"
echo "2. Nginx 配置: cat /etc/nginx/sites-enabled/default"
echo "3. Nginx 日志: tail -f /www/wwwlogs/error.log"
echo ""


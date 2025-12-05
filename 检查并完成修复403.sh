#!/bin/bash

echo "=========================================="
echo "  检查并完成 403 错误修复"
echo "=========================================="
echo ""

cd /www/wwwroot/feihub

# 1. 检查 dist 目录
echo "[1/4] 检查 dist 目录..."
if [ -d "dist" ]; then
    echo "✅ dist 目录存在"
    echo "文件列表:"
    ls -la dist/ | head -10
    echo ""
    if [ -f "dist/index.html" ]; then
        echo "✅ index.html 存在"
    else
        echo "❌ index.html 不存在"
    fi
else
    echo "❌ dist 目录不存在，需要构建前端"
    echo "开始构建..."
    npm run build
    if [ $? -eq 0 ]; then
        echo "✅ 构建成功"
    else
        echo "❌ 构建失败"
        exit 1
    fi
fi
echo ""

# 2. 检查文件权限
echo "[2/4] 检查文件权限..."
if [ -d "dist" ]; then
    echo "当前权限:"
    ls -ld dist/
    echo ""
    echo "修复权限..."
    chown -R www:www dist/
    chmod -R 755 dist/
    chmod -R 644 dist/* 2>/dev/null
    echo "✅ 权限已修复"
fi
echo ""

# 3. 检查 Nginx 配置
echo "[3/4] 检查 Nginx 配置..."
echo "查找 Nginx 配置文件..."
# 查找宝塔的站点配置
if [ -d "/www/server/panel/vhost/nginx" ]; then
    echo "宝塔站点配置:"
    ls -la /www/server/panel/vhost/nginx/ | grep -E "\.conf$" | head -5
    echo ""
    echo "检查配置中的 root 路径:"
    grep -r "root.*feihub" /www/server/panel/vhost/nginx/*.conf 2>/dev/null | head -3
fi

# 检查默认配置
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    echo ""
    echo "默认配置中的 root:"
    grep -E "^\s*root" /etc/nginx/sites-enabled/default | head -3
fi
echo ""

# 4. 测试并重新加载 Nginx
echo "[4/4] 测试并重新加载 Nginx..."
nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Nginx 配置测试通过"
    systemctl reload nginx
    if [ $? -eq 0 ]; then
        echo "✅ Nginx 已重新加载"
    else
        echo "⚠️  重新加载失败，尝试重启..."
        systemctl restart nginx
    fi
else
    echo "❌ Nginx 配置有错误，请检查配置"
fi
echo ""

# 5. 显示最终状态
echo "=========================================="
echo "  最终状态检查"
echo "=========================================="
echo ""
echo "网站文件:"
if [ -d "dist" ]; then
    echo "  ✅ dist 目录: $(du -sh dist | cut -f1)"
    echo "  ✅ index.html: $(ls -lh dist/index.html 2>/dev/null | awk '{print $5}')"
else
    echo "  ❌ dist 目录不存在"
fi
echo ""
echo "Nginx 状态:"
systemctl is-active nginx && echo "  ✅ Nginx 正在运行" || echo "  ❌ Nginx 未运行"
echo ""
echo "端口监听:"
netstat -tuln | grep -E ":80|:443" && echo "  ✅ HTTP/HTTPS 端口正在监听" || echo "  ❌ 端口未监听"
echo ""

echo "=========================================="
echo "  ✅ 修复完成！"
echo "=========================================="
echo ""
echo "请刷新浏览器测试。如果仍有 403 错误，请检查："
echo "1. 宝塔面板 → 网站 → 设置 → 网站目录是否指向: /www/wwwroot/feihub/dist"
echo "2. 查看错误日志: tail -20 /www/wwwlogs/error.log"
echo ""


#!/bin/bash

echo "=========================================="
echo "  服务器重启后恢复服务"
echo "=========================================="
echo ""

# 1. 检查并启动宝塔服务
echo "[1/4] 检查宝塔服务状态..."
if systemctl is-active --quiet bt; then
    echo "✅ 宝塔服务正在运行"
else
    echo "⚠️  宝塔服务未运行，正在启动..."
    systemctl start bt
    sleep 3
    if systemctl is-active --quiet bt; then
        echo "✅ 宝塔服务已启动"
    else
        echo "❌ 宝塔服务启动失败，尝试手动启动..."
        /etc/init.d/bt start
        sleep 3
    fi
fi
echo ""

# 2. 检查并启动 PM2 服务
echo "[2/4] 检查 PM2 服务状态..."
if command -v pm2 &> /dev/null; then
    # 检查 PM2 进程
    if pm2 list | grep -q "feihub-backend"; then
        echo "✅ 后端服务已在 PM2 中"
        # 检查服务是否运行
        if pm2 list | grep "feihub-backend" | grep -q "online"; then
            echo "✅ 后端服务正在运行"
        else
            echo "⚠️  后端服务未运行，正在启动..."
            pm2 restart feihub-backend
        fi
    else
        echo "⚠️  后端服务未在 PM2 中，正在启动..."
        cd /www/wwwroot/feihub/backend
        pm2 start ecosystem.config.js || pm2 start dist/index.js --name feihub-backend
    fi
    pm2 save
else
    echo "❌ PM2 未安装"
fi
echo ""

# 3. 检查 Nginx 服务
echo "[3/4] 检查 Nginx 服务状态..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx 正在运行"
else
    echo "⚠️  Nginx 未运行，正在启动..."
    systemctl start nginx
    sleep 2
    if systemctl is-active --quiet nginx; then
        echo "✅ Nginx 已启动"
    else
        echo "❌ Nginx 启动失败"
    fi
fi
echo ""

# 4. 检查端口监听
echo "[4/4] 检查端口监听状态..."
echo "检查端口 8888 (宝塔)..."
if netstat -tuln | grep -q ":8888"; then
    echo "✅ 端口 8888 正在监听"
else
    echo "❌ 端口 8888 未监听"
fi

echo "检查端口 3000 (后端API)..."
if netstat -tuln | grep -q ":3000"; then
    echo "✅ 端口 3000 正在监听"
else
    echo "❌ 端口 3000 未监听"
fi

echo "检查端口 80/443 (Nginx)..."
if netstat -tuln | grep -q ":80\|:443"; then
    echo "✅ 端口 80/443 正在监听"
else
    echo "❌ 端口 80/443 未监听"
fi
echo ""

# 5. 显示服务状态摘要
echo "=========================================="
echo "  服务状态摘要"
echo "=========================================="
echo ""
echo "宝塔服务:"
systemctl status bt --no-pager -l | head -3
echo ""
echo "PM2 服务:"
pm2 list 2>/dev/null || echo "PM2 未运行"
echo ""
echo "Nginx 服务:"
systemctl status nginx --no-pager -l | head -3
echo ""

echo "=========================================="
echo "  ✅ 恢复完成！"
echo "=========================================="
echo ""
echo "如果服务未正常启动，请手动执行："
echo "1. 启动宝塔: systemctl start bt 或 /etc/init.d/bt start"
echo "2. 启动后端: cd /www/wwwroot/feihub/backend && pm2 start ecosystem.config.js"
echo "3. 启动 Nginx: systemctl start nginx"
echo ""


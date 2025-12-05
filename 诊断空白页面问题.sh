#!/bin/bash

echo "=========================================="
echo "  诊断空白页面问题"
echo "=========================================="
echo ""

cd /www/wwwroot/feihub

# 1. 检查 index.html 中的资源路径
echo "[1/4] 检查 index.html 中的资源路径..."
echo "查看 index.html 内容:"
cat dist/index.html
echo ""

# 2. 检查资源文件是否可访问
echo "[2/4] 检查资源文件..."
echo "CSS 文件:"
ls -lh dist/assets/*.css
echo ""
echo "JS 文件:"
ls -lh dist/assets/*.js
echo ""

# 3. 检查 Nginx 配置
echo "[3/4] 检查 Nginx 配置..."
echo "查看完整的 server 配置:"
grep -A 50 "server_name.*feihub" /www/server/panel/vhost/nginx/feihub.top.conf
echo ""

# 4. 测试资源文件访问
echo "[4/4] 测试资源文件访问..."
echo "测试 index.html:"
curl -I http://localhost/dist/index.html 2>/dev/null | head -5
echo ""
echo "测试 CSS 文件:"
CSS_FILE=$(ls dist/assets/*.css | head -1 | xargs basename)
echo "CSS 文件名: $CSS_FILE"
curl -I "http://localhost/dist/assets/$CSS_FILE" 2>/dev/null | head -5
echo ""

echo "=========================================="
echo "  可能的问题和解决方案"
echo "=========================================="
echo ""
echo "1. 检查 index.html 中的资源路径是否正确（应该是相对路径）"
echo "2. 检查 Nginx 是否正确配置了静态资源服务"
echo "3. 检查浏览器控制台是否有 JS 错误"
echo ""


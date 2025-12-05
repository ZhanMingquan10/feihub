#!/bin/bash
# 查看实际代码并修复

cd /www/wwwroot/feihub

echo "=== 1. 查看 AI 标签的实际代码 ==="
grep -B 2 -A 2 "AI生成中\|border.*blue.*bg.*blue" src/App.tsx | grep -A 5 "rounded-full border" | head -15

echo ""
echo "=== 2. 查看 AI 速读模块的实际代码 ==="
grep -B 2 -A 5 "AI 速读" src/App.tsx | head -20

echo ""
echo "=== 3. 查看文档卡片的实际代码 ==="
grep -A 3 "rounded-3xl border p-6" src/App.tsx | head -10

echo ""
echo "=== 4. 查看浅色模式的所有样式定义 ==="
grep -E "isDarkMode.*:.*border|isDarkMode.*:.*bg-|isDarkMode.*:.*text-" src/App.tsx | grep -v "isDarkMode ?" | head -20


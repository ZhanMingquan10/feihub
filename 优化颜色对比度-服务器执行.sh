#!/bin/bash

# 优化颜色对比度

cd /www/wwwroot/feihub

echo "=== 优化颜色对比度 ==="

python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. 优化文档卡片背景和边框（增加对比度）
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-700/60 bg-gray-800/90"',
    'isDarkMode ? "border-gray-600/80 bg-gray-700/95 shadow-lg"',
    content
)
content = re.sub(
    r'isDarkMode\s+\?\s+"border-white/60 bg-white/90"',
    'isDarkMode ? "border-gray-200/80 bg-white shadow-lg"',
    content
)

# 2. 优化顶部横幅背景
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-700/60 bg-gray-800/85"',
    'isDarkMode ? "border-gray-600/80 bg-gray-700/95 shadow-lg"',
    content
)
content = re.sub(
    r'isDarkMode\s+\?\s+"border-white/60 bg-white/85"',
    'isDarkMode ? "border-gray-200/80 bg-white shadow-lg"',
    content
)

# 3. 优化搜索框背景
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-600/30 bg-gray-700/50',
    'isDarkMode ? "border-gray-600/50 bg-gray-800/70',
    content
)
content = re.sub(
    r'isDarkMode\s+\?\s+"border-black/10 bg-white',
    'isDarkMode ? "border-gray-300/80 bg-white',
    content
)

# 4. 优化 header 背景
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-700/40 bg-gray-900/70"',
    'isDarkMode ? "border-gray-600/60 bg-gray-900/90"',
    content
)
content = re.sub(
    r'isDarkMode\s+\?\s+"border-white/40 bg-white/70"',
    'isDarkMode ? "border-gray-200/80 bg-white/95"',
    content
)

# 5. 优化背景渐变（让背景更深/更浅）
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gradient-to-b from-gray-900 via-gray-800 to-gray-900',
    'isDarkMode ? "bg-gradient-to-b from-gray-950 via-gray-900 to-gray-950',
    content
)
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gradient-to-b from-white via-gray-50 to-gray-200',
    'isDarkMode ? "bg-gradient-to-b from-gray-100 via-gray-50 to-gray-100',
    content
)

# 6. 优化 footer 背景
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-700/60 bg-gray-900/70"',
    'isDarkMode ? "border-gray-600/80 bg-gray-800/90"',
    content,
    count=1  # 只替换第一个（footer）
)
content = re.sub(
    r'isDarkMode\s+\?\s+"border-white/60 bg-white/70"',
    'isDarkMode ? "border-gray-200/80 bg-white/95"',
    content,
    count=1  # 只替换第一个（footer）
)

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 颜色对比度已优化")
print("主要优化：")
print("1. 文档卡片：深色模式 bg-gray-700/95，浅色模式 bg-white")
print("2. 背景：深色模式 from-gray-950，浅色模式 from-gray-100")
print("3. 增加了 shadow-lg 让卡片更突出")
PYEOF

echo ""
echo "=== 重新构建 ==="
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅✅✅ 颜色对比度优化完成！"
    echo ""
    echo "优化内容："
    echo "1. ✅ 文档卡片背景更明显（深色：gray-700，浅色：white）"
    echo "2. ✅ 背景色更深/更浅（深色：gray-950，浅色：gray-100）"
    echo "3. ✅ 增加了阴影效果（shadow-lg）"
    echo "4. ✅ 边框对比度提升"
    echo ""
    echo "请清除浏览器缓存后查看效果："
    echo "  - Windows/Linux: Ctrl+Shift+R"
    echo "  - Mac: Cmd+Shift+R"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
fi


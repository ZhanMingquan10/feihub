#!/bin/bash
# 根据实际代码精确修复浅色模式

cd /www/wwwroot/feihub && python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    content = f.read()

print("=== 开始修复 ===")

# 修复 1: AI 速读模块 - 根据实际代码
content = re.sub(
    r':\s+"border-blue-100 bg-blue-50/80 text-gray-600"',
    ': "border-blue-500 bg-gradient-to-br from-blue-100 via-indigo-100 to-purple-100 text-gray-800 shadow-[0_0_25px_rgba(59,130,246,0.3)]"',
    content
)

# 修复 2: AI 速读模块边框改为 border-2
content = re.sub(
    r'rounded-2xl border px-4 py-3 text-sm shadow-inner',
    'rounded-2xl border-2 px-4 py-3 text-sm shadow-lg backdrop-blur-sm',
    content
)

# 修复 3: AI 速读标题
content = re.sub(
    r':\s+"text-blue-500"',
    ': "text-blue-700 drop-shadow-[0_0_6px_rgba(37,99,235,0.4)] font-extrabold"',
    content
)

# 修复 4: AI 角度文字
content = re.sub(
    r'font-medium", isDarkMode \? "text-cyan-300" : "text-blue-600"',
    'font-bold", isDarkMode ? "text-cyan-300" : "text-blue-700 drop-shadow-[0_0_4px_rgba(37,99,235,0.3)]"',
    content
)

# 修复 5: AI 内容文字（确保是 text-gray-800）
content = re.sub(
    r'isDarkMode \? "text-gray-300" : "text-gray-800"',
    'isDarkMode ? "text-gray-300" : "text-gray-800 font-medium"',
    content
)

# 修复 6: 查找并修复 AI 标签（需要先找到实际代码）
# 先查找 AI 标签的实际代码
ai_tag_match = re.search(r'rounded-full border[^"]*px-3 py-1[^"]*text-xs font-medium[^"]*isDarkMode[^"]*:[^"]*"([^"]*)"', content)
if ai_tag_match:
    print(f"找到 AI 标签样式: {ai_tag_match.group(1)}")
    # 如果还是旧的样式，替换它
    if 'border-blue-400 bg-blue-100' in ai_tag_match.group(1) or 'shadow-sm' in ai_tag_match.group(1):
        content = re.sub(
            r':\s+"border-blue-400 bg-blue-100 text-blue-700 shadow-sm"',
            ': "border-blue-500 bg-gradient-to-r from-blue-100 to-indigo-100 text-blue-700 shadow-[0_0_12px_rgba(59,130,246,0.25)] font-semibold"',
            content
        )
        # 修复边框
        content = re.sub(
            r'rounded-full border px-3 py-1 text-xs font-medium',
            'rounded-full border-2 px-3 py-1 text-xs font-medium',
            content
        )

# 修复 7: 文档卡片边框
content = re.sub(
    r'rounded-3xl border p-6',
    'rounded-3xl border-2 p-6',
    content
)

# 修复 8: 文档卡片样式（需要找到实际代码）
content = re.sub(
    r':\s+"border-gray-300 bg-white shadow-lg"',
    ': "border-gray-400 bg-white shadow-xl"',
    content
)

# 修复 9: Header
content = re.sub(
    r'border-b backdrop-blur-xl',
    'border-b-2 backdrop-blur-xl',
    content,
    count=1
)
content = re.sub(
    r':\s+"border-gray-300 bg-white/98 shadow-md"',
    ': "border-gray-400 bg-white shadow-lg"',
    content
)

# 修复 10: 主卡片
content = re.sub(
    r'rounded-3xl border p-8 text-center',
    'rounded-3xl border-2 p-8 text-center',
    content,
    count=1
)
content = re.sub(
    r':\s+"border-gray-300 bg-white shadow-xl"',
    ': "border-gray-400 bg-white shadow-2xl"',
    content,
    count=1
)

# 修复 11: Footer
content = re.sub(
    r'border-t transition-colors duration-300',
    'border-t-2 transition-colors duration-300',
    content
)
content = re.sub(
    r':\s+"border-gray-200/80 bg-white/95"',
    ': "border-gray-400 bg-white shadow-lg"',
    content
)

# 修复 12: 查看次数标签
content = re.sub(
    r':\s+"bg-white/95 border border-gray-200 text-gray-700 shadow-md"',
    ': "bg-white border-2 border-gray-300 text-gray-800 shadow-lg font-medium"',
    content
)

# 修复 13: 搜索框
content = re.sub(
    r'focus-within:ring-blue-500/30"',
    'focus-within:ring-blue-500/40"',
    content
)
content = re.sub(
    r'shadow-\[0_20px_45px_rgba\(0,0,0,0\.1\)\]',
    'shadow-[0_20px_45px_rgba(0,0,0,0.15)]',
    content
)
content = re.sub(
    r'shadow-\[0_25px_60px_rgba\(59,130,246,0\.2\)\]',
    'shadow-[0_25px_60px_rgba(59,130,246,0.3)]',
    content
)

# 修复 14: AI速读按钮
content = re.sub(
    r':\s+"bg-gradient-to-r from-blue-500 to-indigo-600 text-white border-blue-400 shadow-lg scale-105"',
    ': "bg-gradient-to-r from-blue-500 to-indigo-600 text-white border-blue-400 shadow-[0_0_20px_rgba(59,130,246,0.4)] scale-105"',
    content
)

# 修复 15: AI速读按钮未激活
content = re.sub(
    r':\s+"bg-white text-gray-600 border-gray-300 hover:border-blue-400 hover:text-blue-600 hover:bg-blue-50 shadow-sm"',
    ': "bg-white text-gray-700 border-gray-400 hover:border-blue-500 hover:text-blue-700 hover:bg-blue-50 shadow-md"',
    content
)

# 修复 16: Hero 区域 AI速读标题
content = re.sub(
    r':\s+"from-blue-500 via-indigo-600 to-purple-600 drop-shadow-\[0_0_8px_rgba\(59,130,246,0\.6\)\]"',
    ': "from-blue-600 via-indigo-600 to-purple-600 drop-shadow-[0_0_12px_rgba(59,130,246,0.5)] font-extrabold"',
    content
)

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 修复完成！")
PYEOF
npm run build && echo "✅✅✅ 构建完成！"


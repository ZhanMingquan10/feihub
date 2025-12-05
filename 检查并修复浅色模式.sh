#!/bin/bash
# 检查并修复浅色模式 UI

cd /www/wwwroot/feihub

echo "=== 1. 检查当前文件内容 ==="
echo "检查 AI 标签样式："
grep -A 1 "border-blue-500 bg-gradient-to-r from-blue-100" src/App.tsx | head -2

echo ""
echo "检查 AI 速读模块样式："
grep -A 1 "border-blue-500 bg-gradient-to-br from-blue-100 via-indigo-100" src/App.tsx | head -2

echo ""
echo "检查文档卡片边框："
grep "border-gray-400 bg-white shadow-xl" src/App.tsx | head -1

echo ""
echo "=== 2. 如果未找到，进行修复 ==="

python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    content = f.read()

# 检查是否已经修改过
if 'border-blue-500 bg-gradient-to-r from-blue-100 to-indigo-100' in content:
    print("✅ AI 标签已优化")
else:
    print("❌ AI 标签未优化，开始修复...")
    # 修复 AI 标签
    content = re.sub(
        r'isDarkMode\s+\?\s+"border-blue-500/60 bg-blue-500/20 text-blue-300 shadow-\[0_0_15px_rgba\(59,130,246,0\.3\)\]"\s+:\s+"border-blue-400 bg-blue-100 text-blue-700 shadow-sm"',
        'isDarkMode ? "border-blue-500/60 bg-blue-500/20 text-blue-300 shadow-[0_0_15px_rgba(59,130,246,0.3)]" : "border-blue-500 bg-gradient-to-r from-blue-100 to-indigo-100 text-blue-700 shadow-[0_0_12px_rgba(59,130,246,0.25)] font-semibold"',
        content
    )
    # 修复边框
    content = re.sub(
        r'rounded-full border px-3 py-1 text-xs font-medium transition-all duration-200 hover:scale-105", isDarkMode \? "border-blue-500/60 bg-blue-500/20 text-blue-300 shadow-\[0_0_15px_rgba\(59,130,246,0\.3\)\]" : "border-blue-500 bg-gradient-to-r from-blue-100 to-indigo-100',
        'rounded-full border-2 px-3 py-1 text-xs font-medium transition-all duration-200 hover:scale-105", isDarkMode ? "border-blue-500/60 bg-blue-500/20 text-blue-300 shadow-[0_0_15px_rgba(59,130,246,0.3)]" : "border-blue-500 bg-gradient-to-r from-blue-100 to-indigo-100',
        content
    )

if 'border-blue-500 bg-gradient-to-br from-blue-100 via-indigo-100 to-purple-100' in content:
    print("✅ AI 速读模块已优化")
else:
    print("❌ AI 速读模块未优化，开始修复...")
    # 修复 AI 速读模块
    content = re.sub(
        r'isDarkMode\s+\?\s+"border-blue-500/60 bg-gradient-to-br from-blue-500/25 via-indigo-500/20 to-purple-500/25 text-gray-200 shadow-\[0_0_30px_rgba\(59,130,246,0\.4\)\]"\s+:\s+"border-blue-300 bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 text-gray-700 shadow-\[0_4px_20px_rgba\(59,130,246,0\.15\)\]"',
        'isDarkMode ? "border-blue-500/60 bg-gradient-to-br from-blue-500/25 via-indigo-500/20 to-purple-500/25 text-gray-200 shadow-[0_0_30px_rgba(59,130,246,0.4)]" : "border-blue-500 bg-gradient-to-br from-blue-100 via-indigo-100 to-purple-100 text-gray-800 shadow-[0_0_25px_rgba(59,130,246,0.3)]"',
        content
    )

if 'border-gray-400 bg-white shadow-xl' in content and 'border-2' in content:
    print("✅ 文档卡片边框已优化")
else:
    print("❌ 文档卡片边框未优化，开始修复...")
    # 修复文档卡片边框
    content = re.sub(
        r'rounded-3xl border p-6',
        'rounded-3xl border-2 p-6',
        content
    )
    content = re.sub(
        r'isDarkMode\s+\?\s+"border-gray-500/60 bg-gray-700 shadow-xl"\s+:\s+"border-gray-300 bg-white shadow-lg"',
        'isDarkMode ? "border-gray-500/60 bg-gray-700 shadow-xl" : "border-gray-400 bg-white shadow-xl"',
        content
    )

# 修复 Header
if 'border-b-2' in content:
    print("✅ Header 边框已优化")
else:
    print("❌ Header 边框未优化，开始修复...")
    content = re.sub(
        r'border-b backdrop-blur-xl',
        'border-b-2 backdrop-blur-xl',
        content,
        count=1
    )
    content = re.sub(
        r'isDarkMode\s+\?\s+"border-gray-500/40 bg-gray-900/95 shadow-lg"\s+:\s+"border-gray-300 bg-white/98 shadow-md"',
        'isDarkMode ? "border-gray-500/40 bg-gray-900/95 shadow-lg" : "border-gray-400 bg-white shadow-lg"',
        content
    )

# 修复主卡片
if 'rounded-3xl border-2 p-8' in content:
    print("✅ 主卡片边框已优化")
else:
    print("❌ 主卡片边框未优化，开始修复...")
    content = re.sub(
        r'rounded-3xl border p-8 text-center',
        'rounded-3xl border-2 p-8 text-center',
        content,
        count=1
    )
    content = re.sub(
        r'isDarkMode\s+\?\s+"border-gray-500/60 bg-gray-700 shadow-2xl"\s+:\s+"border-gray-300 bg-white shadow-xl"',
        'isDarkMode ? "border-gray-500/60 bg-gray-700 shadow-2xl" : "border-gray-400 bg-white shadow-2xl"',
        content,
        count=1
    )

# 修复 AI 速读标题
if 'text-blue-700 drop-shadow-[0_0_6px_rgba(37,99,235,0.4)]' in content:
    print("✅ AI 速读标题已优化")
else:
    print("❌ AI 速读标题未优化，开始修复...")
    content = re.sub(
        r'isDarkMode\s+\?\s+"text-cyan-300 drop-shadow-\[0_0_8px_rgba\(103,232,249,0\.6\)\]"\s+:\s+"text-blue-600 font-extrabold"',
        'isDarkMode ? "text-cyan-300 drop-shadow-[0_0_8px_rgba(103,232,249,0.6)]" : "text-blue-700 drop-shadow-[0_0_6px_rgba(37,99,235,0.4)] font-extrabold"',
        content
    )

# 修复 AI 角度文字
if 'text-blue-700 drop-shadow-[0_0_4px_rgba(37,99,235,0.3)]' in content:
    print("✅ AI 角度文字已优化")
else:
    print("❌ AI 角度文字未优化，开始修复...")
    content = re.sub(
        r'font-semibold", isDarkMode \? "text-cyan-300" : "text-blue-700"',
        'font-bold", isDarkMode ? "text-cyan-300" : "text-blue-700 drop-shadow-[0_0_4px_rgba(37,99,235,0.3)]"',
        content
    )

# 修复 AI 内容文字
if 'text-gray-800 font-medium' in content:
    print("✅ AI 内容文字已优化")
else:
    print("❌ AI 内容文字未优化，开始修复...")
    content = re.sub(
        r'isDarkMode\s+\?\s+"text-gray-200"\s+:\s+"text-gray-700"',
        'isDarkMode ? "text-gray-200" : "text-gray-800 font-medium"',
        content
    )
    content = re.sub(
        r'isDarkMode\s+\?\s+"text-gray-300"\s+:\s+"text-gray-600"',
        'isDarkMode ? "text-gray-300" : "text-gray-800"',
        content
    )

# 修复搜索框
if 'focus-within:ring-blue-500/40' in content:
    print("✅ 搜索框已优化")
else:
    print("❌ 搜索框未优化，开始修复...")
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

# 修复 Footer
if 'border-t-2' in content:
    print("✅ Footer 已优化")
else:
    print("❌ Footer 未优化，开始修复...")
    content = re.sub(
        r'border-t transition-colors duration-300',
        'border-t-2 transition-colors duration-300',
        content
    )
    content = re.sub(
        r'isDarkMode\s+\?\s+"border-gray-600/80 bg-gray-800/90"\s+:\s+"border-gray-200/80 bg-white/95"',
        'isDarkMode ? "border-gray-600/80 bg-gray-800/90" : "border-gray-400 bg-white shadow-lg"',
        content
    )

# 修复查看次数标签
if 'border-2 border-gray-300 text-gray-800 shadow-lg font-medium' in content:
    print("✅ 查看次数标签已优化")
else:
    print("❌ 查看次数标签未优化，开始修复...")
    content = re.sub(
        r'isDarkMode\s+\?\s+"bg-gray-800/90 border border-gray-600/50 text-gray-200 shadow-lg"\s+:\s+"bg-white/95 border border-gray-200 text-gray-700 shadow-md"',
        'isDarkMode ? "bg-gray-800/90 border border-gray-600/50 text-gray-200 shadow-lg" : "bg-white border-2 border-gray-300 text-gray-800 shadow-lg font-medium"',
        content
    )

# 修复 AI速读按钮
if 'shadow-[0_0_20px_rgba(59,130,246,0.4)]' in content and 'scale-105' in content:
    print("✅ AI速读按钮已优化")
else:
    print("❌ AI速读按钮未优化，开始修复...")
    content = re.sub(
        r'isDarkMode\s+\?\s+"bg-gradient-to-r from-cyan-500 to-blue-600 text-white border-cyan-400 shadow-\[0_0_25px_rgba\(6,182,212,0\.6\)\] scale-105"\s+:\s+"bg-gradient-to-r from-blue-500 to-indigo-600 text-white border-blue-400 shadow-lg scale-105"',
        'isDarkMode ? "bg-gradient-to-r from-cyan-500 to-blue-600 text-white border-cyan-400 shadow-[0_0_25px_rgba(6,182,212,0.6)] scale-105" : "bg-gradient-to-r from-blue-500 to-indigo-600 text-white border-blue-400 shadow-[0_0_20px_rgba(59,130,246,0.4)] scale-105"',
        content
    )

# 修复 AI速读按钮未激活状态
if 'text-gray-700 border-gray-400' in content:
    print("✅ AI速读按钮未激活状态已优化")
else:
    print("❌ AI速读按钮未激活状态未优化，开始修复...")
    content = re.sub(
        r'isDarkMode\s+\?\s+"bg-gray-800/80 text-gray-400 border-gray-600 hover:border-cyan-500/50 hover:text-cyan-300 hover:bg-cyan-500/10"\s+:\s+"bg-white text-gray-600 border-gray-300 hover:border-blue-400 hover:text-blue-600 hover:bg-blue-50 shadow-sm"',
        'isDarkMode ? "bg-gray-800/80 text-gray-400 border-gray-600 hover:border-cyan-500/50 hover:text-cyan-300 hover:bg-cyan-500/10" : "bg-white text-gray-700 border-gray-400 hover:border-blue-500 hover:text-blue-700 hover:bg-blue-50 shadow-md"',
        content
    )

# 修复 Hero 区域 AI速读标题
if 'from-blue-600 via-indigo-600 to-purple-600 drop-shadow-[0_0_12px_rgba(59,130,246,0.5)] font-extrabold' in content:
    print("✅ Hero 区域 AI速读标题已优化")
else:
    print("❌ Hero 区域 AI速读标题未优化，开始修复...")
    content = re.sub(
        r'isDarkMode\s+\?\s+"from-cyan-400 via-blue-400 to-indigo-400 drop-shadow-\[0_0_15px_rgba\(96,165,250,0\.9\)\] animate-pulse"\s+:\s+"from-blue-500 via-indigo-600 to-purple-600 drop-shadow-\[0_0_8px_rgba\(59,130,246,0\.6\)\]"',
        'isDarkMode ? "from-cyan-400 via-blue-400 to-indigo-400 drop-shadow-[0_0_15px_rgba(96,165,250,0.9)] animate-pulse" : "from-blue-600 via-indigo-600 to-purple-600 drop-shadow-[0_0_12px_rgba(59,130,246,0.5)] font-extrabold"',
        content
    )

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ 修复完成！")
PYEOF

echo ""
echo "=== 3. 验证修改 ==="
grep -A 1 "border-blue-500 bg-gradient-to-r from-blue-100" src/App.tsx | head -2

echo ""
echo "=== 4. 重新构建 ==="
npm run build && echo "✅✅✅ 构建完成！"


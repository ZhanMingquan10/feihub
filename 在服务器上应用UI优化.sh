#!/bin/bash

# 在服务器上直接应用 UI 优化

cd /www/wwwroot/feihub

echo "=== 应用世界级 UI 优化 ==="

# 备份原文件
cp src/App.tsx src/App.tsx.bak_ui_optimize

python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. 移除右上角按钮文字，改为圆形图标按钮
# 客服按钮
content = re.sub(
    r'<button\s+onClick=\{\(\) => setShowCustomerService\(true\)\}\s+className=\{clsx\("flex items-center gap-2 rounded-full border px-4 py-1\.5 text-xs transition"[^>]*>\s*<MessageCircle size=\{14\} />\s*<span>客服</span>',
    '''<button
              onClick={() => setShowCustomerService(true)}
              className={clsx("flex items-center justify-center rounded-full border w-10 h-10 transition-all duration-300 hover:scale-110", isDarkMode ? "border-gray-600 bg-gray-800/80 text-blue-400 hover:border-blue-500/50 hover:bg-blue-500/10 hover:shadow-[0_0_20px_rgba(96,165,250,0.3)]" : "border-gray-300 bg-white text-blue-600 hover:border-blue-400 hover:bg-blue-50 hover:shadow-lg")}
              title="联系客服"
            >
              <MessageCircle size={18} />''',
    content,
    flags=re.DOTALL
)

# 主题切换按钮
content = re.sub(
    r'<button\s+onClick=\{\(\) => setIsDarkMode\(!isDarkMode\)\}\s+className=\{clsx\("flex items-center gap-2 rounded-full border px-4 py-1\.5 text-xs transition"[^>]*>\s*\{isDarkMode \? <Sun size=\{14\} /> : <Moon size=\{14\} />\}\s*<span>\{isDarkMode \? "浅色" : "深色"\}</span>',
    '''<button
              onClick={() => setIsDarkMode(!isDarkMode)}
              className={clsx("flex items-center justify-center rounded-full border w-10 h-10 transition-all duration-300 hover:scale-110", isDarkMode ? "border-gray-600 bg-gray-800/80 text-yellow-400 hover:border-yellow-500/50 hover:bg-yellow-500/10 hover:shadow-[0_0_20px_rgba(250,204,21,0.3)]" : "border-gray-300 bg-white text-gray-700 hover:border-gray-400 hover:bg-gray-50 hover:shadow-lg")}
              title={isDarkMode ? "切换到浅色样式" : "切换到深色样式"}
            >
              {isDarkMode ? <Sun size={18} /> : <Moon size={18} />}''',
    content,
    flags=re.DOTALL
)

# 2. 优化浅色模式对比度
# 文档卡片
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-600/80 bg-gray-700/95 shadow-lg"\s+:\s+"border-gray-200/80 bg-white shadow-lg"',
    'isDarkMode ? "border-gray-500/60 bg-gray-700 shadow-xl" : "border-gray-300 bg-white shadow-lg"',
    content
)

# 顶部横幅
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-600/80 bg-gray-700/95 shadow-lg"\s+:\s+"border-gray-200/80 bg-white shadow-lg"',
    'isDarkMode ? "border-gray-500/60 bg-gray-700 shadow-2xl" : "border-gray-300 bg-white shadow-xl"',
    content,
    count=1
)

# 背景渐变
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gradient-to-b from-gray-950 via-gray-900 to-gray-950',
    'isDarkMode ? "bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950',
    content
)
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gradient-to-b from-gray-100 via-gray-50 to-gray-100',
    'isDarkMode ? "bg-gradient-to-br from-gray-50 via-white to-gray-100',
    content
)

# Header
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-600/60 bg-gray-900/90"',
    'isDarkMode ? "border-gray-500/40 bg-gray-900/95 shadow-lg"',
    content
)
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-200/80 bg-white/95"',
    'isDarkMode ? "border-gray-300 bg-white/98 shadow-md"',
    content
)

# 搜索框
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-600/50 bg-gray-800/70',
    'isDarkMode ? "border-gray-500/60 bg-gray-800/90',
    content
)
content = re.sub(
    r'border-gray-300/80 bg-white shadow',
    'border-gray-400 bg-white shadow',
    content
)

# 添加搜索框聚焦效果
content = re.sub(
    r'focus-within:border-gray-400 focus-within:shadow',
    'focus-within:border-blue-500 focus-within:shadow-[0_25px_60px_rgba(59,130,246,0.2)] focus-within:ring-2 focus-within:ring-blue-500/30',
    content
)

# 3. 优化深色模式 AI 元素
# AI 标签
content = re.sub(
    r'isDarkMode\s+\?\s+"border-blue-800/50 bg-blue-900/30 text-blue-300"',
    'isDarkMode ? "border-blue-500/60 bg-blue-500/20 text-blue-300 shadow-[0_0_15px_rgba(59,130,246,0.3)]"',
    content
)
content = re.sub(
    r'isDarkMode\s+\?\s+"border-blue-100 bg-blue-50/80 text-blue-700"',
    'isDarkMode ? "border-blue-400 bg-blue-100 text-blue-700 shadow-sm"',
    content
)

# AI 速读模块
content = re.sub(
    r'isDarkMode\s+\?\s+"border-blue-900/50 bg-blue-900/20 text-gray-300"',
    'isDarkMode ? "border-blue-500/60 bg-gradient-to-br from-blue-500/25 via-indigo-500/20 to-purple-500/25 text-gray-200 shadow-[0_0_30px_rgba(59,130,246,0.4)]"',
    content
)
content = re.sub(
    r'isDarkMode\s+\?\s+"border-blue-100 bg-blue-50/80 text-gray-600"',
    'isDarkMode ? "border-blue-300 bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 text-gray-700 shadow-[0_4px_20px_rgba(59,130,246,0.15)]"',
    content
)

# AI 速读标题
content = re.sub(
    r'isDarkMode\s+\?\s+"text-blue-400"',
    'isDarkMode ? "text-cyan-300 drop-shadow-[0_0_8px_rgba(103,232,249,0.6)]"',
    content,
    count=1
)

# AI 角度文字
content = re.sub(
    r'isDarkMode\s+\?\s+"text-blue-300"',
    'isDarkMode ? "text-cyan-300"',
    content
)

# 4. 优化按钮和交互
# 排序按钮
content = re.sub(
    r'"rounded-full border px-4 py-2 capitalize transition"',
    '"rounded-full border-2 px-4 py-2 capitalize transition-all duration-200 font-medium"',
    content
)

# AI 速读按钮（如果还没更新）
if 'from-cyan-500 to-blue-600' not in content:
    content = re.sub(
        r'showAIRead\s+\?\s+isDarkMode\s+\?\s+"bg-gray-500 text-white border-gray-400 shadow-lg"',
        'showAIRead ? isDarkMode ? "bg-gradient-to-r from-cyan-500 to-blue-600 text-white border-cyan-400 shadow-[0_0_25px_rgba(6,182,212,0.6)] scale-105"',
        content
    )

# 分享按钮
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gray-700 hover:bg-gray-600"',
    'isDarkMode ? "bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 border border-blue-400/50"',
    content
)

# 卡片悬停效果
content = re.sub(
    r'hover:shadow-2xl duration-300',
    'hover:shadow-2xl hover:-translate-y-1 duration-300',
    content
)

# 查看次数标签
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gray-700 text-gray-300"',
    'isDarkMode ? "bg-gray-800/90 border border-gray-600/50 text-gray-200 shadow-lg"',
    content
)
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gray-200 text-gray-700"',
    'isDarkMode ? "bg-white/95 border border-gray-200 text-gray-700 shadow-md"',
    content
)

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ UI 优化已应用")
PYEOF

echo ""
echo "=== 验证修改 ==="
echo "检查图标按钮："
grep -A 1 "w-10 h-10" src/App.tsx | head -3

echo ""
echo "=== 重新构建 ==="
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅✅✅ UI 优化已应用并构建完成！"
else
    echo ""
    echo "❌ 构建失败，恢复备份："
    echo "  cp src/App.tsx.bak_ui_optimize src/App.tsx"
fi


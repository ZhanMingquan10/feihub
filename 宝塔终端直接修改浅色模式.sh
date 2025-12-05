#!/bin/bash
# 在宝塔终端直接执行此命令，优化浅色模式 UI

cd /www/wwwroot/feihub && \
python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. 增强背景对比度
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gradient-to-br from-gray-50 via-white to-gray-100',
    'isDarkMode ? "bg-gradient-to-br from-gray-100 via-gray-50 to-gray-100',
    content
)

# 2. Header 边框增强
content = re.sub(
    r'border-b backdrop-blur-xl transition-colors duration-300", isDarkMode \? "border-gray-500/40 bg-gray-900/95 shadow-lg" : "border-gray-300 bg-white/98 shadow-md"',
    'border-b-2 backdrop-blur-xl transition-colors duration-300", isDarkMode ? "border-gray-500/40 bg-gray-900/95 shadow-lg" : "border-gray-400 bg-white shadow-lg"',
    content
)

# 3. 主卡片边框增强
content = re.sub(
    r'rounded-3xl border p-8 text-center shadow-glass transition-colors duration-300", isDarkMode \? "border-gray-500/60 bg-gray-700 shadow-2xl" : "border-gray-300 bg-white shadow-xl"',
    'rounded-3xl border-2 p-8 text-center shadow-glass transition-colors duration-300", isDarkMode ? "border-gray-500/60 bg-gray-700 shadow-2xl" : "border-gray-400 bg-white shadow-2xl"',
    content
)

# 4. 文档卡片边框增强
content = re.sub(
    r'rounded-3xl border p-6 shadow-glass transition-all duration-300 hover:shadow-2xl hover:-translate-y-1",\s+isDarkMode\s+\?\s+"border-gray-500/60 bg-gray-700 shadow-xl"\s+:\s+"border-gray-300 bg-white shadow-lg"',
    'rounded-3xl border-2 p-6 shadow-glass transition-all duration-300 hover:shadow-2xl hover:-translate-y-1",\n                isDarkMode \n                  ? "border-gray-500/60 bg-gray-700 shadow-xl" \n                  : "border-gray-400 bg-white shadow-xl"',
    content
)

# 5. AI 标签优化（发光和渐变）
content = re.sub(
    r'isDarkMode\s+\?\s+"border-blue-500/60 bg-blue-500/20 text-blue-300 shadow-\[0_0_15px_rgba\(59,130,246,0\.3\)\]"\s+:\s+"border-blue-400 bg-blue-100 text-blue-700 shadow-sm"',
    'isDarkMode ? "border-blue-500/60 bg-blue-500/20 text-blue-300 shadow-[0_0_15px_rgba(59,130,246,0.3)]" : "border-blue-500 bg-gradient-to-r from-blue-100 to-indigo-100 text-blue-700 shadow-[0_0_12px_rgba(59,130,246,0.25)] font-semibold"',
    content
)

# 6. AI 标签边框改为 border-2
content = re.sub(
    r'rounded-full border px-3 py-1 text-xs font-medium transition-all duration-200 hover:scale-105", isDarkMode \? "border-blue-500/60 bg-blue-500/20 text-blue-300 shadow-\[0_0_15px_rgba\(59,130,246,0\.3\)\]" : "border-blue-500 bg-gradient-to-r from-blue-100 to-indigo-100',
    'rounded-full border-2 px-3 py-1 text-xs font-medium transition-all duration-200 hover:scale-105", isDarkMode ? "border-blue-500/60 bg-blue-500/20 text-blue-300 shadow-[0_0_15px_rgba(59,130,246,0.3)]" : "border-blue-500 bg-gradient-to-r from-blue-100 to-indigo-100',
    content
)

# 7. AI 速读模块优化（发光和渐变）
content = re.sub(
    r'isDarkMode\s+\?\s+"border-blue-500/60 bg-gradient-to-br from-blue-500/25 via-indigo-500/20 to-purple-500/25 text-gray-200 shadow-\[0_0_30px_rgba\(59,130,246,0\.4\)\]"\s+:\s+"border-blue-300 bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 text-gray-700 shadow-\[0_4px_20px_rgba\(59,130,246,0\.15\)\]"',
    'isDarkMode ? "border-blue-500/60 bg-gradient-to-br from-blue-500/25 via-indigo-500/20 to-purple-500/25 text-gray-200 shadow-[0_0_30px_rgba(59,130,246,0.4)]" : "border-blue-500 bg-gradient-to-br from-blue-100 via-indigo-100 to-purple-100 text-gray-800 shadow-[0_0_25px_rgba(59,130,246,0.3)]"',
    content
)

# 8. AI 速读标题优化
content = re.sub(
    r'isDarkMode\s+\?\s+"text-cyan-300 drop-shadow-\[0_0_8px_rgba\(103,232,249,0\.6\)\]"\s+:\s+"text-blue-600 font-extrabold"',
    'isDarkMode ? "text-cyan-300 drop-shadow-[0_0_8px_rgba(103,232,249,0.6)]" : "text-blue-700 drop-shadow-[0_0_6px_rgba(37,99,235,0.4)] font-extrabold"',
    content
)

# 9. AI 角度文字优化
content = re.sub(
    r'font-semibold", isDarkMode \? "text-cyan-300" : "text-blue-700"',
    'font-bold", isDarkMode ? "text-cyan-300" : "text-blue-700 drop-shadow-[0_0_4px_rgba(37,99,235,0.3)]"',
    content
)

# 10. AI 内容文字优化
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
content = re.sub(
    r'isDarkMode\s+\?\s+"text-gray-300"\s+:\s+"text-gray-700"',
    'isDarkMode ? "text-gray-300" : "text-gray-800"',
    content
)

# 11. 搜索框聚焦效果增强
content = re.sub(
    r'isDarkMode\s+\?\s+"border-gray-500/60 bg-gray-800/90 shadow-\[0_20px_45px_rgba\(0,0,0,0\.4\)\] focus-within:border-blue-500/60 focus-within:shadow-\[0_25px_60px_rgba\(59,130,246,0\.3\)\] focus-within:ring-2 focus-within:ring-blue-500/20"\s+:\s+"border-gray-400 bg-white shadow-\[0_20px_45px_rgba\(0,0,0,0\.1\)\] focus-within:border-blue-500 focus-within:shadow-\[0_25px_60px_rgba\(59,130,246,0\.2\)\] focus-within:ring-2 focus-within:ring-blue-500/30"',
    'isDarkMode ? "border-gray-500/60 bg-gray-800/90 shadow-[0_20px_45px_rgba(0,0,0,0.4)] focus-within:border-blue-500/60 focus-within:shadow-[0_25px_60px_rgba(59,130,246,0.3)] focus-within:ring-2 focus-within:ring-blue-500/20" : "border-gray-400 bg-white shadow-[0_20px_45px_rgba(0,0,0,0.15)] focus-within:border-blue-500 focus-within:shadow-[0_25px_60px_rgba(59,130,246,0.3)] focus-within:ring-2 focus-within:ring-blue-500/40"',
    content
)

# 12. 查看次数标签优化
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gray-800/90 border border-gray-600/50 text-gray-200 shadow-lg"\s+:\s+"bg-white/95 border border-gray-200 text-gray-700 shadow-md"',
    'isDarkMode ? "bg-gray-800/90 border border-gray-600/50 text-gray-200 shadow-lg" : "bg-white border-2 border-gray-300 text-gray-800 shadow-lg font-medium"',
    content
)

# 13. AI速读按钮优化
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gradient-to-r from-cyan-500 to-blue-600 text-white border-cyan-400 shadow-\[0_0_25px_rgba\(6,182,212,0\.6\)\] scale-105"\s+:\s+"bg-gradient-to-r from-blue-500 to-indigo-600 text-white border-blue-400 shadow-lg scale-105"',
    'isDarkMode ? "bg-gradient-to-r from-cyan-500 to-blue-600 text-white border-cyan-400 shadow-[0_0_25px_rgba(6,182,212,0.6)] scale-105" : "bg-gradient-to-r from-blue-500 to-indigo-600 text-white border-blue-400 shadow-[0_0_20px_rgba(59,130,246,0.4)] scale-105"',
    content
)

# 14. AI速读按钮未激活状态
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gray-800/80 text-gray-400 border-gray-600 hover:border-cyan-500/50 hover:text-cyan-300 hover:bg-cyan-500/10"\s+:\s+"bg-white text-gray-600 border-gray-300 hover:border-blue-400 hover:text-blue-600 hover:bg-blue-50 shadow-sm"',
    'isDarkMode ? "bg-gray-800/80 text-gray-400 border-gray-600 hover:border-cyan-500/50 hover:text-cyan-300 hover:bg-cyan-500/10" : "bg-white text-gray-700 border-gray-400 hover:border-blue-500 hover:text-blue-700 hover:bg-blue-50 shadow-md"',
    content
)

# 15. Footer 优化
content = re.sub(
    r'border-t transition-colors duration-300", isDarkMode \? "border-gray-600/80 bg-gray-800/90" : "border-gray-200/80 bg-white/95"',
    'border-t-2 transition-colors duration-300", isDarkMode ? "border-gray-600/80 bg-gray-800/90" : "border-gray-400 bg-white shadow-lg"',
    content
)

# 16. 分享文档按钮优化
content = re.sub(
    r'isDarkMode\s+\?\s+"bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 border border-blue-400/50"\s+:\s+"bg-gradient-to-r from-gray-900 to-black hover:from-gray-800 hover:to-gray-900 border border-gray-700"',
    'isDarkMode ? "bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 border border-blue-400/50" : "bg-gradient-to-r from-gray-900 to-black hover:from-gray-800 hover:to-gray-900 border-2 border-gray-700 shadow-[0_0_20px_rgba(0,0,0,0.3)]"',
    content
)

# 17. AI速读标题文字优化（Hero区域）
content = re.sub(
    r'isDarkMode\s+\?\s+"from-cyan-400 via-blue-400 to-indigo-400 drop-shadow-\[0_0_15px_rgba\(96,165,250,0\.9\)\] animate-pulse"\s+:\s+"from-blue-500 via-indigo-600 to-purple-600 drop-shadow-\[0_0_8px_rgba\(59,130,246,0\.6\)\]"',
    'isDarkMode ? "from-cyan-400 via-blue-400 to-indigo-400 drop-shadow-[0_0_15px_rgba(96,165,250,0.9)] animate-pulse" : "from-blue-600 via-indigo-600 to-purple-600 drop-shadow-[0_0_12px_rgba(59,130,246,0.5)] font-extrabold"',
    content
)

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 浅色模式 UI 优化已应用")
PYEOF
npm run build && echo "✅✅✅ 构建完成！"


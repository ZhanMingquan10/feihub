#!/bin/bash
# 在服务器上精确修复分享按钮

cd /www/wwwroot/feihub && python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print("=== 精确修复分享按钮 ===")

# 先查看分享按钮的实际代码
for i, line in enumerate(lines):
    if '分享文档' in line and i >= 420 and i <= 450:
        print(f"\n找到分享文档在第 {i+1} 行")
        # 显示前后10行
        for j in range(max(0, i-10), min(i+10, len(lines))):
            print(f"{j+1:4d}: {lines[j].rstrip()}")
        break

# 精确查找并替换分享按钮
button_found = False
for i, line in enumerate(lines):
    if '<button' in line and 'fixed bottom-6' in line and i >= 420 and i <= 450:
        print(f"\n找到按钮开始: 第 {i+1} 行")
        print(f"按钮行内容: {line.rstrip()[:100]}")
        
        # 查找按钮结束
        button_end = -1
        for j in range(i, min(i+15, len(lines))):
            if '</button>' in lines[j]:
                button_end = j + 1
                break
        
        if button_end > i:
            button_content = ''.join(lines[i:button_end])
            print(f"按钮结束: 第 {button_end} 行")
            print(f"按钮完整内容:\n{button_content[:300]}")
            
            if 'isScrolled' not in button_content:
                # 直接替换
                new_button = '''      <button
        className={clsx(
          "fixed bottom-6 right-6 flex items-center justify-center rounded-full text-white shadow-2xl transition-all duration-300 hover:scale-110 hover:shadow-[0_0_30px_rgba(0,0,0,0.5)] z-50",
          isDarkMode 
            ? "bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 border border-blue-400/50" 
            : "bg-gradient-to-r from-gray-900 to-black hover:from-gray-800 hover:to-gray-900 border-2 border-gray-700 shadow-[0_0_20px_rgba(0,0,0,0.3)]",
          isScrolled 
            ? "px-3 py-3 w-12 h-12 md:w-14 md:h-14 gap-0" 
            : "px-5 py-3 gap-2 w-auto h-auto"
        )}
        onClick={() => setShowUpload(true)}
        title={isScrolled ? "分享文档" : ""}
      >
        <Upload size={isScrolled ? 18 : 16} className="flex-shrink-0" />
        <span className={clsx(
          "transition-all duration-300 whitespace-nowrap overflow-hidden",
          isScrolled ? "w-0 opacity-0" : "w-auto opacity-100"
        )}>
          分享文档
        </span>
      </button>
'''
                lines[i:button_end] = new_button.split('\n')
                button_found = True
                print(f"✅ 替换分享按钮: 第 {i+1} 行到第 {button_end} 行")
            else:
                print("✅ 分享按钮已使用 isScrolled")
                button_found = True
            break

if not button_found:
    print("❌ 未找到分享按钮，尝试其他方法...")
    # 查找包含 "分享文档" 的所有位置
    for i, line in enumerate(lines):
        if '分享文档' in line:
            print(f"找到'分享文档'文本在第 {i+1} 行: {line.rstrip()[:80]}")

content = '\n'.join(lines)

# 最终验证
print("\n=== 最终验证 ===")
if 'isScrolled ? "px-3 py-3 w-12 h-12' in content:
    print("✅ 分享按钮使用了 isScrolled")
    # 显示按钮代码片段
    idx = content.find('isScrolled ? "px-3 py-3 w-12 h-12')
    print(f"按钮代码片段:\n{content[max(0, idx-50):idx+200]}")
else:
    print("❌ 分享按钮未使用 isScrolled")
    # 查找分享按钮的实际代码
    idx = content.find('分享文档')
    if idx > 0:
        print(f"分享文档附近代码:\n{content[max(0, idx-200):idx+200]}")

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ 修复完成！")
PYEOF
npm run build 2>&1 | tail -20 && echo "✅✅✅ 构建完成！"


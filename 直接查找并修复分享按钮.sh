#!/bin/bash
# 直接查找并修复分享按钮

cd /www/wwwroot/feihub && python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print("=== 直接查找并修复分享按钮 ===")

# 方法1: 直接搜索包含 "分享文档" 的所有行
print("查找所有包含'分享文档'的行:")
for i, line in enumerate(lines):
    if '分享文档' in line:
        print(f"  第 {i+1} 行: {line.rstrip()[:100]}")

# 方法2: 直接搜索包含 "fixed bottom-6" 的行
print("\n查找所有包含'fixed bottom-6'的行:")
for i, line in enumerate(lines):
    if 'fixed bottom-6' in line:
        print(f"  第 {i+1} 行: {line.rstrip()[:150]}")
        # 显示前后几行
        for j in range(max(0, i-2), min(i+8, len(lines))):
            print(f"    {j+1}: {lines[j].rstrip()[:120]}")

# 方法3: 直接替换 - 使用更简单的匹配
content = '\n'.join(lines)

# 查找分享按钮的精确模式
# 查找: <button ... className={clsx("fixed bottom-6 ... 分享文档 ... </button>
button_pattern = r'(<button\s+className=\{clsx\("fixed bottom-6 right-6[^}]+\)\}\s+onClick=\{\(\) => setShowUpload\(true\)\}>[^<]*<Upload size=\{16\} />[^<]*分享文档[^<]*</button>)'

match = re.search(button_pattern, content, re.DOTALL)
if match:
    print(f"\n✅ 找到分享按钮（使用正则）")
    print(f"按钮代码长度: {len(match.group(1))}")
    print(f"按钮代码预览: {match.group(1)[:200]}")
    
    # 替换
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
      </button>'''
    
    content = content.replace(match.group(1), new_button)
    print("✅ 已替换分享按钮")
else:
    print("\n❌ 正则未找到，使用行号方法...")
    # 使用行号方法：直接在第423-429行替换
    for i in range(420, min(440, len(lines))):
        if '<button' in lines[i] and 'fixed' in lines[i]:
            print(f"找到按钮开始: 第 {i+1} 行")
            # 查找结束
            button_end = -1
            for j in range(i, min(i+10, len(lines))):
                if '</button>' in lines[j]:
                    button_end = j + 1
                    break
            
            if button_end > i:
                print(f"按钮结束: 第 {button_end} 行")
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
                content = '\n'.join(lines)
                print(f"✅ 已替换分享按钮: 第 {i+1} 行到第 {button_end} 行")
                break

# 验证
print("\n=== 验证 ===")
if 'isScrolled ? "px-3 py-3 w-12 h-12' in content:
    print("✅ 分享按钮使用了 isScrolled")
else:
    print("❌ 分享按钮未使用 isScrolled")
    # 再次查找
    idx = content.find('分享文档')
    if idx > 0:
        print(f"\n分享文档位置: {idx}")
        print(f"附近代码:\n{content[max(0, idx-300):idx+300]}")

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ 修复完成！")
PYEOF
npm run build && echo "✅✅✅ 构建完成！"


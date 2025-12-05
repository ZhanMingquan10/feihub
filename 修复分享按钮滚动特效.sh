#!/bin/bash
# 完整修复分享按钮滚动折叠特效

cd /www/wwwroot/feihub && python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print("=== 完整修复分享按钮滚动折叠特效 ===")

# 步骤1: 添加 isScrolled 状态
found_scrolled = False
for i, line in enumerate(lines):
    if 'const [isScrolled, setIsScrolled]' in line:
        found_scrolled = True
        print(f"✅ isScrolled 状态已存在: 第 {i+1} 行")
        break

if not found_scrolled:
    # 在 copied 状态后添加
    for i, line in enumerate(lines):
        if 'const [copied, setCopied] = useState(false);' in line:
            lines.insert(i+1, '  const [isScrolled, setIsScrolled] = useState(false);\n')
            print(f"✅ 添加 isScrolled 状态: 第 {i+2} 行")
            break

# 步骤2: 添加滚动监听 useEffect
found_listener = False
for i, line in enumerate(lines):
    if 'handleScrollForButton' in line or ('setIsScrolled' in line and 'scrollTop' in line):
        found_listener = True
        print(f"✅ 滚动监听已存在: 第 {i+1} 行")
        break

if not found_listener:
    # 在最后一个 useEffect 后添加
    for i in range(len(lines)-1, -1, -1):
        if '}, [filteredDocs.length, displayedCount]);' in lines[i]:
            scroll_effect = '''  // 监听滚动，实现分享按钮折叠效果
  useEffect(() => {
    const handleScrollForButton = () => {
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop || window.scrollY;
      setIsScrolled(scrollTop > 50);
    };

    window.addEventListener("scroll", handleScrollForButton);
    handleScrollForButton(); // 初始检查
    return () => window.removeEventListener("scroll", handleScrollForButton);
  }, []);

'''
            lines.insert(i+1, scroll_effect)
            print(f"✅ 添加滚动监听: 第 {i+2} 行")
            break

# 步骤3: 修改分享按钮
button_modified = False
for i, line in enumerate(lines):
    if '分享文档' in line and '<button' in ''.join(lines[max(0, i-10):i+1]):
        # 向上查找 button 开始
        button_start = -1
        for j in range(i, max(0, i-15), -1):
            if '<button' in lines[j] and 'fixed bottom-6' in lines[j]:
                button_start = j
                break
        
        if button_start >= 0:
            # 查找 button 结束
            button_end = -1
            for j in range(i, min(i+10, len(lines))):
                if '</button>' in lines[j]:
                    button_end = j + 1
                    break
            
            if button_end > button_start:
                # 检查是否已经使用了 isScrolled
                button_content = ''.join(lines[button_start:button_end])
                if 'isScrolled' not in button_content:
                    # 替换整个按钮
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
                    lines[button_start:button_end] = new_button.split('\n')
                    button_modified = True
                    print(f"✅ 修改分享按钮: 第 {button_start+1} 行到第 {button_end} 行")
                    break

if not button_modified:
    print("❌ 未找到分享按钮，尝试备用方法...")
    # 备用方法：直接查找并替换
    content = '\n'.join(lines)
    if '<button' in content and '分享文档' in content:
        # 使用正则替换
        content = re.sub(
            r'(<button\s+className=\{clsx\("fixed bottom-6 right-6[^"]*"[^}]*\}\)[^>]*onClick=\{\(\) => setShowUpload\(true\)\}>)\s*<Upload size=\{16\} />\s*分享文档\s*</button>',
            '''<button
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
      </button>''',
            content,
            flags=re.DOTALL
        )
        lines = content.split('\n')
        print("✅ 使用备用方法修改分享按钮")

content = '\n'.join(lines)

# 验证修复
print("\n=== 验证修复 ===")
if 'const [isScrolled, setIsScrolled]' in content:
    print("✅ isScrolled 状态存在")
else:
    print("❌ isScrolled 状态不存在")

if 'handleScrollForButton' in content:
    print("✅ 滚动监听存在")
else:
    print("❌ 滚动监听不存在")

if 'isScrolled ? "px-3 py-3 w-12 h-12' in content:
    print("✅ 分享按钮使用了 isScrolled")
else:
    print("❌ 分享按钮未使用 isScrolled")

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ 修复完成！")
PYEOF
npm run build 2>&1 | tail -20 && echo "✅✅✅ 构建完成！"


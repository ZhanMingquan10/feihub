#!/bin/bash
# 将本地最新版本应用到服务器

cd /www/wwwroot/feihub && python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    content = f.read()

print("=== 恢复最新版本到服务器 ===")

# 修复1: 添加 Share2 到导入
if 'Share2' not in content:
    content = re.sub(
        r'import \{ Upload, Search, Eye, Moon, Sun, FileText, Activity, MessageCircle \} from "lucide-react";',
        'import { Upload, Search, Eye, Moon, Sun, FileText, Activity, MessageCircle, Share2 } from "lucide-react";',
        content
    )
    print("✅ 添加 Share2 到导入")

# 修复2: 添加 isScrolled 状态
if 'const [isScrolled, setIsScrolled]' not in content:
    content = re.sub(
        r'(const \[copied, setCopied\] = useState\(false\);.*?// 是否已复制微信号)',
        r'\1\n  const [isScrolled, setIsScrolled] = useState(false); // 滚动状态，用于分享按钮折叠',
        content,
        flags=re.DOTALL
    )
    print("✅ 添加 isScrolled 状态")

# 修复3: 添加滚动监听
if 'handleScrollForButton' not in content:
    content = re.sub(
        r'(}, \[filteredDocs\.length, displayedCount\]\);)\s*(const handleUpload)',
        r'''\1

  // 监听滚动，实现分享按钮折叠效果
  useEffect(() => {
    const handleScrollForButton = () => {
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop || window.scrollY;
      setIsScrolled(scrollTop > 50);
    };

    window.addEventListener("scroll", handleScrollForButton);
    handleScrollForButton(); // 初始检查
    return () => window.removeEventListener("scroll", handleScrollForButton);
  }, []);

  \2''',
        content
    )
    print("✅ 添加滚动监听")

# 修复4: 修复分享按钮（使用 isScrolled 和 Share2）
# 查找分享按钮
old_button_pattern = r'<button\s+className=\{clsx\("fixed bottom-6 right-6[^"]*"[^}]*\}\)[^>]*onClick=\{\(\) => setShowUpload\(true\)\}>[^<]*<Upload[^>]*>[^<]*分享文档[^<]*</button>'

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
        <Share2 size={isScrolled ? 18 : 16} className="flex-shrink-0" />
        <span className={clsx(
          "transition-all duration-300 whitespace-nowrap overflow-hidden",
          isScrolled ? "w-0 opacity-0" : "w-auto opacity-100"
        )}>
          分享文档
        </span>
      </button>'''

if re.search(old_button_pattern, content, re.DOTALL):
    content = re.sub(old_button_pattern, new_button, content, flags=re.DOTALL)
    print("✅ 修复分享按钮（使用 isScrolled 和 Share2）")
elif 'isScrolled ? "px-3 py-3 w-12 h-12' not in content:
    # 如果没匹配到，使用行号方法
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if '分享文档' in line and '<button' in ''.join(lines[max(0, i-10):i+1]):
            button_start = -1
            for j in range(i, max(0, i-15), -1):
                if '<button' in lines[j] and 'fixed bottom-6' in lines[j]:
                    button_start = j
                    break
            
            if button_start >= 0:
                button_end = -1
                for j in range(i, min(i+10, len(lines))):
                    if '</button>' in lines[j]:
                        button_end = j + 1
                        break
                
                if button_end > button_start:
                    lines[button_start:button_end] = new_button.split('\n')
                    print(f"✅ 修复分享按钮: 第 {button_start+1} 行到第 {button_end} 行")
                    break
    
    content = '\n'.join(lines)

# 修复5: 修复 AI速读 位置
content = re.sub(
    r'absolute -right-14 -top-4 text-xs font-bold uppercase tracking-\[0\.5em\]',
    'absolute right-1 top-1 md:-right-14 md:-top-4 text-[7px] md:text-xs font-bold uppercase tracking-[0.05em] md:tracking-[0.5em]',
    content
)
if 'right-1 top-1 md:-right-14' in content:
    print("✅ 修复 AI速读 位置")

# 验证
print("\n=== 验证 ===")
checks = [
    ('Share2', 'Share2 图标'),
    ('isScrolled', 'isScrolled 状态'),
    ('handleScrollForButton', '滚动监听'),
    ('isScrolled ? "px-3 py-3 w-12 h-12', '分享按钮滚动折叠'),
    ('right-1 top-1 md:-right-14', 'AI速读位置')
]

for check, name in checks:
    if check in content:
        print(f"✅ {name} 已存在")
    else:
        print(f"❌ {name} 不存在")

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ 最新版本已恢复！")
PYEOF
npm run build && echo "✅✅✅ 构建完成！"


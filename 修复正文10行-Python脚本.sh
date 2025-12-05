#!/bin/bash

# 修复正文显示10行 - Python 脚本方法

cd /www/wwwroot/feihub

echo "=== 备份原文件 ==="
cp src/App.tsx src/App.tsx.bak
echo "✅ 已备份到 src/App.tsx.bak"

echo ""
echo "=== 使用 Python 脚本修改 ==="

python3 << 'PYTHON_SCRIPT'
import re

file_path = 'src/App.tsx'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 查找需要修改的 <p> 标签
# 匹配包含 doc.preview && doc.preview.length > 500 的 <p> 标签及其内容
pattern = r'(<p className=\{clsx\("mt-4 text-sm leading-relaxed whitespace-pre-wrap", isDarkMode \? "text-gray-300" : "text-gray-600"\)\}>)\s*(\{doc\.preview && doc\.preview\.length > 500 \? `\$\{doc\.preview\.slice\(0, 500\)\}\.\.\.` : \(doc\.preview \|\| "暂无预览"\)\})\s*(</p>)'

# 替换为新的代码
replacement = '''<p className={clsx("mt-4 text-sm leading-relaxed whitespace-pre-wrap overflow-hidden", isDarkMode ? "text-gray-300" : "text-gray-600")} style={{ display: '-webkit-box', WebkitLineClamp: 10, WebkitBoxOrient: 'vertical' }}>
                {doc.preview || "暂无预览"}
              </p>'''

new_content = re.sub(pattern, replacement, content)

if new_content == content:
    print("❌ 未找到匹配的代码")
    print("尝试查找包含 'doc.preview && doc.preview.length' 的行...")
    # 尝试更宽松的匹配
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'doc.preview && doc.preview.length' in line:
            print(f"找到第 {i+1} 行: {line.strip()[:80]}...")
    exit(1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("✅ 代码修改成功")
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "=== 验证修改 ==="
    grep -n "WebkitLineClamp" src/App.tsx
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ 修改成功！"
        echo ""
        echo "=== 重新构建前端 ==="
        npm run build
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ 构建成功！"
            echo ""
            echo "=== 重载 Nginx ==="
            nginx -s reload
            echo ""
            echo "✅ 完成！请清除浏览器缓存（Ctrl+Shift+R）后刷新页面"
        else
            echo "❌ 构建失败，请检查错误信息"
        fi
    else
        echo "❌ 修改失败，WebkitLineClamp 未找到"
    fi
else
    echo ""
    echo "❌ Python 脚本执行失败"
    echo "请使用 nano 手动编辑（见修复正文10行-简单方法.md）"
fi


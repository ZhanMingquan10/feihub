#!/bin/bash

# 修复正文显示10行 - 手动修改命令

cd /www/wwwroot/feihub

echo "=== 备份原文件 ==="
cp src/App.tsx src/App.tsx.bak
echo "✅ 已备份到 src/App.tsx.bak"

echo ""
echo "=== 修改代码 ==="

# 使用 sed 修改第380行左右的代码
# 找到包含 "doc.preview && doc.preview.length > 500" 的行，替换整个 <p> 标签

# 方法：先找到行号，然后替换
LINE_NUM=$(grep -n "doc.preview && doc.preview.length > 500" src/App.tsx | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
    echo "❌ 找不到需要修改的行"
    exit 1
fi

echo "找到需要修改的行：第 $LINE_NUM 行"

# 查看上下文
echo ""
echo "修改前的代码："
sed -n "$((LINE_NUM-2)),$((LINE_NUM+2))p" src/App.tsx

# 使用 Python 脚本进行精确替换（更安全）
cat > /tmp/fix_app_tsx.py << 'PYTHON_SCRIPT'
import re
import sys

file_path = sys.argv[1]

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 查找并替换 <p> 标签
# 匹配模式：包含 doc.preview && doc.preview.length > 500 的 <p> 标签
pattern = r'(<p className=\{clsx\("mt-4 text-sm leading-relaxed whitespace-pre-wrap", isDarkMode \? "text-gray-300" : "text-gray-600"\)\}>)\s*(\{doc\.preview && doc\.preview\.length > 500 \? `\$\{doc\.preview\.slice\(0, 500\)\}\.\.\.` : \(doc\.preview \|\| "暂无预览"\)\})\s*(</p>)'

replacement = r'''<p className={clsx("mt-4 text-sm leading-relaxed whitespace-pre-wrap overflow-hidden", isDarkMode ? "text-gray-300" : "text-gray-600")} style={{ display: '-webkit-box', WebkitLineClamp: 10, WebkitBoxOrient: 'vertical' }}>
                {doc.preview || "暂无预览"}
              </p>'''

new_content = re.sub(pattern, replacement, content)

if new_content == content:
    print("❌ 未找到匹配的代码，可能需要手动修改")
    sys.exit(1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("✅ 代码修改成功")
PYTHON_SCRIPT

python3 /tmp/fix_app_tsx.py src/App.tsx

if [ $? -eq 0 ]; then
    echo ""
    echo "=== 验证修改 ==="
    echo "修改后的代码："
    sed -n "$((LINE_NUM-2)),$((LINE_NUM+2))p" src/App.tsx
    
    echo ""
    echo "=== 检查是否包含 WebkitLineClamp ==="
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
            exit 1
        fi
    else
        echo "❌ 修改失败，WebkitLineClamp 未找到"
        exit 1
    fi
else
    echo "❌ Python 脚本执行失败，使用手动方法"
    exit 1
fi


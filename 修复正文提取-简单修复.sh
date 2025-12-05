#!/bin/bash

# 修复正文提取问题 - 简单修复脚本

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 查找需要修复的文件 ==="
FILES=$(ls feishu*.ts 2>/dev/null)

if [ -z "$FILES" ]; then
    echo "❌ 未找到 feishu*.ts 文件"
    exit 1
fi

echo "找到文件: $FILES"

for FILE in $FILES; do
    echo ""
    echo "=== 处理文件: $FILE ==="
    
    # 备份
    cp "$FILE" "${FILE}.bak"
    echo "✅ 已备份"
    
    # 检查是否包含内容提取逻辑
    if ! grep -q "querySelector\|innerText\|textContent" "$FILE"; then
        echo "⚠️  文件不包含内容提取逻辑，跳过"
        continue
    fi
    
    # 使用 sed 添加过滤逻辑
    # 在提取文本后添加过滤（在 const text = ... 之后）
    if grep -q "const.*text.*=.*innerText\|const.*text.*=.*textContent" "$FILE"; then
        echo "✅ 找到内容提取代码，开始修复..."
        
        # 方法：在 return text.trim() 之前添加过滤
        # 但 sed 处理多行比较复杂，改用 Python
        python3 << PYEOF
import re

file_path = '$FILE'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 在 return text.trim() 或类似语句前添加过滤
# 查找模式：在循环中返回文本的地方
pattern = r'(if\s*\([^)]*text[^)]*length[^)]*\)\s*\{[^}]*return\s+[^;]+;)'

def add_filter(match):
    return_stmt = match.group(1)
    # 在 return 前添加过滤
    return '''// 过滤导航栏内容
            const textContent = text.trim();
            if (textContent && (
                textContent.includes('Help Center') || 
                textContent.includes('Keyboard Shortcuts') ||
                textContent.includes('Token Limit') ||
                textContent.includes('快捷键') ||
                textContent.split(/\\s+/).length < 10
            )) {
              continue; // 跳过无效内容
            }
            ''' + return_stmt

content = re.sub(pattern, add_filter, content)

# 更简单的方法：在 bodyText 提取后添加清理
if 'bodyText' in content:
    # 在 bodyText = ... trim() 后添加过滤
    pattern2 = r'(bodyText\s*=\s*[^;]+\.trim\(\);)'
    def add_body_filter(match):
        return match.group(1) + '''
        
        // 移除导航栏文本
        bodyText = bodyText
            .replace(/Help Center[^\\n]*/gi, '')
            .replace(/Keyboard Shortcuts[^\\n]*/gi, '')
            .replace(/Token Limit[^\\n]*/gi, '')
            .replace(/快捷键[^\\n]*/gi, '')
            .replace(/\\s+/g, ' ')
            .trim();
        
        // 验证内容有效性
        if (bodyText.length < 100 || (!/[\\u4e00-\\u9fa5]/.test(bodyText) && bodyText.length < 200)) {
            bodyText = '';
        }'''
    content = re.sub(pattern2, add_body_filter, content)

if content != original:
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ 已修复")
else:
    print("⚠️  未找到匹配的模式，可能需要手动修改")
PYEOF
    else
        echo "⚠️  未找到标准的内容提取模式"
    fi
done

echo ""
echo "=== 验证修复 ==="
for FILE in $FILES; do
    if grep -q "Help Center\|Keyboard Shortcuts" "$FILE"; then
        echo "✅ $FILE 已包含过滤逻辑"
    fi
done

echo ""
echo "=== 重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build && pm2 restart feihub-backend && echo "✅ 修复完成！"


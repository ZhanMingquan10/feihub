#!/bin/bash

# 修复正文提取问题 - 通用修复方案
# 这个脚本会修复所有 feishu 相关文件中的内容提取逻辑

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：备份文件 ==="
for file in feishu*.ts; do
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak"
        echo "✅ 已备份: $file"
    fi
done

echo ""
echo "=== 第二步：查找需要修改的文件 ==="

# 查找包含内容提取逻辑的文件
for file in feishu*.ts; do
    if [ -f "$file" ] && grep -q "querySelector.*content\|innerText\|textContent" "$file"; then
        echo "找到需要修改的文件: $file"
        
        # 检查是否已经包含 Help Center 过滤
        if grep -q "Help Center\|Keyboard Shortcuts" "$file"; then
            echo "  ⚠️  文件已包含 Help Center 过滤，但可能不够彻底"
        else
            echo "  ❌ 文件未包含 Help Center 过滤"
        fi
    fi
done

echo ""
echo "=== 第三步：使用 Python 脚本修复 ==="

python3 << 'PYEOF'
import re
import os
import glob

# 查找所有 feishu*.ts 文件
files = glob.glob('feishu*.ts')

for file_path in files:
    if not os.path.isfile(file_path):
        continue
    
    print(f"\n处理文件: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 查找内容提取的代码块（包含 querySelector 和 innerText/textContent）
    # 改进：更彻底地排除导航栏内容
    
    # 模式1: 查找包含 querySelector 的内容提取代码
    pattern1 = r'(const\s+text\s*=\s*(?:cloned|element|body)\.(?:innerText|textContent)[^;]*;)'
    
    # 在提取文本后添加过滤逻辑
    replacement1 = r'''\1
            
            // 过滤掉导航栏和帮助中心内容
            if (text && (
                text.includes('Help Center') || 
                text.includes('Keyboard Shortcuts') ||
                text.includes('快捷键') ||
                text.includes('Token Limit') ||
                text.trim().split(/\s+/).length < 10 ||
                (!/[\u4e00-\u9fa5]/.test(text) && text.length < 200)
            )) {
              continue; // 跳过这个元素
            }'''
    
    content = re.sub(pattern1, replacement1, content)
    
    # 模式2: 在返回文本前添加最终过滤
    pattern2 = r'(return\s+(?:text|bodyText|cleanText|content)[^;]*;)'
    
    def add_final_filter(match):
        return_match = match.group(1)
        # 在 return 前添加过滤
        return f'''// 最终过滤：排除导航栏内容
            let finalText = {return_match.split('return')[1].strip().rstrip(';')};
            if (finalText && (
                finalText.includes('Help Center') || 
                finalText.includes('Keyboard Shortcuts') ||
                finalText.includes('Token Limit') ||
                (!/[\u4e00-\u9fa5]/.test(finalText) && finalText.length < 200)
            )) {
              finalText = ''; // 清空无效内容
            }
            return finalText;'''
    
    # 更简单的方法：在内容提取的 evaluate 函数中添加过滤
    # 查找 page.evaluate 中的内容提取逻辑
    if 'page.evaluate' in content and 'querySelector' in content:
        # 在提取文本后、返回前添加过滤
        pattern3 = r'(const\s+(?:text|bodyText|cleanText)\s*=\s*[^;]+;\s*)(?=\s*if\s*\(|return)'
        
        def add_filter_after_extract(match):
            extract_line = match.group(1)
            return extract_line + '''
            // 过滤导航栏和帮助中心内容
            if (text && (
                text.includes('Help Center') || 
                text.includes('Keyboard Shortcuts') ||
                text.includes('Token Limit') ||
                text.trim().split(/\\s+/).length < 10
            )) {
              text = ''; // 清空无效内容
            }
            '''
        
        content = re.sub(pattern3, add_filter_after_extract, content, flags=re.MULTILINE)
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✅ 已修改: {file_path}")
    else:
        print(f"  ⚠️  未找到需要修改的代码模式")

print("\n=== 修复完成 ===")
PYEOF

echo ""
echo "=== 第四步：验证修改 ==="
for file in feishu*.ts; do
    if [ -f "$file" ] && grep -q "Help Center\|Keyboard Shortcuts" "$file"; then
        echo "✅ $file 已包含过滤逻辑"
        echo "   相关行："
        grep -n "Help Center\|Keyboard Shortcuts" "$file" | head -3
    fi
done

echo ""
echo "=== 第五步：重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "=== 第六步：重启服务 ==="
    pm2 restart feihub-backend
    echo ""
    echo "✅✅✅ 修复完成！请重新测试文档提取"
else
    echo "❌ 构建失败，请检查错误信息"
    echo "可以恢复备份："
    echo "  cd /www/wwwroot/feihub/backend/src/lib"
    echo "  cp feishu*.ts.bak feishu*.ts"
fi


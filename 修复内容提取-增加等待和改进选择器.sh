#!/bin/bash

# 修复内容提取问题 - 增加等待时间和改进选择器

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：检查实际使用的文件 ==="
FILES=$(ls feishu*.ts 2>/dev/null)
echo "找到文件: $FILES"

for FILE in $FILES; do
    echo ""
    echo "=== 处理文件: $FILE ==="
    
    # 备份
    cp "$FILE" "${FILE}.bak"
    
    # 使用 Python 修复
    python3 << PYEOF
import re

file_path = '$FILE'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 修复1: 增加等待时间（从5秒增加到10秒，并添加内容等待）
if 'await new Promise(resolve => setTimeout(resolve, 5000))' in content:
    content = content.replace(
        'await new Promise(resolve => setTimeout(resolve, 5000));',
        '''// 等待内容渲染（增加等待时间）
        await new Promise(resolve => setTimeout(resolve, 10000));
        
        // 等待正文内容出现（如果存在）
        try {
            await page.waitForSelector('[class*="content"], [class*="body"], [class*="main"], article, .wiki-content, .doc-content', { timeout: 10000 });
            console.log('[内容提取] 找到内容元素，继续等待3秒确保完全渲染...');
            await new Promise(resolve => setTimeout(resolve, 3000));
        } catch (e) {
            console.log('[内容提取] 未找到内容元素，继续提取...');
        }'''
    )
    print("  ✅ 已增加等待时间")

# 修复2: 改进内容提取逻辑，优先选择包含中文的内容
# 查找内容提取的 evaluate 函数
pattern = r'(content\s*=\s*await\s+page\.evaluate\(\(\)\s*=>\s*\{[^}]+)(return\s+result;)'

def improve_extraction(match):
    evaluate_start = match.group(1)
    return_stmt = match.group(2)
    
    # 在返回前添加更智能的选择逻辑
    improved = evaluate_start + '''
        
        // 改进的内容提取：优先选择包含中文且足够长的内容
        const allContentElements = document.querySelectorAll('[class*="content"], [class*="body"], [class*="main"], article, .wiki-content, .doc-content, [data-content]');
        
        let bestContent = '';
        let bestScore = 0;
        
        for (const elem of allContentElements) {
            // 克隆并清理
            const clone = elem.cloneNode(true);
            clone.querySelectorAll('script, style, nav, header, footer, button, [class*="nav"], [class*="help"], [class*="Help"]').forEach(el => el.remove());
            
            const text = (clone.innerText || clone.textContent || '').trim();
            
            // 跳过无效内容
            if (text.includes('Help Center') || 
                text.includes('Keyboard Shortcuts') ||
                text.includes('Token Limit') ||
                text.length < 50) {
                continue;
            }
            
            // 计算内容质量分数
            let score = 0;
            const chineseCount = (text.match(/[\\u4e00-\\u9fa5]/g) || []).length;
            score += chineseCount * 10; // 中文越多越好
            score += text.length; // 长度越长越好
            score -= (text.match(/Help|Shortcut|Token/gi) || []).length * 100; // 包含导航词汇扣分
            
            if (score > bestScore && text.length > 100) {
                bestScore = score;
                bestContent = text;
            }
        }
        
        // 如果找到高质量内容，返回它
        if (bestContent.length > 100) {
            return bestContent;
        }
        
        // 否则使用原来的逻辑
        ''' + return_stmt
    
    return improved

content = re.sub(pattern, improve_extraction, content, flags=re.DOTALL)

# 修复3: 在 body 提取时也添加智能选择
if 'body.innerText' in content or 'body.textContent' in content:
    # 在 bodyText 提取后添加更彻底的清理
    pattern2 = r'(let\s+bodyText\s*=\s*\(body\.(?:innerText|textContent)[^;]+\.trim\(\);)'
    def improve_body_extract(match):
        return match.group(1) + '''
        
        // 移除所有导航和帮助相关的内容
        bodyText = bodyText
            .replace(/Help Center[^\\n]*/gi, '')
            .replace(/Keyboard Shortcuts[^\\n]*/gi, '')
            .replace(/Token Limit[^\\n]*/gi, '')
            .replace(/快捷键[^\\n]*/gi, '')
            .replace(/\\s+/g, ' ')
            .trim();
        
        // 查找包含中文的主要段落
        const paragraphs = bodyText.split(/\\n\\n+|\\r\\n\\r\\n+/);
        const chineseParagraphs = paragraphs.filter(p => /[\\u4e00-\\u9fa5]/.test(p) && p.length > 50);
        
        if (chineseParagraphs.length > 0) {
            // 返回包含中文的段落
            bodyText = chineseParagraphs.join('\\n\\n');
        } else if (bodyText.length < 100 || (!/[\\u4e00-\\u9fa5]/.test(bodyText) && bodyText.length < 200)) {
            bodyText = '';
        }'''
    content = re.sub(pattern2, improve_body_extract, content)

if content != original:
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("  ✅ 已修复文件")
else:
    print("  ⚠️  未找到需要修改的代码模式")
PYEOF
done

echo ""
echo "=== 第二步：重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功"
    echo ""
    echo "=== 第三步：重启服务 ==="
    pm2 restart feihub-backend
    echo ""
    echo "✅✅✅ 修复完成！"
    echo ""
    echo "现在会："
    echo "1. 等待更长时间（10秒 + 3秒）"
    echo "2. 等待内容元素出现"
    echo "3. 优先选择包含中文且足够长的内容"
    echo "4. 过滤掉导航栏内容"
else
    echo "❌ 构建失败，请检查错误"
fi


#!/bin/bash

# 修复内容提取 - 修复 cheerio 和选择器

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：查看 cheerio 备用方案的代码 ==="
grep -A 30 "cheerio 备用方案" feishu-puppeteer.ts | head -40

echo ""
echo "=== 第二步：修复 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 修复1: 在 cheerio 提取后添加过滤
if 'cheerio 备用方案' in content:
    # 查找 cheerio 提取内容的模式
    # 通常在 cheerio 备用方案后会有 content = $('...').text() 或类似代码
    pattern1 = r'(const content = [^;]+cheerio[^;]+;)'
    
    def add_cheerio_filter(match):
        extract_line = match.group(1)
        return extract_line + '''
        
        // 过滤导航栏内容
        if (content && (content.includes('Help Center') || content.includes('Keyboard Shortcuts') || content.includes('Token Limit'))) {
          content = '';
        }'''
    
    content = re.sub(pattern1, add_cheerio_filter, content)

# 修复2: 改进 page.evaluate 中的选择器，优先选择包含中文的区域
# 查找 selectors 数组，添加更精确的选择器
import re

# 查找 const selectors = [...] 的模式
pattern2 = r"(const selectors = \[[^\]]+\])"

# 由于选择器可能跨多行，使用更简单的方法：在循环中添加智能选择
# 查找 for (const selector of selectors) 循环
# 在循环内，优先选择包含中文的元素

# 更直接的方法：在提取文本后，立即验证并跳过导航栏
# 查找 let text = clone.innerText 的模式
pattern3 = r'(let text = clone\.innerText \|\| clone\.textContent \|\| \'\';)'

def add_early_validation(match):
    return match.group(1) + '''
              
              // 立即验证：排除导航栏内容（在任何处理之前）
              if (text && (text.includes('Help Center') || text.includes('Keyboard Shortcuts') || text.includes('Token Limit'))) {
                continue; // 跳过导航栏内容
              }'''

content = re.sub(pattern3, add_early_validation, content)

# 修复3: 在 cheerio 备用方案中添加过滤
if 'cheerio 备用方案' in content:
    # 查找 cheerio 提取后的内容处理
    # 通常在 cheerio 提取后会有 content = ... 的赋值
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'cheerio 备用方案' in line:
            # 查找后面的 content 赋值
            for j in range(i+1, min(i+50, len(lines))):
                if 'content =' in lines[j] and ('$(' in lines[j] or '.text()' in lines[j] or 'cheerio' in lines[j].lower()):
                    # 在这行后添加过滤
                    indent = len(lines[j]) - len(lines[j].lstrip())
                    indent_str = ' ' * indent
                    # 查找下一个非空行
                    k = j + 1
                    while k < len(lines) and (not lines[k].strip() or lines[k].strip().startswith('//')):
                        k += 1
                    # 检查是否已有过滤
                    has_filter = any('Help Center' in lines[m] for m in range(j+1, min(j+20, len(lines))))
                    if not has_filter:
                        lines.insert(k, f"{indent_str}\n")
                        lines.insert(k+1, f"{indent_str}// 过滤导航栏内容\n")
                        lines.insert(k+2, f"{indent_str}if (content && (content.includes('Help Center') || content.includes('Keyboard Shortcuts') || content.includes('Token Limit'))) {{\n")
                        lines.insert(k+3, f"{indent_str}  content = ''; // 清空无效内容\n")
                        lines.insert(k+4, f"{indent_str}}}\n")
                        print(f"✅ 在 cheerio 提取后添加过滤（第 {j+1} 行后）")
                    break
            break
    content = '\n'.join(lines)

if content != original:
    with open('feishu-puppeteer.ts.bak15', 'w', encoding='utf-8') as f:
        f.write(original)
    with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ 修复完成")
else:
    print("⚠️  未找到需要修改的代码")
PYEOF

echo ""
echo "=== 第三步：重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "=== 重启服务 ==="
    pm2 restart feihub-backend
    echo ""
    echo "✅✅✅ 修复完成！"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
fi


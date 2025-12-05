#!/bin/bash

# 修复内容提取 - 查看并修复代码

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：查看内容提取的代码 ==="
echo "查找 '从页面直接提取内容' 相关的代码："
grep -n "从页面直接提取内容\|page.evaluate.*content\|querySelector.*content" feishu-puppeteer.ts | head -10

echo ""
echo "=== 第二步：查看内容提取的具体实现 ==="
# 查找 page.evaluate 中内容提取的部分
grep -A 100 "从页面直接提取内容" feishu-puppeteer.ts | head -120

echo ""
echo "=== 第三步：修复内容提取逻辑 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 查找内容提取的 page.evaluate 部分
# 需要找到提取内容的逻辑，并改进选择器

# 方法1: 查找包含 "从页面直接提取内容" 的代码块
# 然后找到对应的 page.evaluate 函数

# 更直接的方法：查找所有 page.evaluate 中提取内容的部分
# 并添加更精确的选择器和过滤

import re

# 查找 content = await page.evaluate 的模式
# 然后在 evaluate 函数内改进内容提取逻辑

# 查找模式：content = await page.evaluate((pageTitle) => { ... });
# 需要找到这个函数的完整内容，然后修改其中的选择器

# 由于代码可能跨多行，使用更简单的方法：
# 在 page.evaluate 函数内，查找选择器部分，添加更精确的选择

# 查找包含 selectors 数组的部分
pattern = r"(const selectors = \[[^\]]+\])"

def improve_selectors(match):
    selectors = match.group(1)
    # 添加更精确的选择器，优先选择包含中文内容的区域
    improved = '''const selectors = [
          // 优先选择包含中文内容的区域
          '[class*="content"]:has-text([\\u4e00-\\u9fa5])',
          '[class*="body"]:has-text([\\u4e00-\\u9fa5])',
          'article:has-text([\\u4e00-\\u9fa5])',
          '.wiki-content',
          '.wiki-body',
          '.doc-content',
          '.doc-body',
          'main article',
          'article',
          '[role="main"]',
          '.document-content',
          '.page-content',
          '[class*="content"]',
          '[class*="body"]',
          '[class*="main"]'
        ];'''
    return improved

# 但 :has-text 可能不支持，改用其他方法
# 更好的方法：在选择器循环后添加内容验证

# 查找 for (const selector of selectors) 循环
# 在循环内添加内容验证，跳过包含 "Help Center" 的内容

pattern2 = r"(for \(const selector of selectors\) \{[\s\S]*?const text = [^;]+;[\s\S]*?if \(text\.trim\(\)\.length > 100\) \{[\s\S]*?return text\.trim\(\);[\s\S]*?\}[\s\S]*?\})"

def add_validation(match):
    loop_code = match.group(1)
    # 在 return text.trim() 前添加验证
    if 'Help Center' not in loop_code or 'Keyboard Shortcuts' not in loop_code:
        # 在 return 前添加验证
        loop_code = loop_code.replace(
            'return text.trim();',
            '''// 验证内容：排除导航栏
            if (text.includes('Help Center') || 
                text.includes('Keyboard Shortcuts') ||
                text.includes('Token Limit') ||
                text.trim().split(/\\s+/).length < 10 ||
                (!/[\\u4e00-\\u9fa5]/.test(text) && text.length < 200)) {
              continue; // 跳过无效内容
            }
            return text.trim();'''
        )
    return loop_code

content = re.sub(pattern2, add_validation, content, flags=re.MULTILINE)

# 如果上面的正则太复杂，使用更简单的方法：
# 直接查找并替换 return text.trim() 的地方

# 查找所有 return text.trim() 或类似模式
lines = content.split('\n')
fixed_lines = []
in_evaluate = False
for i, line in enumerate(lines):
    if 'content = await page.evaluate' in line:
        in_evaluate = True
    if in_evaluate and '});' in line:
        in_evaluate = False
    
    # 在 evaluate 函数内，查找 return text.trim()
    if in_evaluate and 'return text.trim()' in line:
        # 在这行前添加验证
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        fixed_lines.append(f"{indent_str}// 验证内容：排除导航栏")
        fixed_lines.append(f"{indent_str}if (text.includes('Help Center') || text.includes('Keyboard Shortcuts') || text.includes('Token Limit') || text.trim().split(/\\s+/).length < 10 || (!/[\\u4e00-\\u9fa5]/.test(text) && text.length < 200)) {{")
        fixed_lines.append(f"{indent_str}  continue;")
        fixed_lines.append(f"{indent_str}}")
        print(f"在第 {i+1} 行前添加验证")
    
    fixed_lines.append(line)

if len(fixed_lines) != len(lines):
    content = '\n'.join(fixed_lines)

if content != original:
    with open('feishu-puppeteer.ts.bak11', 'w', encoding='utf-8') as f:
        f.write(original)
    with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ 已修复内容提取逻辑")
else:
    print("⚠️  未找到需要修改的代码")
PYEOF

echo ""
echo "=== 第四步：重新构建 ==="
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


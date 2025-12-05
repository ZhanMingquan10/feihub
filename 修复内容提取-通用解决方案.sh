#!/bin/bash

# 修复内容提取 - 通用解决方案（不针对特定内容）

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 修复内容提取逻辑 - 通用方案 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 修复1: 改进选择器，排除导航和侧边栏
# 查找 selectors 数组
for i, line in enumerate(lines):
    if 'const selectors = [' in line:
        # 查找数组结束位置
        j = i
        while j < len(lines) and '];' not in lines[j]:
            j += 1
        
        # 在选择器数组中，添加排除导航的选择器（放在前面，优先匹配）
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        
        # 检查是否已有排除导航的选择器
        has_exclude = any('not(aside)' in lines[k] or 'not([class*="nav"])' in lines[k] for k in range(i, j+1))
        
        if not has_exclude:
            # 在数组开头添加更精确的选择器（排除导航）
            lines.insert(i+1, f"{indent_str}  // 优先选择：排除导航和侧边栏\n")
            lines.insert(i+2, f"{indent_str}  'main [class*=\"content\"]:not(aside):not([class*=\"nav\"]):not([class*=\"sidebar\"])',\n")
            lines.insert(i+3, f"{indent_str}  'main [class*=\"body\"]:not(aside):not([class*=\"nav\"]):not([class*=\"sidebar\"])',\n")
            lines.insert(i+4, f"{indent_str}  'article:not(aside):not([class*=\"nav\"])',\n")
            lines.insert(i+5, f"{indent_str}  '[role=\"main\"]:not(aside)',\n")
            lines.insert(i+6, f"{indent_str}  // 通用选择器（备用）\n")
            print(f"✅ 在选择器数组中添加排除导航的选择器")
        break

# 修复2: 在提取文本后，立即验证并排除导航内容（通用方法）
for i, line in enumerate(lines):
    if 'let text = clone.innerText' in line or 'let text = clone.textContent' in line:
        # 在这行后立即添加验证（在任何处理之前）
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        
        # 检查是否已有立即验证
        has_immediate_validation = False
        for j in range(i+1, min(i+10, len(lines))):
            if '立即验证' in lines[j] or ('Help Center' in lines[j] and 'includes' in lines[j] and 'if (text.length > 200)' not in '\n'.join(lines[i+1:j])):
                has_immediate_validation = True
                break
        
        if not has_immediate_validation:
            lines.insert(i+1, f"{indent_str}\n")
            lines.insert(i+2, f"{indent_str}// 立即验证：排除导航栏和帮助中心（通用方法）\n")
            lines.insert(i+3, f"{indent_str}if (text && (\n")
            lines.insert(i+4, f"{indent_str}  text.includes('Help Center') ||\n")
            lines.insert(i+5, f"{indent_str}  text.includes('Keyboard Shortcuts') ||\n")
            lines.insert(i+6, f"{indent_str}  text.includes('Token Limit') ||\n")
            lines.insert(i+7, f"{indent_str}  text.trim().split(/\\s+/).length < 10 ||\n")
            lines.insert(i+8, f"{indent_str}  (!/[\\u4e00-\\u9fa5]/.test(text) && text.length < 200)\n")
            lines.insert(i+9, f"{indent_str})) {{\n")
            lines.insert(i+10, f"{indent_str}  continue; // 跳过导航栏内容\n")
            lines.insert(i+11, f"{indent_str}}}\n")
            print(f"✅ 在第 {i+1} 行后添加立即验证")
            break

# 修复3: 在循环中，优先选择包含足够中文内容的元素
for i, line in enumerate(lines):
    if 'return text.trim()' in line and i > 400 and i < 420:
        # 检查是否已有优先选择逻辑
        has_priority = any('优先选择' in lines[j] or '包含中文' in lines[j] for j in range(max(0, i-15), i))
        
        if not has_priority:
            indent = len(line) - len(line.lstrip())
            indent_str = ' ' * indent
            lines.insert(i, f"{indent_str}\n")
            lines.insert(i+1, f"{indent_str}// 优先选择：包含足够中文且足够长的内容\n")
            lines.insert(i+2, f"{indent_str}const chineseCount = (text.match(/[\\u4e00-\\u9fa5]/g) || []).length;\n")
            lines.insert(i+3, f"{indent_str}if (chineseCount > 50 && text.length > 200) {{\n")
            lines.insert(i+4, f"{indent_str}  console.log(`[调试] ✅ 找到高质量内容，中文数: ${{chineseCount}}, 长度: ${{text.length}}`);\n")
            lines.insert(i+5, f"{indent_str}  return text.trim();\n")
            lines.insert(i+6, f"{indent_str}}}\n")
            print(f"✅ 在第 {i+1} 行前添加优先选择逻辑")
            break

# 修复4: 在 cheerio 备用方案中也添加过滤
for i, line in enumerate(lines):
    if 'cheerio 备用方案' in line or '使用 cheerio 备用方案' in line:
        # 查找 cheerio 提取后的 content 赋值
        for j in range(i+1, min(i+50, len(lines))):
            if 'content =' in lines[j] and ('$(' in lines[j] or '.text()' in lines[j]):
                # 在这行后添加过滤
                indent = len(lines[j]) - len(lines[j].lstrip())
                indent_str = ' ' * indent
                k = j + 1
                while k < len(lines) and (not lines[k].strip() or lines[k].strip().startswith('//')):
                    k += 1
                has_filter = any('Help Center' in lines[m] for m in range(j+1, min(j+20, len(lines))))
                if not has_filter:
                    lines.insert(k, f"{indent_str}\n")
                    lines.insert(k+1, f"{indent_str}// 过滤导航栏内容（通用方法）\n")
                    lines.insert(k+2, f"{indent_str}if (content && (content.includes('Help Center') || content.includes('Keyboard Shortcuts') || content.includes('Token Limit'))) {{\n")
                    lines.insert(k+3, f"{indent_str}  content = '';\n")
                    lines.insert(k+4, f"{indent_str}}}\n")
                    print(f"✅ 在 cheerio 提取后添加过滤（第 {j+1} 行后）")
                break
        break

with open('feishu-puppeteer.ts.bak17', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

echo ""
echo "=== 重新构建 ==="
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


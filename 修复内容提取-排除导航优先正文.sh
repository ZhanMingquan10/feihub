#!/bin/bash

# 修复内容提取 - 排除导航，优先选择正文

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：查看当前的选择器逻辑 ==="
grep -A 20 "const selectors = \[" feishu-puppeteer.ts | head -25

echo ""
echo "=== 第二步：修复选择器和提取逻辑 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 修复1: 改进选择器，排除左侧导航
# 查找 selectors 数组
for i, line in enumerate(lines):
    if 'const selectors = [' in line:
        # 查看选择器数组的结束位置
        j = i
        while j < len(lines) and '];' not in lines[j]:
            j += 1
        
        # 在选择器数组中添加更精确的选择器，排除导航
        # 在 ]; 前添加新的选择器
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        
        # 检查是否已有排除导航的选择器
        has_nav_exclude = False
        for k in range(i, j+1):
            if 'aside' in lines[k] or 'sidebar' in lines[k] or 'nav' in lines[k]:
                has_nav_exclude = True
                break
        
        if not has_nav_exclude:
            # 在 ]; 前添加排除导航的选择器
            lines.insert(j, f"{indent_str}  // 排除导航区域，优先选择主要内容区域\n")
            lines.insert(j+1, f"{indent_str}  'main [class*=\"content\"]:not(aside):not([class*=\"nav\"]):not([class*=\"sidebar\"])',\n")
            lines.insert(j+2, f"{indent_str}  'main [class*=\"body\"]:not(aside):not([class*=\"nav\"])',\n")
            print(f"✅ 在选择器数组中添加排除导航的选择器（第 {j+1} 行前）")
        break

# 修复2: 在提取文本后，优先选择包含正文开头的元素
# 查找 let text = clone.innerText 的位置
for i, line in enumerate(lines):
    if 'let text = clone.innerText' in line or 'let text = clone.textContent' in line:
        # 在 text.trim() 后，添加智能选择逻辑
        # 查找 text.trim() 的位置
        for j in range(i+1, min(i+50, len(lines))):
            if 'text = text.trim();' in lines[j]:
                # 在这行后添加逻辑：如果包含导航关键词，尝试提取正文部分
                indent = len(lines[j]) - len(lines[j].lstrip())
                indent_str = ' ' * indent
                
                # 检查是否已有这个逻辑
                has_nav_removal = False
                for k in range(j+1, min(j+30, len(lines))):
                    if '版本一' in lines[k] or '版本二' in lines[k]:
                        has_nav_removal = True
                        break
                
                if not has_nav_removal:
                    lines.insert(j+1, f"{indent_str}\n")
                    lines.insert(j+2, f"{indent_str}// 如果包含导航内容，尝试提取正文部分\n")
                    lines.insert(j+3, f"{indent_str}if (text.includes('版本一') || text.includes('版本二') || text.includes('一、让') || text.includes('二、让')) {{\n")
                    lines.insert(j+4, f"{indent_str}  // 查找正文开始的位置（通常是标题后的第一个段落）\n")
                    lines.insert(j+5, f"{indent_str}  const titleMatch = text.match(/热点话题转瞬即逝[^\\n]*/);\n")
                    lines.insert(j+6, f"{indent_str}  if (titleMatch) {{\n")
                    lines.insert(j+7, f"{indent_str}    const afterTitle = text.substring(titleMatch.index + titleMatch[0].length);\n")
                    lines.insert(j+8, f"{indent_str}    // 查找正文开始（通常是'嗨'、'你好'等开头）\n")
                    lines.insert(j+9, f"{indent_str}    const bodyStart = afterTitle.search(/[嗨你好我是][^\\n]{10,}/);\n")
                    lines.insert(j+10, f"{indent_str}    if (bodyStart > 0 && bodyStart < 500) {{\n")
                    lines.insert(j+11, f"{indent_str}      text = afterTitle.substring(bodyStart);\n")
                    lines.insert(j+12, f"{indent_str}      console.log(`[调试] 从导航+正文中提取正文部分，新长度: ${{text.length}}`);\n")
                    lines.insert(j+13, f"{indent_str}    }}\n")
                    lines.insert(j+14, f"{indent_str}  }}\n")
                    lines.insert(j+15, f"{indent_str}}}\n")
                    print(f"✅ 在第 {j+1} 行后添加导航移除逻辑")
                break
        break

# 修复3: 在选择器循环中，优先选择包含正文开头的元素
# 查找 for (const selector of selectors) 循环
for i, line in enumerate(lines):
    if 'for (const selector of selectors)' in line:
        # 在循环内，找到 return text.trim() 的位置
        for j in range(i+1, min(i+200, len(lines))):
            if 'return text.trim()' in lines[j]:
                # 在这行前添加：优先选择包含正文开头的元素
                indent = len(lines[j]) - len(lines[j].lstrip())
                indent_str = ' ' * indent
                
                # 检查是否已有优先选择逻辑
                has_priority = False
                for k in range(max(0, j-20), j):
                    if '包含正文开头' in lines[k] or '优先选择' in lines[k]:
                        has_priority = True
                        break
                
                if not has_priority:
                    lines.insert(j, f"{indent_str}\n")
                    lines.insert(j+1, f"{indent_str}// 优先选择包含正文开头的元素\n")
                    lines.insert(j+2, f"{indent_str}if (text.includes('嗨，你好') || text.includes('我是') || (text.includes('应届') && text.includes('毕业生'))) {{\n")
                    lines.insert(j+3, f"{indent_str}  console.log(`[调试] 找到包含正文开头的元素，长度: ${{text.length}}`);\n")
                    lines.insert(j+4, f"{indent_str}  return text.trim();\n")
                    lines.insert(j+5, f"{indent_str}}}\n")
                    print(f"✅ 在第 {j+1} 行前添加优先选择逻辑")
                break
        break

with open('feishu-puppeteer.ts.bak16', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
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


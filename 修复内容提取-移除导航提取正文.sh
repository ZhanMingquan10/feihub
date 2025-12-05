#!/bin/bash

# 修复内容提取 - 移除导航，提取正文部分

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 修复内容提取逻辑 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 在 text.trim() 后添加逻辑：如果包含导航，提取正文部分
for i, line in enumerate(lines):
    if 'text = text.trim();' in line and i > 350 and i < 400:
        # 检查是否已有这个逻辑
        has_nav_removal = False
        for j in range(i+1, min(i+30, len(lines))):
            if '版本一' in lines[j] or '提取正文部分' in lines[j]:
                has_nav_removal = True
                break
        
        if not has_nav_removal:
            indent = len(line) - len(line.lstrip())
            indent_str = ' ' * indent
            
            # 在 text.trim() 后添加导航移除逻辑
            lines.insert(i+1, f"{indent_str}\n")
            lines.insert(i+2, f"{indent_str}// 如果包含导航内容，提取正文部分\n")
            lines.insert(i+3, f"{indent_str}if (text.includes('版本一') || text.includes('版本二') || text.includes('一、让') || text.includes('二、让')) {{\n")
            lines.insert(i+4, f"{indent_str}  // 查找正文开始位置（通常是'嗨'、'你好'等开头）\n")
            lines.insert(i+5, f"{indent_str}  const bodyStart = text.search(/[嗨你好我是][^\\n]{10,}|应届[^\\n]{5,}/);\n")
            lines.insert(i+6, f"{indent_str}  if (bodyStart > 0 && bodyStart < 1000) {{\n")
            lines.insert(i+7, f"{indent_str}    text = text.substring(bodyStart);\n")
            lines.insert(i+8, f"{indent_str}    console.log(`[调试] 从导航+正文中提取正文，新长度: ${{text.length}}`);\n")
            lines.insert(i+9, f"{indent_str}  }}\n")
            lines.insert(i+10, f"{indent_str}}}\n")
            print(f"✅ 在第 {i+1} 行后添加导航移除逻辑")
            break

# 在 return text.trim() 前添加：优先选择包含正文开头的元素
for i, line in enumerate(lines):
    if 'return text.trim()' in line and i > 400 and i < 420:
        # 检查是否已有优先选择逻辑
        has_priority = False
        for j in range(max(0, i-10), i):
            if '包含正文开头' in lines[j] or '优先选择' in lines[j]:
                has_priority = True
                break
        
        if not has_priority:
            indent = len(line) - len(line.lstrip())
            indent_str = ' ' * indent
            lines.insert(i, f"{indent_str}\n")
            lines.insert(i+1, f"{indent_str}// 优先选择包含正文开头的元素\n")
            lines.insert(i+2, f"{indent_str}if (text.includes('嗨，你好') || text.includes('我是') || (text.includes('应届') && text.includes('毕业生'))) {{\n")
            lines.insert(i+3, f"{indent_str}  console.log(`[调试] ✅ 找到包含正文开头的元素`);\n")
            lines.insert(i+4, f"{indent_str}  return text.trim();\n")
            lines.insert(i+5, f"{indent_str}}}\n")
            print(f"✅ 在第 {i+1} 行前添加优先选择逻辑")
            break

with open('feishu-puppeteer.ts.bak16', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

echo ""
echo "=== 重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build && pm2 restart feihub-backend && echo "✅ 修复完成！"


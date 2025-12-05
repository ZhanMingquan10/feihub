#!/bin/bash

# 修复内容提取 - 按照 Log In or Sign Up 规则提取

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 查看 body 提取的代码 ==="
sed -n '450,520p' feishu-puppeteer.ts

echo ""
echo "=== 修复：按照 Log In or Sign Up 规则提取 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找 bodyText 提取后的处理位置
# 在 return bodyText.trim(); 前添加新的提取逻辑
for i, line in enumerate(lines):
    if 'return bodyText.trim();' in line and i > 450:
        # 在这行前添加新的提取逻辑
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        
        # 检查是否已有这个逻辑
        has_log_in_rule = False
        for j in range(max(0, i-30), i):
            if 'Log In or Sign Up' in lines[j]:
                has_log_in_rule = True
                break
        
        if not has_log_in_rule:
            # 插入新的提取逻辑
            lines.insert(i, f"{indent_str}\n")
            lines.insert(i+1, f"{indent_str}// 按照 Log In or Sign Up 规则提取\n")
            lines.insert(i+2, f"{indent_str}const logInIndex = bodyText.indexOf('Log In or Sign Up');\n")
            lines.insert(i+3, f"{indent_str}if (logInIndex > 0) {{\n")
            lines.insert(i+4, f"{indent_str}  // 丢弃 Log In or Sign Up 之前的内容\n")
            lines.insert(i+5, f"{indent_str}  bodyText = bodyText.substring(logInIndex + 'Log In or Sign Up'.length);\n")
            lines.insert(i+6, f"{indent_str}  \n")
            lines.insert(i+7, f"{indent_str}  // 找到第一个日期（Modified ... 格式）\n")
            lines.insert(i+8, f"{indent_str}  const dateMatch = bodyText.match(/Modified\\s+([A-Za-z]+)\\s+(\\d{1,2})(?:,\\s*(\\d{4}))?/i);\n")
            lines.insert(i+9, f"{indent_str}  if (dateMatch) {{\n")
            lines.insert(i+10, f"{indent_str}    const dateStart = dateMatch.index;\n")
            lines.insert(i+11, f"{indent_str}    const dateEnd = dateStart + dateMatch[0].length;\n")
            lines.insert(i+12, f"{indent_str}    \n")
            lines.insert(i+13, f"{indent_str}    // 日期前面是标题，后面是正文\n")
            lines.insert(i+14, f"{indent_str}    const titlePart = bodyText.substring(0, dateStart).trim();\n")
            lines.insert(i+15, f"{indent_str}    const contentPart = bodyText.substring(dateEnd).trim();\n")
            lines.insert(i+16, f"{indent_str}    \n")
            lines.insert(i+17, f"{indent_str}    // 提取日期文本用于后续处理\n")
            lines.insert(i+18, f"{indent_str}    const dateText = dateMatch[0];\n")
            lines.insert(i+19, f"{indent_str}    \n")
            lines.insert(i+20, f"{indent_str}    // 只返回正文部分\n")
            lines.insert(i+21, f"{indent_str}    bodyText = contentPart;\n")
            lines.insert(i+22, f"{indent_str}    \n")
            lines.insert(i+23, f"{indent_str}    console.log(`[调试] 按照 Log In 规则提取，标题: "${{titlePart.substring(0, 50)}}", 日期: "${{dateText}}", 正文长度: ${{contentPart.length}}`);\n")
            lines.insert(i+24, f"{indent_str}  }}\n")
            lines.insert(i+25, f"{indent_str}}}\n")
            print(f"✅ 在第 {i+1} 行前添加 Log In 规则提取逻辑")
            break

with open('feishu-puppeteer.ts.bak20', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

echo ""
echo "=== 同时需要修改日期提取逻辑 ==="
echo "需要在 page.evaluate 中返回日期信息，或者在外部提取"

echo ""
echo "=== 验证修复 ==="
sed -n '450,520p' feishu-puppeteer.ts

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


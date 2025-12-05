#!/bin/bash

# 修复提取逻辑 - 完整规则实现

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 修复提取逻辑 - 实现完整规则 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找 return bodyText.trim() 的位置
for i, line in enumerate(lines):
    if 'return bodyText.trim();' in line and i > 450:
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        
        # 检查是否已有这个逻辑
        has_rule = any('Log In or Sign Up' in lines[j] and 'Created on' in lines[j] for j in range(max(0, i-50), i))
        
        if not has_rule:
            # 在 return 前添加完整规则提取
            lines.insert(i, f"{indent_str}\n")
            lines.insert(i+1, f"{indent_str}// 规则1: 丢弃 Log In or Sign Up 前面的内容\n")
            lines.insert(i+2, f"{indent_str}const logInIndex = bodyText.indexOf('Log In or Sign Up');\n")
            lines.insert(i+3, f"{indent_str}if (logInIndex > 0) {{\n")
            lines.insert(i+4, f"{indent_str}  bodyText = bodyText.substring(logInIndex + 'Log In or Sign Up'.length).trim();\n")
            lines.insert(i+5, f"{indent_str}}}\n")
            lines.insert(i+6, f"{indent_str}\n")
            lines.insert(i+7, f"{indent_str}// 规则2: 找到创建或更新日期\n")
            lines.insert(i+8, f"{indent_str}let extractedDate = '';\n")
            lines.insert(i+9, f"{indent_str}let extractedTitle = '';\n")
            lines.insert(i+10, f"{indent_str}let extractedContent = '';\n")
            lines.insert(i+11, f"{indent_str}\n")
            lines.insert(i+12, f"{indent_str}// 匹配日期格式：Created on 或 Modified\n")
            lines.insert(i+13, f"{indent_str}const dateMatch = bodyText.match(/(Created on|Modified)\\s+([A-Za-z]+)\\s+(\\d{{1,2}})(?:,\\s*(\\d{{4}}))?/i);\n")
            lines.insert(i+14, f"{indent_str}if (dateMatch) {{\n")
            lines.insert(i+15, f"{indent_str}  extractedDate = dateMatch[0];\n")
            lines.insert(i+16, f"{indent_str}  const dateStart = dateMatch.index;\n")
            lines.insert(i+17, f"{indent_str}  const dateEnd = dateStart + dateMatch[0].length;\n")
            lines.insert(i+18, f"{indent_str}  \n")
            lines.insert(i+19, f"{indent_str}  // 规则3: 日期前面一行是标题\n")
            lines.insert(i+20, f"{indent_str}  const beforeDate = bodyText.substring(0, dateStart).trim();\n")
            lines.insert(i+21, f"{indent_str}  const linesBeforeDate = beforeDate.split(/\\n+/);\n")
            lines.insert(i+22, f"{indent_str}  if (linesBeforeDate.length > 0) {{\n")
            lines.insert(i+23, f"{indent_str}    extractedTitle = linesBeforeDate[linesBeforeDate.length - 1].trim();\n")
            lines.insert(i+24, f"{indent_str}  }}\n")
            lines.insert(i+25, f"{indent_str}  \n")
            lines.insert(i+26, f"{indent_str}  // 规则4: 日期后面是正文\n")
            lines.insert(i+27, f"{indent_str}  extractedContent = bodyText.substring(dateEnd).trim();\n")
            lines.insert(i+28, f"{indent_str}  \n")
            lines.insert(i+29, f"{indent_str}  console.log(`[调试] 提取结果 - 标题: "${{extractedTitle.substring(0, 50)}}", 日期: "${{extractedDate}}", 正文长度: ${{extractedContent.length}}`);\n")
            lines.insert(i+30, f"{indent_str}  \n")
            lines.insert(i+31, f"{indent_str}  // 使用提取的正文\n")
            lines.insert(i+32, f"{indent_str}  bodyText = extractedContent;\n")
            lines.insert(i+33, f"{indent_str}}}\n")
            print(f"✅ 在第 {i+1} 行前添加完整规则提取")
        
        # 修改 return 语句，返回对象
        if '{ content:' not in line and '{content:' not in line:
            lines[i] = f"{indent_str}return {{ content: bodyText.trim(), date: extractedDate, title: extractedTitle }};\n"
            print(f"✅ 修改 return 语句为返回对象")
        break

# 修改外部代码，处理返回的对象
for i, line in enumerate(lines):
    if 'content = await page.evaluate' in line and i > 410 and i < 420:
        # 查找对应的闭合括号
        for j in range(i+1, min(i+200, len(lines))):
            if '});' in lines[j]:
                indent = len(lines[j]) - len(lines[j].lstrip())
                indent_str = ' ' * indent
                
                # 检查是否已有处理代码
                has_process = any('extractedDate' in lines[k] or 'content.date' in lines[k] for k in range(j+1, min(j+15, len(lines))))
                
                if not has_process:
                    lines.insert(j+1, f"{indent_str}\n")
                    lines.insert(j+2, f"{indent_str}// 处理返回的对象（包含日期、标题和正文）\n")
                    lines.insert(j+3, f"{indent_str}if (content && typeof content === 'object' && content.content) {{\n")
                    lines.insert(j+4, f"{indent_str}  // 如果提取到了日期，更新 dateText\n")
                    lines.insert(j+5, f"{indent_str}  if (content.date && content.date.length > 0) {{\n")
                    lines.insert(j+6, f"{indent_str}    dateText = content.date;\n")
                    lines.insert(j+7, f"{indent_str}    console.log(`[Puppeteer] 从正文中提取到日期: "${{dateText}}"`);\n")
                    lines.insert(j+8, f"{indent_str}  }}\n")
                    lines.insert(j+9, f"{indent_str}  // 如果提取到了标题，更新 title（如果 title 为空）\n")
                    lines.insert(j+10, f"{indent_str}  if (content.title && content.title.length > 0 && (!title || title.length < 5)) {{\n")
                    lines.insert(j+11, f"{indent_str}    title = content.title;\n")
                    lines.insert(j+12, f"{indent_str}    console.log(`[Puppeteer] 从正文中提取到标题: "${{title}}"`);\n")
                    lines.insert(j+13, f"{indent_str}  }}\n")
                    lines.insert(j+14, f"{indent_str}  // 使用提取的正文\n")
                    lines.insert(j+15, f"{indent_str}  content = content.content;\n")
                    lines.insert(j+16, f"{indent_str}}}\n")
                    print(f"✅ 在第 {j+1} 行后添加处理返回对象的代码")
                break
        break

with open('feishu-puppeteer.ts.bak22', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

echo ""
echo "=== 验证修复 ==="
grep -A 40 "规则1: 丢弃 Log In or Sign Up" feishu-puppeteer.ts | head -45

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


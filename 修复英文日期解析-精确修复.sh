#!/bin/bash

cd /www/wwwroot/feihub/backend/src/lib

# 备份
cp feishu-puppeteer.ts feishu-puppeteer.ts.backup5

# 查看完整的代码块
sed -n '355,375p' feishu-puppeteer.ts

# 使用 Python 脚本修复
python3 << 'PYTHON_EOF'
import re

file_path = '/www/wwwroot/feihub/backend/src/lib/feishu-puppeteer.ts'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找第366行（parseChineseDate 调用）
for i in range(len(lines)):
    if i == 365 and 'parseChineseDate' in lines[i]:  # 第366行（0-based index 365）
        indent = len(lines[i]) - len(lines[i].lstrip())
        
        # 在这行之前插入英文日期解析代码
        insert_code = [
            ' ' * indent + '// 先尝试解析英文日期格式（如 "Modified January 9, 2024"）\n',
            ' ' * indent + 'let parsedDate = null;\n',
            ' ' * indent + 'const englishDateMatch = dateText.match(/(?:Modified|Updated)?\\s*(January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{1,2}),\\s*(\\d{4})/i);\n',
            ' ' * indent + 'if (englishDateMatch) {\n',
            ' ' * (indent + 2) + 'const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];\n',
            ' ' * (indent + 2) + 'const monthIndex = monthNames.findIndex(m => m.toLowerCase() === englishDateMatch[1].toLowerCase());\n',
            ' ' * (indent + 2) + 'if (monthIndex !== -1) {\n',
            ' ' * (indent + 4) + 'const year = parseInt(englishDateMatch[3]);\n',
            ' ' * (indent + 4) + 'const month = monthIndex + 1;\n',
            ' ' * (indent + 4) + 'const day = parseInt(englishDateMatch[2]);\n',
            ' ' * (indent + 4) + 'parsedDate = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;\n',
            ' ' * (indent + 4) + 'console.log(`[Puppeteer] ✅ 解析英文日期成功: "${dateText}" -> "${parsedDate}"`);\n',
            ' ' * (indent + 2) + '}\n',
            ' ' * indent + '}\n',
            ' ' * indent + '\n',
            ' ' * indent + '// 如果英文日期解析失败，使用 parseChineseDate\n',
            ' ' * indent + 'if (!parsedDate) {\n',
            ' ' * (indent + 2) + 'console.log(`[Puppeteer] 准备解析日期: "${dateText}"`);\n',
        ]
        
        # 修改 parseChineseDate 调用，添加缩进
        lines[i] = ' ' * (indent + 2) + 'dateText = parseChineseDate(dateText);\n'
        
        # 查找并修改后面的日志输出
        if i + 1 < len(lines) and '解析后的日期' in lines[i + 1]:
            lines[i + 1] = ' ' * (indent + 2) + 'console.log(`[Puppeteer] 解析后的日期: "${dateText}"`);\n'
            # 在日志后添加结束括号和赋值
            lines.insert(i + 2, ' ' * indent + '}\n')
            lines.insert(i + 3, ' ' * indent + '\n')
            lines.insert(i + 4, ' ' * indent + 'dateText = parsedDate || dateText;\n')
        
        # 在 parseChineseDate 调用之前插入代码
        lines[i:i] = insert_code
        break

# 清理重复的日志（删除重复的 "准备解析日期" 和 "解析后的日期"）
new_lines = []
skip_next = False
for i, line in enumerate(lines):
    if skip_next:
        skip_next = False
        continue
    if '准备解析日期' in line and i + 1 < len(lines) and '准备解析日期' in lines[i + 1]:
        # 跳过重复的
        continue
    if '解析后的日期' in line and i + 1 < len(lines) and '解析后的日期' in lines[i + 1]:
        # 跳过重复的
        continue
    new_lines.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("✅ 修复完成")
PYTHON_EOF

# 验证修复
echo "修复后的代码："
sed -n '355,390p' feishu-puppeteer.ts


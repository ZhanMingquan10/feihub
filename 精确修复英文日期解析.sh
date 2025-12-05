#!/bin/bash

cd /www/wwwroot/feihub/backend/src/lib

# 备份
cp feishu-puppeteer.ts feishu-puppeteer.ts.backup7

# 使用 Python 脚本精确修复
python3 << 'PYTHON_EOF'
file_path = '/www/wwwroot/feihub/backend/src/lib/feishu-puppeteer.ts'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 找到第363行（"准备解析日期"）的位置
for i in range(len(lines)):
    if i == 362 and '准备解析日期' in lines[i]:  # 第363行（0-based index 362）
        indent = len(lines[i]) - len(lines[i].lstrip())
        
        # 删除重复的日志行（第364行和第368行）
        if i + 1 < len(lines) and '准备解析日期' in lines[i + 1]:
            lines.pop(i + 1)  # 删除重复的 "准备解析日期"
        
        # 找到 parseChineseDate 调用（应该在 i+2 或 i+1 位置）
        parse_idx = i + 1
        while parse_idx < len(lines) and 'parseChineseDate' not in lines[parse_idx]:
            parse_idx += 1
        
        if parse_idx < len(lines):
            # 删除重复的 "解析后的日期" 日志
            if parse_idx + 1 < len(lines) and '解析后的日期' in lines[parse_idx + 1]:
                if parse_idx + 2 < len(lines) and '解析后的日期' in lines[parse_idx + 2]:
                    lines.pop(parse_idx + 2)  # 删除重复的 "解析后的日期"
        
        # 在 "准备解析日期" 之后插入英文日期解析代码
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
        ]
        
        # 在 "准备解析日期" 之后插入代码
        lines[i+1:i+1] = insert_code
        
        # 重新找到 parseChineseDate 的位置（因为插入了代码，位置会变化）
        parse_idx = i + 1 + len(insert_code)
        while parse_idx < len(lines) and 'parseChineseDate' not in lines[parse_idx]:
            parse_idx += 1
        
        if parse_idx < len(lines):
            # 修改 parseChineseDate 调用，添加缩进
            lines[parse_idx] = ' ' * (indent + 2) + lines[parse_idx].lstrip()
            
            # 查找 "解析后的日期" 日志
            if parse_idx + 1 < len(lines) and '解析后的日期' in lines[parse_idx + 1]:
                # 删除重复的日志
                if parse_idx + 2 < len(lines) and '解析后的日期' in lines[parse_idx + 2]:
                    lines.pop(parse_idx + 2)
                
                # 修改日志，添加缩进
                lines[parse_idx + 1] = ' ' * (indent + 2) + lines[parse_idx + 1].lstrip()
                
                # 在日志后添加结束括号和赋值
                lines.insert(parse_idx + 2, ' ' * indent + '} else {\n')
                lines.insert(parse_idx + 3, ' ' * indent + '  dateText = parsedDate;\n')
                lines.insert(parse_idx + 4, ' ' * indent + '}\n')
        
        break

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYTHON_EOF

# 验证修复
echo "修复后的代码："
sed -n '360,395p' feishu-puppeteer.ts


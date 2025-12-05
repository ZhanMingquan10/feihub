# 修复 parseChineseDate 函数

## 🔧 在服务器上执行

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend/src/lib

# 备份
cp feishu-puppeteer.ts feishu-puppeteer.ts.backup13

# 修复 parseChineseDate 函数
python3 << 'PYTHON_EOF'
file_path = '/www/wwwroot/feihub/backend/src/lib/feishu-puppeteer.ts'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 替换整个 parseChineseDate 函数
old_function = r'function parseChineseDate\(dateStr: string\): string \{[^}]+\}[^}]+\}[^}]+\}'

new_function = '''function parseChineseDate(dateStr: string): string {
  try {
    // 如果已经是 ISO 格式，直接返回
    if (/^\\d{4}-\\d{2}-\\d{2}$/.test(dateStr)) {
      return dateStr;
    }
    
    // 匹配带年份的格式：YYYY年X月X日
    const matchWithYear = dateStr.match(/(\\d{4})年(\\d{1,2})月(\\d{1,2})日/);
    if (matchWithYear) {
      const year = parseInt(matchWithYear[1], 10);
      const month = parseInt(matchWithYear[2], 10);
      const day = parseInt(matchWithYear[3], 10);
      
      return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
    }
    
    // 匹配不带年份的格式：X月X日、X月XX日、XX月X日、XX月XX日
    const match = dateStr.match(/(\\d{1,2})月(\\d{1,2})日/);
    if (match) {
      const month = parseInt(match[1], 10);
      const day = parseInt(match[2], 10);
      const now = new Date();
      const currentYear = now.getFullYear();
      
      // 对于只有月份和日期的格式，默认使用当前年份
      // 因为飞书文档的修改时间不可能是未来的日期
      const year = currentYear;
      
      // 构建日期
      const date = new Date(year, month - 1, day);
      
      // 验证日期是否有效
      if (date.getMonth() === month - 1 && date.getDate() === day) {
        return date.toISOString().split("T")[0];
      }
    }
    
    // 如果无法解析，返回当前日期
    return new Date().toISOString().split("T")[0];
  } catch (e) {
    // 如果解析失败，返回当前日期
    return new Date().toISOString().split("T")[0];
  }
}'''

import re
content = re.sub(
    r'function parseChineseDate\(dateStr: string\): string \{[^}]*\{[^}]*\{[^}]*\}[^}]*\}[^}]*\}',
    new_function,
    content,
    flags=re.MULTILINE | re.DOTALL
)

# 如果上面的替换没成功，尝试更精确的替换
if 'function parseChineseDate(dateStr: string): string {' in content and '匹配带年份的格式' not in content:
    # 找到函数开始和结束位置
    start = content.find('function parseChineseDate(dateStr: string): string {')
    if start != -1:
        # 找到函数结束位置（匹配大括号）
        brace_count = 0
        end = start
        for i in range(start, len(content)):
            if content[i] == '{':
                brace_count += 1
            elif content[i] == '}':
                brace_count -= 1
                if brace_count == 0:
                    end = i + 1
                    break
        
        # 替换函数
        content = content[:start] + new_function + content[end:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ parseChineseDate 函数已修复")
PYTHON_EOF

# 验证修复
echo "修复后的函数："
sed -n '760,800p' feishu-puppeteer.ts
```

---

## ✅ 然后重新构建

```bash
cd /www/wwwroot/feihub/backend

npm run build

if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    pm2 restart feihub-backend
else
    echo "❌ 构建失败"
    npm run build 2>&1 | tail -30
fi
```


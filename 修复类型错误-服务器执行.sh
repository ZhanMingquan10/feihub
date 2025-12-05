#!/bin/bash

# 修复类型错误 - page.evaluate 返回 null 的问题

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 查看第414行附近的代码 ==="
sed -n '410,420p' feishu-puppeteer.ts

echo ""
echo "=== 修复类型错误 ==="

python3 << 'PYEOF'
file_path = 'feishu-puppeteer.ts'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 修复1: 查找 content = await page.evaluate 的赋值
# 在赋值后添加 null 检查
pattern1 = r'(content\s*=\s*await\s+page\.evaluate\([^)]+\);)'

def add_null_check(match):
    return match.group(1) + '''
      // 处理 null 返回值
      if (!content) {
        content = '';
      }'''

content = re.sub(pattern1, add_null_check, content)

# 修复2: 或者更简单，在赋值时使用 || '' 来处理 null
pattern2 = r'(content\s*=\s*await\s+page\.evaluate\([^)]+\);)'

def use_default(match):
    return match.group(1).replace('page.evaluate(', '(await page.evaluate(') + ' || \'\';'

# 更简单的方法：直接查找并修复
lines = content.split('\n')
fixed_lines = []
for i, line in enumerate(lines):
    if 'content = await page.evaluate' in line and i >= 410 and i <= 420:
        # 在这行后面添加 null 检查
        fixed_lines.append(line)
        # 查找下一个非空行，在它之前插入检查
        j = i + 1
        while j < len(lines) and (not lines[j].strip() or lines[j].strip().startswith('//')):
            j += 1
        # 在下一个有效代码行前插入 null 检查
        if j < len(lines):
            fixed_lines.append('      // 处理 null 返回值')
            fixed_lines.append('      if (!content) content = \'\';')
        else:
            fixed_lines.append('      if (!content) content = \'\';')
    else:
        fixed_lines.append(line)

content = '\n'.join(fixed_lines)

if content != original:
    with open(file_path + '.bak3', 'w', encoding='utf-8') as f:
        f.write(original)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ 已修复类型错误")
else:
    print("⚠️  未找到需要修复的代码")
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


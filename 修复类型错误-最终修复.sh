#!/bin/bash

# 修复类型错误 - 最终修复

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：确认文件位置 ==="
pwd
ls -la feishu-puppeteer.ts

echo ""
echo "=== 第二步：查找闭合括号 ==="
grep -n "});" feishu-puppeteer.ts | head -10

echo ""
echo "=== 第三步：查看第414行附近的代码 ==="
sed -n '414,450p' feishu-puppeteer.ts

echo ""
echo "=== 第四步：修复类型错误 ==="

python3 << 'PYEOF'
import os

# 切换到正确的目录
os.chdir('/www/wwwroot/feihub/backend/src/lib')

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找 content = await page.evaluate 的行
evaluate_line = None
for i, line in enumerate(lines):
    if 'content = await page.evaluate' in line and i >= 410 and i <= 420:
        evaluate_line = i
        print(f"找到 page.evaluate 在第 {i+1} 行")
        break

if evaluate_line is None:
    print("❌ 未找到 content = await page.evaluate")
    exit(1)

# 查找闭合括号 });
closing_line = None
for i in range(evaluate_line + 1, min(evaluate_line + 200, len(lines))):
    if '});' in lines[i]:
        closing_line = i
        print(f"找到闭合括号在第 {i+1} 行")
        print(f"  内容: {lines[i].strip()}")
        break

if closing_line is None:
    print("❌ 未找到闭合括号 });")
    exit(1)

# 修复：在 }); 后添加 || ''
original_line = lines[closing_line]
if '}) ||' not in original_line and '}) ||' not in original_line:
    lines[closing_line] = original_line.replace('});', '}) || \'\';')
    print(f"✅ 已修复第 {closing_line + 1} 行")
    print(f"  原: {original_line.strip()}")
    print(f"  新: {lines[closing_line].strip()}")
else:
    print(f"⚠️  第 {closing_line + 1} 行已经包含 || ''")

# 删除错误插入的代码（在 page.evaluate 内部的 if (!content)）
to_remove = []
for i in range(evaluate_line + 1, closing_line):
    if 'if (!content) content' in lines[i]:
        to_remove.append(i)
        print(f"标记删除第 {i+1} 行: {lines[i].strip()}")

for i in reversed(to_remove):
    del lines[i]
    print(f"✅ 已删除第 {i+1} 行")

# 保存
with open('feishu-puppeteer.ts.bak8', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

echo ""
echo "=== 第五步：验证修复 ==="
sed -n '414,450p' feishu-puppeteer.ts | grep -E "content =|});"

echo ""
echo "=== 第六步：重新构建 ==="
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


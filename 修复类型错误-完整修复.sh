#!/bin/bash

# 修复类型错误 - 完整修复

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：查找闭合括号位置 ==="
grep -n "});" feishu-puppeteer.ts | head -10

echo ""
echo "=== 第二步：完整修复 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. 修复第414行：添加类型断言
for i, line in enumerate(lines):
    if i == 413 and 'content = await page.evaluate' in line:  # 第414行
        lines[i] = line.replace('content = await page.evaluate', 'content = (await page.evaluate as any)')
        print(f"✅ 修复第 {i+1} 行：添加类型断言")

# 2. 删除第416-417行的错误代码
to_remove = []
for i, line in enumerate(lines):
    if i >= 415 and i <= 418 and 'if (!content) content' in line:
        to_remove.append(i)
        print(f"标记删除第 {i+1} 行: {line.strip()}")

# 从后往前删除
for i in reversed(to_remove):
    del lines[i]
    print(f"✅ 已删除第 {i+1} 行")

# 保存
with open('feishu-puppeteer.ts.bak10', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

echo ""
echo "=== 第三步：验证修复 ==="
sed -n '414,420p' feishu-puppeteer.ts

echo ""
echo "=== 第四步：重新构建 ==="
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


#!/bin/bash

# 修复类型错误 - 删除错误插入的代码并正确修复

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：删除错误插入的代码 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找并删除在 page.evaluate 函数内部的错误代码
# 第416-417行的 if (!content) content = ''; 应该删除
to_remove = []
for i, line in enumerate(lines):
    # 检查是否在 page.evaluate 函数内部
    if i >= 410 and i <= 450:
        # 检查这行是否在 content = await page.evaluate 之后
        # 并且在这行的前面有 page.evaluate
        has_evaluate_start = False
        for j in range(max(0, i-10), i):
            if 'content = await page.evaluate' in lines[j]:
                has_evaluate_start = True
                break
        
        # 检查这行是否在闭合括号之前
        has_closing = False
        for j in range(i, min(i+50, len(lines))):
            if '});' in lines[j]:
                has_closing = True
                break
        
        # 如果在这两个之间，且是 if (!content) content = '';，则删除
        if has_evaluate_start and has_closing and 'if (!content) content' in line:
            to_remove.append(i)
            print(f"标记删除第 {i+1} 行: {line.strip()}")

# 从后往前删除，避免索引变化
for i in reversed(to_remove):
    del lines[i]
    print(f"✅ 已删除第 {i+1} 行")

# 保存
with open('feishu-puppeteer.ts.bak6', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 已删除错误代码")
PYEOF

echo ""
echo "=== 第二步：在正确位置添加 null 检查 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找 page.evaluate 的闭合括号 });
for i, line in enumerate(lines):
    if '});' in line and i >= 410:
        # 检查前面是否有 content = await page.evaluate
        has_evaluate = False
        for j in range(max(0, i-50), i):
            if 'content = await page.evaluate' in lines[j]:
                has_evaluate = True
                break
        
        if has_evaluate:
            # 在 }); 后添加 || ''
            lines[i] = line.replace('});', '}) || \'\';')
            print(f"✅ 修复第 {i+1} 行: 在 }); 后添加 || ''")
            break

with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)
PYEOF

echo ""
echo "=== 验证修复 ==="
sed -n '410,425p' feishu-puppeteer.ts

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


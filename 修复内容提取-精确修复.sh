#!/bin/bash

# 修复内容提取 - 精确修复第405行

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：查看第405行附近的代码 ==="
sed -n '395,415p' feishu-puppeteer.ts

echo ""
echo "=== 第二步：修复内容提取逻辑 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找第405行的 return text.trim()
for i, line in enumerate(lines):
    if i == 404 and 'return text.trim()' in line:  # 第405行（索引404）
        # 查看上下文，确认在循环内
        context = '\n'.join(lines[max(0, i-10):i+1])
        if 'for (const selector' in context or 'for (let i = 0' in context:
            # 在这行前添加验证
            indent = len(line) - len(line.lstrip())
            indent_str = ' ' * indent
            
            # 插入验证代码
            lines.insert(i, f"{indent_str}// 验证内容：排除导航栏和帮助中心\n")
            lines.insert(i+1, f"{indent_str}if (text && (\n")
            lines.insert(i+2, f"{indent_str}  text.includes('Help Center') ||\n")
            lines.insert(i+3, f"{indent_str}  text.includes('Keyboard Shortcuts') ||\n")
            lines.insert(i+4, f"{indent_str}  text.includes('Token Limit') ||\n")
            lines.insert(i+5, f"{indent_str}  text.trim().split(/\\s+/).length < 10 ||\n")
            lines.insert(i+6, f"{indent_str}  (!/[\\u4e00-\\u9fa5]/.test(text) && text.length < 200)\n")
            lines.insert(i+7, f"{indent_str})) {{\n")
            lines.insert(i+8, f"{indent_str}  continue; // 跳过无效内容\n")
            lines.insert(i+9, f"{indent_str}}}\n")
            
            print(f"✅ 在第 {i+1} 行前添加验证")
            print(f"  原行: {line.strip()}")
            break

with open('feishu-puppeteer.ts.bak12', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

echo ""
echo "=== 第三步：验证修复 ==="
sed -n '395,420p' feishu-puppeteer.ts

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


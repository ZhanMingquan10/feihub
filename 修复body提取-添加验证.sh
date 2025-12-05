#!/bin/bash

# 修复 body 提取 - 添加验证

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 查看 body 提取的完整代码 ==="
sed -n '450,520p' feishu-puppeteer.ts

echo ""
echo "=== 修复：在 body 提取后添加验证 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找 body 提取的 return bodyText.trim()
for i, line in enumerate(lines):
    if 'return bodyText.trim();' in line and i > 450:
        # 在这行前添加验证
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        
        # 检查是否已有验证
        has_validation = False
        for j in range(max(0, i-20), i):
            if 'Help Center' in lines[j] and 'bodyText' in lines[j]:
                has_validation = True
                break
        
        if not has_validation:
            # 在 return 前添加验证
            lines.insert(i, f"{indent_str}\n")
            lines.insert(i+1, f"{indent_str}// 验证 bodyText：排除导航栏\n")
            lines.insert(i+2, f"{indent_str}if (bodyText && (\n")
            lines.insert(i+3, f"{indent_str}  bodyText.includes('Help Center') ||\n")
            lines.insert(i+4, f"{indent_str}  bodyText.includes('Keyboard Shortcuts') ||\n")
            lines.insert(i+5, f"{indent_str}  bodyText.includes('Token Limit') ||\n")
            lines.insert(i+6, f"{indent_str}  bodyText.trim().split(/\\s+/).length < 10 ||\n")
            lines.insert(i+7, f"{indent_str}  (!/[\\u4e00-\\u9fa5]/.test(bodyText) && bodyText.length < 200)\n")
            lines.insert(i+8, f"{indent_str})) {{\n")
            lines.insert(i+9, f"{indent_str}  return ''; // 返回空字符串，避免返回导航栏内容\n")
            lines.insert(i+10, f"{indent_str}}}\n")
            print(f"✅ 在第 {i+1} 行前添加 bodyText 验证")
            break

with open('feishu-puppeteer.ts.bak19', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

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


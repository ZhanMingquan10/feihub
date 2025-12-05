#!/bin/bash

# 修复内容提取 - 改进验证逻辑

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：查看完整的提取逻辑 ==="
sed -n '355,420p' feishu-puppeteer.ts

echo ""
echo "=== 第二步：改进验证逻辑 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 问题分析：
# 验证在 if (text.length > 200) 之后
# 但如果 text.length <= 200，就不会进入验证
# 需要把验证提前，在任何返回前都验证

# 查找 let text = clone.innerText 的位置
text_extract_line = None
for i, line in enumerate(lines):
    if 'let text = clone.innerText' in line or 'let text = clone.textContent' in line:
        text_extract_line = i
        print(f"找到文本提取在第 {i+1} 行")
        break

# 在 text.trim() 后立即添加验证（在 if (text.length > 200) 之前）
for i, line in enumerate(lines):
    if 'text = text.trim();' in line and i > 350 and i < 400:
        # 在这行后添加早期验证
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        
        # 检查是否已经有验证
        has_early_validation = False
        for j in range(i+1, min(i+20, len(lines))):
            if 'Help Center' in lines[j] and 'includes' in lines[j]:
                has_early_validation = True
                break
        
        if not has_early_validation:
            # 在 text.trim() 后立即添加验证
            lines.insert(i+1, f"{indent_str}\n")
            lines.insert(i+2, f"{indent_str}// 早期验证：排除导航栏内容\n")
            lines.insert(i+3, f"{indent_str}if (text && (text.includes('Help Center') || text.includes('Keyboard Shortcuts') || text.includes('Token Limit'))) {{\n")
            lines.insert(i+4, f"{indent_str}  continue; // 跳过导航栏内容\n")
            lines.insert(i+5, f"{indent_str}}}\n")
            print(f"✅ 在第 {i+1} 行后添加早期验证")
            break

# 同时改进现有的验证（在 if (text.length > 200) 内）
# 确保验证更严格
for i, line in enumerate(lines):
    if '验证内容：排除导航栏和帮助中心' in line:
        # 查看验证逻辑，确保足够严格
        # 检查下一行的验证条件
        if i+1 < len(lines) and 'text.includes' in lines[i+1]:
            # 验证逻辑看起来是对的，但可能需要更早执行
            pass
        break

with open('feishu-puppeteer.ts.bak14', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

echo ""
echo "=== 第三步：验证修复 ==="
sed -n '355,380p' feishu-puppeteer.ts

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


#!/bin/bash

# 检查并修复内容提取 - 详细诊断

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：检查修复是否生效 ==="
echo "查看第405行附近的代码："
sed -n '395,425p' feishu-puppeteer.ts

echo ""
echo "=== 第二步：查找所有 return text.trim() ==="
grep -n "return text.trim()" feishu-puppeteer.ts

echo ""
echo "=== 第三步：查看 page.evaluate 的完整结构 ==="
echo "查找 page.evaluate 的开始和结束："
grep -n "content = await page.evaluate\|});" feishu-puppeteer.ts | head -5

echo ""
echo "=== 第四步：查看内容提取的循环结构 ==="
sed -n '350,410p' feishu-puppeteer.ts

echo ""
echo "=== 第五步：修复内容提取逻辑 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找所有 return text.trim() 的位置
return_lines = []
for i, line in enumerate(lines):
    if 'return text.trim()' in line:
        return_lines.append(i)
        print(f"找到 return text.trim() 在第 {i+1} 行")

# 查找在 page.evaluate 函数内的 return text.trim()
# 查找 content = await page.evaluate 的位置
evaluate_start = None
evaluate_end = None
for i, line in enumerate(lines):
    if 'content = await page.evaluate' in line:
        evaluate_start = i
        print(f"找到 page.evaluate 开始在第 {i+1} 行")
    if evaluate_start and '});' in line and i > evaluate_start:
        evaluate_end = i
        print(f"找到 page.evaluate 结束在第 {i+1} 行")
        break

# 在 evaluate 函数内查找 return text.trim()
for return_line in return_lines:
    if evaluate_start and evaluate_end and evaluate_start < return_line < evaluate_end:
        # 检查是否已经有验证代码
        has_validation = False
        for j in range(max(0, return_line-10), return_line):
            if 'Help Center' in lines[j] or 'Keyboard Shortcuts' in lines[j]:
                has_validation = True
                break
        
        if not has_validation:
            # 在这行前添加验证
            indent = len(lines[return_line]) - len(lines[return_line].lstrip())
            indent_str = ' ' * indent
            
            # 插入验证代码
            lines.insert(return_line, f"{indent_str}// 验证内容：排除导航栏\n")
            lines.insert(return_line+1, f"{indent_str}if (text && (text.includes('Help Center') || text.includes('Keyboard Shortcuts') || text.includes('Token Limit') || text.trim().split(/\\s+/).length < 10 || (!/[\\u4e00-\\u9fa5]/.test(text) && text.length < 200))) {{\n")
            lines.insert(return_line+2, f"{indent_str}  continue;\n")
            lines.insert(return_line+3, f"{indent_str}}}\n")
            
            print(f"✅ 在第 {return_line+1} 行前添加验证")
            break

with open('feishu-puppeteer.ts.bak13', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

echo ""
echo "=== 第六步：验证修复 ==="
sed -n '395,425p' feishu-puppeteer.ts

echo ""
echo "=== 第七步：重新构建 ==="
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


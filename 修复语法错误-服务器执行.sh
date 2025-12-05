#!/bin/bash

# 修复语法错误 - continue 不能在函数边界外使用

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 修复语法错误 ==="

python3 << 'PYEOF'
import re

file_path = 'feishu-puppeteer.ts'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 修复1: 将 continue 改为 return '' 或 return null（如果在函数内但不是循环）
# 查找错误的 continue 语句
pattern1 = r'(if\s*\([^)]+\)\s*continue;)'

def fix_continue(match):
    # 检查上下文，如果在循环外，改为 return
    return match.group(1).replace('continue;', 'return null;')

content = re.sub(pattern1, fix_continue, content)

# 修复2: 更精确地修复 - 在 page.evaluate 函数内的 continue 应该改为 return null
# 查找在 evaluate 函数内的 continue
pattern2 = r'(if\s*\([^)]*bodyText[^)]*\)\s*\{[^}]*continue;[^}]*\})'

def fix_in_evaluate(match):
    # 在 evaluate 函数内，continue 应该改为 return null
    return match.group(1).replace('continue;', 'return null;')

content = re.sub(pattern2, fix_in_evaluate, content)

# 修复3: 直接查找并替换错误的 continue
# 查找包含 bodyText 检查的 continue
lines = content.split('\n')
fixed_lines = []
for i, line in enumerate(lines):
    if 'continue;' in line and ('bodyText' in line or 'text' in line) and 'for' not in lines[max(0, i-5):i]:
        # 如果前面几行没有 for 循环，说明不在循环内
        # 检查是否在函数内（page.evaluate）
        in_evaluate = False
        for j in range(max(0, i-20), i):
            if 'page.evaluate' in lines[j] or 'await page.evaluate' in lines[j]:
                in_evaluate = True
                break
        
        if in_evaluate:
            # 在 evaluate 函数内，改为 return null
            line = line.replace('continue;', 'return null;')
            print(f"  修复第 {i+1} 行: continue -> return null")
        else:
            # 不在 evaluate 内，可能是其他情况，改为 return ''
            line = line.replace('continue;', "return '';")
            print(f"  修复第 {i+1} 行: continue -> return ''")
    fixed_lines.append(line)

content = '\n'.join(fixed_lines)

if content != original:
    # 备份
    with open(file_path + '.bak2', 'w', encoding='utf-8') as f:
        f.write(original)
    
    # 保存
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ 已修复语法错误")
else:
    print("⚠️  未找到需要修复的代码")
PYEOF

echo ""
echo "=== 验证修复 ==="
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
    echo "可以恢复备份："
    echo "  cd /www/wwwroot/feihub/backend/src/lib"
    echo "  cp feishu-puppeteer.ts.bak2 feishu-puppeteer.ts"
fi


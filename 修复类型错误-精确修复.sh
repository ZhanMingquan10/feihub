#!/bin/bash

# 精确修复 TypeScript 类型错误

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 查看问题代码 ==="
sed -n '110,145p' feishu-puppeteer.ts

echo ""
echo "=== 修复类型错误 ==="

python3 << 'PYEOF'
import re

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找并修复每一处错误
for i, line in enumerate(lines):
    # 修复 1: 第115行 - 为 info 添加类型定义
    if 'const info = { scrollContainers: []' in line:
        # 找到完整的 info 定义
        lines[i] = line.replace(
            'const info = { scrollContainers: []',
            'const info: { scrollContainers: Array<{ tagName: string; className: string; id: string; scrollHeight: number; clientHeight: number }> } = { scrollContainers: []'
        )
        print(f"✅ 修复第 {i+1} 行: 添加类型定义")
    
    # 修复 2: 第121行 - reduce 添加初始值
    if 'const mainContainer = scrollInfo.scrollContainers.reduce' in line:
        # 检查是否已经有初始值
        if ', scrollInfo.scrollContainers[0]' not in line:
            lines[i] = '      const mainContainer = scrollInfo.scrollContainers.length > 0 ? scrollInfo.scrollContainers.reduce((max, current) => current.scrollHeight > max.scrollHeight ? current : max, scrollInfo.scrollContainers[0]) : null;\n'
            print(f"✅ 修复第 {i+1} 行: reduce 添加初始值")
    
    # 修复 3: 第122行 - 在 mainContainer 使用前添加检查
    if 'console.log(`[Puppeteer] 找到滚动容器: ${mainContainer.tagName}' in line:
        # 在这行前插入检查
        indent = len(line) - len(line.lstrip())
        check_line = ' ' * indent + 'if (!mainContainer) { console.log(\'[Puppeteer] 无法获取滚动容器\'); return; }\n'
        lines.insert(i, check_line)
        print(f"✅ 在第 {i+1} 行前添加 mainContainer 空值检查")
        break
    
    # 修复 4: 第127行 - for...of 循环
    if 'for (const el of elements)' in line and 'Array.from' not in line:
        lines[i] = line.replace(
            'for (const el of elements)',
            'for (const el of Array.from(elements))'
        )
        print(f"✅ 修复第 {i+1} 行: 转换 NodeListOf 为数组")
    
    # 修复 5: 第139行 - mainContainer 使用前添加检查
    if '}, { tagName: mainContainer.tagName' in line:
        # 在这行前插入检查
        indent = len(line) - len(line.lstrip())
        check_line = ' ' * indent + 'if (!mainContainer) return null;\n'
        lines.insert(i, check_line)
        print(f"✅ 在第 {i+1} 行前添加 mainContainer 空值检查")
        break

# 保存备份
with open('feishu-puppeteer.ts.bak_fix_types2', 'w', encoding='utf-8') as f:
    f.writelines(lines)

# 保存修改后的文件
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 类型错误已修复")
PYEOF

echo ""
echo "=== 验证修复 ==="
echo "检查第115行:"
sed -n '115p' feishu-puppeteer.ts
echo "检查第121行:"
sed -n '121p' feishu-puppeteer.ts
echo "检查第122行附近:"
sed -n '120,125p' feishu-puppeteer.ts

echo ""
echo "=== 重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build 2>&1 | head -40

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    pm2 restart feihub-backend
    echo "✅✅✅ 修复完成！"
else
    echo ""
    echo "❌ 构建失败，查看详细错误："
    npm run build 2>&1 | grep "error TS" | head -15
fi


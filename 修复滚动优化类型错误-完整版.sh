#!/bin/bash

# 修复滚动优化的 TypeScript 类型错误（完整版）

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 修复 TypeScript 类型错误 ==="

python3 << 'PYEOF'
import re

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找需要修复的行
for i, line in enumerate(lines):
    # 修复 1: 为 info 添加类型定义
    if 'const info = { scrollContainers: []' in line:
        lines[i] = line.replace(
            'const info = { scrollContainers: []',
            'const info: { scrollContainers: Array<{ tagName: string; className: string; id: string; scrollHeight: number; clientHeight: number }> } = { scrollContainers: []'
        )
        print(f"✅ 修复第 {i+1} 行: 添加类型定义")
    
    # 修复 2: reduce 添加初始值
    if 'const mainContainer = scrollInfo.scrollContainers.reduce' in line:
        # 需要检查下一行是否包含完整的 reduce
        full_line = line
        j = i + 1
        while j < len(lines) and ');' not in full_line:
            full_line += lines[j]
            j += 1
        
        if 'reduce((max, current)' in full_line:
            # 替换为带初始值的版本
            new_line = '      const mainContainer = scrollInfo.scrollContainers.length > 0 ? scrollInfo.scrollContainers.reduce((max, current) => current.scrollHeight > max.scrollHeight ? current : max, scrollInfo.scrollContainers[0]) : null;\n'
            lines[i] = new_line
            # 删除后续的 reduce 相关行（如果有）
            k = i + 1
            while k < len(lines) and k < i + 3:
                if ');' in lines[k]:
                    lines[k] = ''
                    break
                k += 1
            print(f"✅ 修复第 {i+1} 行: reduce 添加初始值")
    
    # 修复 3: for...of 循环转换为数组
    if 'for (const el of elements)' in line:
        lines[i] = line.replace(
            'for (const el of elements)',
            'for (const el of Array.from(elements))'
        )
        print(f"✅ 修复第 {i+1} 行: 转换 NodeListOf 为数组")
    
    # 修复 4: 添加 mainContainer 的空值检查
    if 'if (scrollInfo.scrollContainers.length > 0)' in line:
        # 在 mainContainer 使用前添加检查
        for j in range(i, min(i+10, len(lines))):
            if 'mainContainer.tagName' in lines[j] and 'if (mainContainer)' not in lines[j-1] and 'if (mainContainer)' not in lines[j-2]:
                # 在 mainContainer 使用前插入检查
                indent = len(lines[j]) - len(lines[j].lstrip())
                check_line = ' ' * indent + 'if (!mainContainer) return;\n'
                lines.insert(j, check_line)
                print(f"✅ 在第 {j+1} 行前添加 mainContainer 空值检查")
                break

# 保存备份
with open('feishu-puppeteer.ts.bak_fix_types', 'w', encoding='utf-8') as f:
    f.writelines(lines)

# 保存修改后的文件
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 类型错误已修复")
PYEOF

echo ""
echo "=== 验证修改 ==="
grep -A 2 "scrollContainers:" feishu-puppeteer.ts | head -5
grep -A 1 "mainContainer" feishu-puppeteer.ts | head -10

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
    echo "✅✅✅ 类型错误已修复并重启服务！"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
    echo "如果构建失败，可以恢复："
    echo "  cd /www/wwwroot/feihub/backend/src/lib"
    echo "  cp feishu-puppeteer.ts.bak_fix_types feishu-puppeteer.ts"
fi


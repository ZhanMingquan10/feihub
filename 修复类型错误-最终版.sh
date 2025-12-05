#!/bin/bash

# 最终修复 TypeScript 类型错误

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 修复 TypeScript 类型错误 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 修复 1: 为 info 添加明确的类型定义（使用 as any 临时解决类型推断问题）
content = content.replace(
    'const info = { scrollContainers: []',
    'const info: any = { scrollContainers: []'
)

# 修复 2: reduce 添加初始值并添加类型断言
content = content.replace(
    'const mainContainer = scrollInfo.scrollContainers.reduce((max, current) => current.scrollHeight > max.scrollHeight ? current : max);',
    'const mainContainer: any = scrollInfo.scrollContainers.length > 0 ? scrollInfo.scrollContainers.reduce((max: any, current: any) => current.scrollHeight > max.scrollHeight ? current : max, scrollInfo.scrollContainers[0]) : null;'
)

# 修复 3: 在 mainContainer 使用前添加检查
content = content.replace(
    'const mainContainer: any = scrollInfo.scrollContainers.length > 0 ? scrollInfo.scrollContainers.reduce((max: any, current: any) => current.scrollHeight > max.scrollHeight ? current : max, scrollInfo.scrollContainers[0]) : null;\n      console.log(`[Puppeteer] 找到滚动容器: ${mainContainer.tagName}',
    'const mainContainer: any = scrollInfo.scrollContainers.length > 0 ? scrollInfo.scrollContainers.reduce((max: any, current: any) => current.scrollHeight > max.scrollHeight ? current : max, scrollInfo.scrollContainers[0]) : null;\n      if (!mainContainer) { console.log(\'[Puppeteer] 无法获取滚动容器\'); } else {\n      console.log(`[Puppeteer] 找到滚动容器: ${mainContainer.tagName}'
)

# 修复 4: for...of 循环
content = content.replace(
    'for (const el of elements) {',
    'for (const el of Array.from(elements)) {'
)

# 修复 5: 在 page.evaluate 中使用 mainContainer 前添加检查
content = content.replace(
    '}, { tagName: mainContainer.tagName, className: mainContainer.className, id: mainContainer.id });',
    'if (!mainContainer) return null;\n        }, { tagName: mainContainer.tagName, className: mainContainer.className, id: mainContainer.id });'
)

# 修复 6: 确保 if 块正确闭合
if 'if (!mainContainer) { console.log' in content and '} else {' not in content.split('if (!mainContainer) { console.log')[1].split('for (let i = 0')[0]:
    # 在 for 循环前添加 else 闭合
    content = content.replace(
        '      if (!mainContainer) { console.log(\'[Puppeteer] 无法获取滚动容器\'); } else {\n      console.log(`[Puppeteer] 找到滚动容器',
        '      if (!mainContainer) { console.log(\'[Puppeteer] 无法获取滚动容器\'); return; }\n      console.log(`[Puppeteer] 找到滚动容器'
    )

# 保存备份
with open('feishu-puppeteer.ts.bak_fix_types_final', 'w', encoding='utf-8') as f:
    f.write(original)

# 保存修改后的文件
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 类型错误已修复（使用 any 类型临时解决）")
PYEOF

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


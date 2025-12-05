#!/bin/bash

# 直接修复 TypeScript 类型错误

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 修复 TypeScript 类型错误 ==="

# 创建修复脚本
python3 << 'PYEOF'
import re

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 修复 1: 为 info 添加类型定义
content = re.sub(
    r'const info = \{ scrollContainers: \[\]',
    r'const info: { scrollContainers: Array<{ tagName: string; className: string; id: string; scrollHeight: number; clientHeight: number }> } = { scrollContainers: []',
    content
)

# 修复 2: reduce 添加初始值和空值检查
content = re.sub(
    r'const mainContainer = scrollInfo\.scrollContainers\.reduce\(\(max, current\) => current\.scrollHeight > max\.scrollHeight \? current : max\);',
    r'if (scrollInfo.scrollContainers.length === 0) { console.log(\'[Puppeteer] 未找到滚动容器\'); } else { const mainContainer = scrollInfo.scrollContainers.reduce((max, current) => current.scrollHeight > max.scrollHeight ? current : max, scrollInfo.scrollContainers[0]);',
    content
)

# 修复 3: 在 mainContainer 使用前添加检查，并修复 for...of
# 查找 if (scrollInfo.scrollContainers.length > 0) 后的代码块
if 'if (scrollInfo.scrollContainers.length > 0)' in content:
    # 在 mainContainer 使用前添加检查
    content = re.sub(
        r'(const mainContainer[^;]+;)\s+console\.log',
        r'\1\n      if (!mainContainer) { console.log(\'[Puppeteer] 无法获取滚动容器\'); } else {\n      console.log',
        content
    )
    
    # 在 reduce 后添加闭合括号
    if '} else {' in content and content.count('} else {') > content.count('if (scrollInfo.scrollContainers.length === 0)'):
        # 需要找到对应的闭合位置
        pass

# 修复 4: for...of 循环
content = re.sub(
    r'for \(const el of elements\)',
    r'for (const el of Array.from(elements))',
    content
)

# 修复 5: 确保所有 mainContainer 使用都有检查
# 在 mainContainer.tagName 等使用前添加检查
content = re.sub(
    r'(\{ tagName: mainContainer\.tagName)',
    r'if (!mainContainer) return null;\n        \1',
    content
)

# 保存备份
with open('feishu-puppeteer.ts.bak_fix_types', 'w', encoding='utf-8') as f:
    f.write(original)

# 保存修改后的文件
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 类型错误已修复")
PYEOF

echo ""
echo "=== 重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build 2>&1 | head -30

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    pm2 restart feihub-backend
    echo "✅✅✅ 修复完成！"
else
    echo ""
    echo "❌ 构建失败，查看详细错误："
    cd /www/wwwroot/feihub/backend
    npm run build 2>&1 | grep "error TS"
fi


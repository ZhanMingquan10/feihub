#!/bin/bash

# 修复滚动优化的 TypeScript 类型错误

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 修复 TypeScript 类型错误 ==="

python3 << 'PYEOF'
import re

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 修复类型错误：为 scrollContainers 添加类型定义
# 查找 const info = { scrollContainers: [] };
pattern1 = r'(const info = \{ scrollContainers: \[\];)'
replacement1 = r'const info: { scrollContainers: Array<{ tagName: string; className: string; id: string; scrollHeight: number; clientHeight: number }> } = { scrollContainers: [];'

content = re.sub(pattern1, replacement1, content)

# 修复 reduce 的类型问题：添加初始值
pattern2 = r'(const mainContainer = scrollInfo\.scrollContainers\.reduce\(\(max, current\) => current\.scrollHeight > max\.scrollHeight \? current : max\);)'
replacement2 = r'const mainContainer = scrollInfo.scrollContainers.reduce((max, current) => current.scrollHeight > max.scrollHeight ? current : max, scrollInfo.scrollContainers[0]);'

content = re.sub(pattern2, replacement2, content)

# 修复 for...of 循环：将 NodeListOf 转换为数组
pattern3 = r'(for \(const el of elements\) \{)'
replacement3 = r'for (const el of Array.from(elements)) {'

content = re.sub(pattern3, replacement3, content)

# 保存备份
with open('feishu-puppeteer.ts.bak_fix_types', 'w', encoding='utf-8') as f:
    f.write(original)

# 保存修改后的文件
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 类型错误已修复")
PYEOF

echo ""
echo "=== 验证修改 ==="
grep -A 2 "scrollContainers:" feishu-puppeteer.ts | head -5

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


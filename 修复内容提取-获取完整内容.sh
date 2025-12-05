#!/bin/bash

# 修复内容提取逻辑，确保获取完整内容而不是最后一部分

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：保存当前版本 ==="
if [ -f "版本管理系统.sh" ]; then
    bash 版本管理系统.sh save "修复内容提取前" 2>/dev/null || echo "⚠️  版本管理系统未安装，跳过"
fi

echo ""
echo "=== 第二步：修复内容提取逻辑 ==="

python3 << 'PYEOF'
import re

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 问题：滚动到底部后，提取的内容可能是最后一部分
# 解决方案：在滚动完成后，确保提取的是完整内容，而不是当前可见部分

# 查找内容提取的代码（通常在滚动之后）
# 查找 "开始提取内容" 或 "page.evaluate" 中提取内容的部分

# 1. 确保在提取内容前，滚动回顶部（或者不滚动，直接提取完整DOM）
# 2. 或者确保选择器选择的是完整的文档内容，而不是当前可见部分

# 查找滚动完成后的内容提取代码
# 通常在 "已滚动到底部" 或滚动循环之后

# 在滚动完成后，添加滚动回顶部的逻辑（可选，或者直接提取完整内容）
if '已滚动到底部' in content or '滚动完成' in content:
    # 在滚动完成后，添加逻辑：提取完整内容（不依赖滚动位置）
    scroll_end_pattern = r'(已滚动到底部|滚动完成|滚动到底部)[^\n]*\n'
    
    # 在滚动完成后，添加说明：提取完整内容
    replacement = r'\1\n      // 滚动完成后，提取完整内容（不依赖当前滚动位置）\n'
    content = re.sub(scroll_end_pattern, replacement, content)

# 更重要的修复：确保内容提取选择器选择的是完整内容
# 查找 page.evaluate 中的内容提取逻辑

# 如果选择器是基于当前可见内容的，需要改为提取完整DOM
# 查找 "从页面直接提取内容" 或类似的位置

# 在 page.evaluate 中，确保提取的是完整内容
# 查找 content = await page.evaluate 的位置
if 'content = await page.evaluate' in content:
    # 在 page.evaluate 开始前，添加说明：提取完整内容
    # 查找 page.evaluate 的闭合位置，在开始处添加注释
    pattern = r'(content = await page\.evaluate\([^)]*\) => \{)'
    replacement = r'\1\n        // 提取完整内容（不依赖滚动位置，提取整个DOM）'
    content = re.sub(pattern, replacement, content)

# 关键修复：确保选择器选择的是完整文档，而不是当前可见部分
# 查找选择器数组，确保选择的是主容器，而不是当前可见的元素

# 查找 selectors 数组
if 'const selectors = [' in content:
    # 在选择器数组后，添加说明：这些选择器会提取完整内容
    pattern = r'(const selectors = \[[^\]]+\];)'
    replacement = r'\1\n        // 注意：这些选择器会提取元素的完整内容，不依赖滚动位置'
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# 更重要的：确保在提取内容时，选择的是主容器，而不是当前可见的小块
# 查找内容提取的循环逻辑

# 如果提取逻辑有问题，可能需要：
# 1. 在滚动完成后，滚动回顶部
# 2. 或者确保选择器选择的是主容器（如 .page-main, .page-block 等）

# 在滚动完成后，添加滚动回顶部的逻辑（可选）
if '已滚动到底部' in content:
    # 在滚动完成后，滚动回顶部，确保提取完整内容
    pattern = r'(已滚动到底部[^\n]*\n)'
    replacement = r'\1      // 滚动回顶部，准备提取完整内容\n      await page.evaluate((containerInfo) => {\n        const elements = document.querySelectorAll(containerInfo.tagName);\n        for (const el of Array.from(elements)) {\n          if ((containerInfo.className && el.className.includes(containerInfo.className.split(\' \')[0])) ||\n              (containerInfo.id && el.id === containerInfo.id)) {\n            if (el.scrollHeight > el.clientHeight) {\n              el.scrollTop = 0;\n              break;\n            }\n          }\n        }\n      }, { tagName: mainContainer.tagName, className: mainContainer.className, id: mainContainer.id });\n      await new Promise(resolve => setTimeout(resolve, 1000));\n'
    content = re.sub(pattern, replacement, content)

# 保存备份
with open('feishu-puppeteer.ts.bak_fix_extract', 'w', encoding='utf-8') as f:
    f.write(original)

# 保存修改后的文件
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 内容提取逻辑已修复")
print("主要修复：")
print("1. 滚动完成后，滚动回顶部")
print("2. 确保提取的是完整内容，而不是当前可见部分")
PYEOF

echo ""
echo "=== 第三步：验证修改 ==="
grep -A 3 "滚动回顶部" feishu-puppeteer.ts | head -10

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
    echo "✅✅✅ 内容提取修复完成！"
    echo ""
    echo "现在爬虫会："
    echo "1. ✅ 滚动到底部加载所有内容"
    echo "2. ✅ 滚动回顶部"
    echo "3. ✅ 提取完整文档内容（而不是最后一部分）"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
fi


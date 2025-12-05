#!/bin/bash

# 修复内容提取：滚动回顶部，确保提取完整内容

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 修复内容提取逻辑 ==="

python3 << 'PYEOF'
import re

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 在滚动完成后，滚动回顶部，确保提取完整内容
# 查找 "已滚动到底部" 的位置
if '已滚动到底部' in content:
    # 在 "已滚动到底部" 后，添加滚动回顶部的逻辑
    pattern = r'(已滚动到底部[^\n]*\n)'
    replacement = r'''\1      // 滚动回顶部，准备提取完整内容
      if (mainContainer) {
        await page.evaluate((containerInfo) => {
          const elements = document.querySelectorAll(containerInfo.tagName);
          for (const el of Array.from(elements)) {
            if ((containerInfo.className && el.className.includes(containerInfo.className.split(' ')[0])) ||
                (containerInfo.id && el.id === containerInfo.id)) {
              if (el.scrollHeight > el.clientHeight) {
                el.scrollTop = 0; // 滚动回顶部
                break;
              }
            }
          }
        }, { tagName: mainContainer.tagName, className: mainContainer.className, id: mainContainer.id });
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
'''
    content = re.sub(pattern, replacement, content)
    print("✅ 添加滚动回顶部逻辑")
else:
    print("⚠️  未找到 '已滚动到底部'，可能需要手动添加")

# 保存备份
with open('feishu-puppeteer.ts.bak_fix_extract', 'w', encoding='utf-8') as f:
    f.write(original)

# 保存修改后的文件
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 内容提取逻辑已修复")
PYEOF

echo ""
echo "=== 重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    pm2 restart feihub-backend
    echo "✅✅✅ 修复完成！"
    echo ""
    echo "现在爬虫会："
    echo "1. 滚动到底部加载所有内容"
    echo "2. 滚动回顶部"
    echo "3. 提取完整文档内容"
else
    echo ""
    echo "❌ 构建失败"
fi


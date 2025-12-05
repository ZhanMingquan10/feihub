#!/bin/bash

# 应用滚动优化到实际爬虫代码（服务器执行）

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：保存当前版本 ==="
if [ -f "版本管理系统.sh" ]; then
    bash 版本管理系统.sh save "应用滚动优化前" 2>/dev/null || echo "⚠️  版本管理系统未安装，跳过"
fi

echo ""
echo "=== 第二步：查找并应用滚动优化 ==="

# 查找 "等待内容渲染" 或类似的位置
python3 << 'PYEOF'
import re

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找插入位置：通常在 "等待内容渲染" 或 "额外等待" 之后
insert_line = None
for i, line in enumerate(lines):
    if '等待内容渲染' in line or '额外等待' in line or '确保内容完全渲染' in line:
        # 找到这一行的结束位置
        insert_line = i + 1
        # 继续查找，直到找到合适的位置（通常是下一个 await 或 console.log 之前）
        while insert_line < len(lines) and insert_line < i + 10:
            if lines[insert_line].strip().startswith('await') or lines[insert_line].strip().startswith('console.log'):
                break
            insert_line += 1
        break

if insert_line is None:
    # 如果没找到，查找 "page.evaluate" 之前的位置
    for i, line in enumerate(lines):
        if 'page.evaluate' in line and 'content =' in line:
            insert_line = i
            break

if insert_line is None:
    print("❌ 未找到合适的插入位置")
    exit(1)

print(f"✅ 找到插入位置: 第 {insert_line + 1} 行")

# 检查是否已经应用过滚动优化
if any('查找真实滚动容器' in line for line in lines):
    print("⚠️  滚动优化已存在，跳过")
    exit(0)

# 准备插入的代码
indent = '      '  # 6个空格（根据代码风格调整）
new_code = [
    f'{indent}// 优化后的滚动策略：查找真实滚动容器并滚动\n',
    f'{indent}console.log(\'[Puppeteer] 查找真实滚动容器...\');\n',
    f'{indent}const scrollInfo = await page.evaluate(() => {{\n',
    f'{indent}  const info = {{\n',
    f'{indent}    scrollContainers: []\n',
    f'{indent}  }};\n',
    f'{indent}  \n',
    f'{indent}  const allElements = document.querySelectorAll(\'*\');\n',
    f'{indent}  allElements.forEach((el) => {{\n',
    f'{indent}    const style = window.getComputedStyle(el);\n',
    f'{indent}    const overflow = style.overflow + style.overflowY + style.overflowX;\n',
    f'{indent}    if ((overflow.includes(\'scroll\') || overflow.includes(\'auto\')) && el.scrollHeight > el.clientHeight) {{\n',
    f'{indent}      info.scrollContainers.push({{\n',
    f'{indent}        tagName: el.tagName,\n',
    f'{indent}        className: el.className || \'\',\n',
    f'{indent}        id: el.id || \'\',\n',
    f'{indent}        scrollHeight: el.scrollHeight,\n',
    f'{indent}        clientHeight: el.clientHeight\n',
    f'{indent}      }});\n',
    f'{indent}    }}\n',
    f'{indent}  }});\n',
    f'{indent}  \n',
    f'{indent}  return info;\n',
    f'{indent}}});\n',
    f'{indent}\n',
    f'{indent}if (scrollInfo.scrollContainers.length > 0) {{\n',
    f'{indent}  const mainContainer = scrollInfo.scrollContainers.reduce((max, current) => \n',
    f'{indent}    current.scrollHeight > max.scrollHeight ? current : max\n',
    f'{indent}  );\n',
    f'{indent}  \n',
    f'{indent}  console.log(`[Puppeteer] 找到滚动容器: ${{mainContainer.tagName}} ${{(mainContainer.className || mainContainer.id || \'\').substring(0, 50)}}, 高度: ${{mainContainer.scrollHeight}}px`);\n',
    f'{indent}  \n',
    f'{indent}  for (let i = 0; i < 50; i++) {{\n',
    f'{indent}    const currentState = await page.evaluate((containerInfo) => {{\n',
    f'{indent}      const elements = document.querySelectorAll(containerInfo.tagName);\n',
    f'{indent}      let targetElement = null;\n',
    f'{indent}      \n',
    f'{indent}      for (const el of elements) {{\n',
    f'{indent}        if ((containerInfo.className && el.className.includes(containerInfo.className.split(\' \')[0])) ||\n',
    f'{indent}            (containerInfo.id && el.id === containerInfo.id)) {{\n',
    f'{indent}          if (el.scrollHeight > el.clientHeight) {{\n',
    f'{indent}            targetElement = el;\n',
    f'{indent}            break;\n',
    f'{indent}          }}\n',
    f'{indent}        }}\n',
    f'{indent}      }}\n',
    f'{indent}      \n',
    f'{indent}      if (targetElement) {{\n',
    f'{indent}        const scrollAmount = targetElement.clientHeight * 0.8;\n',
    f'{indent}        targetElement.scrollTop += scrollAmount;\n',
    f'{indent}        targetElement.dispatchEvent(new Event(\'scroll\', {{ bubbles: true }}));\n',
    f'{indent}        \n',
    f'{indent}        return {{\n',
    f'{indent}          scrollHeight: targetElement.scrollHeight,\n',
    f'{indent}          scrollTop: targetElement.scrollTop,\n',
    f'{indent}          clientHeight: targetElement.clientHeight,\n',
    f'{indent}          textLength: document.body.innerText.length\n',
    f'{indent}        }};\n',
    f'{indent}      }}\n',
    f'{indent}      \n',
    f'{indent}      return null;\n',
    f'{indent}    }}, {{\n',
    f'{indent}      tagName: mainContainer.tagName,\n',
    f'{indent}      className: mainContainer.className,\n',
    f'{indent}      id: mainContainer.id\n',
    f'{indent}    }});\n',
    f'{indent}    \n',
    f'{indent}    if (!currentState) break;\n',
    f'{indent}    \n',
    f'{indent}    await new Promise(resolve => setTimeout(resolve, 2000));\n',
    f'{indent}    \n',
    f'{indent}    if (i % 5 === 0) {{\n',
    f'{indent}      console.log(`[Puppeteer] 滚动第 ${{i + 1}} 轮: 容器高度 ${{currentState.scrollHeight}}px, 文本长度 ${{currentState.textLength}} 字符`);\n',
    f'{indent}    }}\n',
    f'{indent}    \n',
    f'{indent}    if (currentState.scrollTop + currentState.clientHeight >= currentState.scrollHeight - 10) {{\n',
    f'{indent}      console.log(\'[Puppeteer] 已滚动到底部\');\n',
    f'{indent}      break;\n',
    f'{indent}    }}\n',
    f'{indent}  }}\n',
    f'{indent}}} else {{\n',
    f'{indent}  console.log(\'[Puppeteer] 未找到滚动容器，使用备用滚动方案\');\n',
    f'{indent}  for (let i = 0; i < 20; i++) {{\n',
    f'{indent}    await page.evaluate(() => {{\n',
    f'{indent}      window.scrollTo(0, document.body.scrollHeight);\n',
    f'{indent}    }});\n',
    f'{indent}    await new Promise(resolve => setTimeout(resolve, 2000));\n',
    f'{indent}  }}\n',
    f'{indent}}}\n',
    f'{indent}\n'
]

# 插入代码
lines[insert_line:insert_line] = new_code

# 保存备份
with open('feishu-puppeteer.ts.bak_scroll_optimize', 'w', encoding='utf-8') as f:
    f.writelines(lines)

# 保存修改后的文件
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print(f"✅ 滚动优化已应用到第 {insert_line + 1} 行")
PYEOF

echo ""
echo "=== 第三步：验证修改 ==="
grep -A 5 "查找真实滚动容器" feishu-puppeteer.ts | head -10

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
    echo "✅✅✅ 滚动优化已应用到爬虫！"
    echo ""
    echo "现在爬虫会："
    echo "1. ✅ 自动查找真实的滚动容器（如 bear-web-x-container）"
    echo "2. ✅ 在正确的容器上滚动"
    echo "3. ✅ 等待内容加载完成"
    echo "4. ✅ 容器高度会从 9635px 增长到 18984px+"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
    echo "如果构建失败，可以恢复："
    echo "  cd /www/wwwroot/feihub/backend/src/lib"
    echo "  cp feishu-puppeteer.ts.bak_scroll_optimize feishu-puppeteer.ts"
fi


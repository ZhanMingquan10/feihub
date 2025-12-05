#!/bin/bash

cd /www/wwwroot/feihub/backend/src/lib

# 备份
cp feishu-puppeteer.ts feishu-puppeteer.ts.backup

# 修复1: 在 timeSelectors 数组最前面添加 .doc-info-time-item
sed -i '224s/const timeSelectors = \[/const timeSelectors = [\n        ".doc-info-time-item",  \/\/ 优先查找飞书文档的修改时间元素/' feishu-puppeteer.ts

# 修复2: 在 "额外等待3秒" 之后添加等待日期元素的代码
# 找到行号
line_num=$(grep -n "额外等待3秒，确保内容完全渲染" feishu-puppeteer.ts | cut -d: -f1)
if [ -n "$line_num" ]; then
    # 在下一行之后插入
    sed -i "${line_num}a\\
    // 额外等待，确保日期元素也加载完成（飞书的日期元素可能需要更长时间）\\
    console.log(\`[Puppeteer] 额外等待，确保日期元素加载完成...\`);\\
    \\
    // 等待日期元素出现（最多等待10秒）\\
    try {\\
      await page.waitForSelector('.doc-info-time-item', { timeout: 10000 });\\
      console.log(\`[Puppeteer] ✅ 找到日期元素 .doc-info-time-item\`);\\
      \\
      // 立即提取日期元素的内容，用于调试\\
      const dateElementText = await page.evaluate(() => {\\
        const el = document.querySelector('.doc-info-time-item');\\
        if (el) {\\
          return (el.innerText || el.textContent || '').trim();\\
        }\\
        return null;\\
      });\\
      console.log(\`[Puppeteer] 📅 日期元素内容: \"\${dateElementText}\"\`);\\
    } catch (e) {\\
      console.warn(\`[Puppeteer] ⚠️ 未找到日期元素 .doc-info-time-item，继续提取...\`);\\
    }\\
    \\
    // 再等待3秒，确保所有内容完全渲染\\
    await new Promise(resolve => setTimeout(resolve, 3000));
" feishu-puppeteer.ts
fi

# 修复3: 在日期提取部分，优先查找 .doc-info-time-item
sed -i '221a\
      // 优先查找 .doc-info-time-item（飞书文档的修改时间）\
      const docInfoTimeEl = document.querySelector(".doc-info-time-item") as HTMLElement | null;\
      if (docInfoTimeEl) {\
        const timeText = (docInfoTimeEl.innerText || docInfoTimeEl.textContent || "").trim();\
        if (timeText && timeText.length > 3) {\
          result.date = timeText;\
          console.log(`[Puppeteer] ✅ 找到日期来源: .doc-info-time-item, 内容: "${timeText}"`);\
        }\
      }\
      \
      // 如果还没找到，继续使用其他选择器
' feishu-puppeteer.ts

# 修复4: 添加详细日志
sed -i '275a\
    console.log(`[Puppeteer] 🔍 pageData 提取结果（详细）:`);\
    console.log(`[Puppeteer] - 标题: "${pageData.title}"`);\
    console.log(`[Puppeteer] - 作者: "${pageData.author}"`);\
    console.log(`[Puppeteer] - 日期（原始，从 pageData）: "${pageData.date}"`);
' feishu-puppeteer.ts

# 修复5: 改进日期解析日志
sed -i 's/dateText = parseChineseDate(dateText);/console.log(`[Puppeteer] 准备解析日期: "${dateText}"`);\
      dateText = parseChineseDate(dateText);\
      console.log(`[Puppeteer] 解析后的日期: "${dateText}"`);/' feishu-puppeteer.ts

echo "修复完成！"


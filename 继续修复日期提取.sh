#!/bin/bash

cd /www/wwwroot/feihub/backend/src/lib

# 备份
cp feishu-puppeteer.ts feishu-puppeteer.ts.backup2

# 修复1: 在 "额外等待3秒" 之后添加等待日期元素的代码
# 找到 "额外等待3秒" 的行号
line_num=$(grep -n "额外等待3秒，确保内容完全渲染" feishu-puppeteer.ts | cut -d: -f1)
if [ -n "$line_num" ]; then
    # 找到下一行（await new Promise）
    next_line=$((line_num + 1))
    # 在这行之后插入
    sed -i "${next_line}a\\
    \\
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
    echo "✅ 已添加等待日期元素的代码"
else
    echo "⚠️ 未找到 '额外等待3秒' 的位置"
fi

# 修复2: 在 pageData 提取的日期部分，优先查找 .doc-info-time-item
# 找到 "// 3. 提取日期" 的行号
date_line=$(grep -n "// 3. 提取日期 - 查找更新时间" feishu-puppeteer.ts | cut -d: -f1)
if [ -n "$date_line" ]; then
    # 在下一行之后插入
    next_date_line=$((date_line + 1))
    sed -i "${next_date_line}a\\
      // 优先查找 .doc-info-time-item（飞书文档的修改时间）\\
      const docInfoTimeEl = document.querySelector('.doc-info-time-item') as HTMLElement | null;\\
      if (docInfoTimeEl) {\\
        const timeText = (docInfoTimeEl.innerText || docInfoTimeEl.textContent || '').trim();\\
        if (timeText && timeText.length > 3) {\\
          result.date = timeText;\\
          console.log(\`[Puppeteer] ✅ 找到日期来源: .doc-info-time-item, 内容: \"\${timeText}\"\`);\\
        }\\
      }\\
      \\
      // 如果还没找到，继续使用其他选择器
" feishu-puppeteer.ts
    echo "✅ 已添加优先查找 .doc-info-time-item 的代码"
else
    echo "⚠️ 未找到 '// 3. 提取日期' 的位置"
fi

# 修复3: 改进日期解析日志
sed -i 's/dateText = parseChineseDate(dateText);/console.log(`[Puppeteer] 准备解析日期: "${dateText}"`);\
      dateText = parseChineseDate(dateText);\
      console.log(`[Puppeteer] 解析后的日期: "${dateText}"`);/' feishu-puppeteer.ts

echo "修复完成！"


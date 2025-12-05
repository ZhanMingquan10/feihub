#!/bin/bash

cd /www/wwwroot/feihub/backend/src/lib

# 备份原文件
cp feishu-puppeteer.ts feishu-puppeteer.ts.backup

# 修复1: 在 timeSelectors 数组最前面添加 .doc-info-time-item
sed -i 's/const timeSelectors = \[/const timeSelectors = [\n        ".doc-info-time-item",/' feishu-puppeteer.ts

# 修复2: 在页面加载后，添加等待日期元素的代码
# 找到 "额外等待3秒" 的位置，在其后添加等待日期元素的代码
sed -i '/额外等待3秒，确保内容完全渲染/a\    \/\/ 额外等待，确保日期元素也加载完成（飞书的日期元素可能需要更长时间）\n    console.log(`[Puppeteer] 额外等待，确保日期元素加载完成...`);\n    \n    \/\/ 等待日期元素出现（最多等待10秒）\n    try {\n      await page.waitForSelector(".doc-info-time-item", { timeout: 10000 });\n      console.log(`[Puppeteer] ✅ 找到日期元素 .doc-info-time-item`);\n      \n      \/\/ 立即提取日期元素的内容，用于调试\n      const dateElementText = await page.evaluate(() => {\n        const el = document.querySelector(".doc-info-time-item");\n        if (el) {\n          return (el.innerText || el.textContent || "").trim();\n        }\n        return null;\n      });\n      console.log(`[Puppeteer] 📅 日期元素内容: "${dateElementText}"`);\n    } catch (e) {\n      console.warn(`[Puppeteer] ⚠️ 未找到日期元素 .doc-info-time-item，继续提取...`);\n    }\n    \n    \/\/ 再等待3秒，确保所有内容完全渲染\n    await new Promise(resolve => setTimeout(resolve, 3000));' feishu-puppeteer.ts

# 修复3: 改进日期提取逻辑，优先查找 .doc-info-time-item
# 在 pageData 提取的日期部分，添加对 .doc-info-time-item 的优先查找
sed -i '/\/\/ 3. 提取日期 - 查找更新时间/i\      \/\/ 优先查找 .doc-info-time-item（飞书文档的修改时间）\n      const docInfoTimeEl = document.querySelector(".doc-info-time-item") as HTMLElement | null;\n      if (docInfoTimeEl) {\n        const timeText = (docInfoTimeEl.innerText || docInfoTimeEl.textContent || "").trim();\n        if (timeText && timeText.length > 3) {\n          result.date = timeText;\n          console.log(`[Puppeteer] ✅ 找到日期来源: .doc-info-time-item, 内容: "${timeText}"`);\n        }\n      }\n      \n      \/\/ 如果还没找到，继续使用其他选择器' feishu-puppeteer.ts

# 修复4: 改进日期解析，处理 "X月X日修改" 和 "YYYY年X月X日修改" 格式
# 查找 parseChineseDate 函数调用，添加更详细的日志
sed -i 's/dateText = parseChineseDate(dateText);/console.log(`[Puppeteer] 准备解析日期: "${dateText}"`);\n      dateText = parseChineseDate(dateText);\n      console.log(`[Puppeteer] 解析后的日期: "${dateText}"`);/' feishu-puppeteer.ts

# 修复5: 在 pageData 提取后，添加详细日志
sed -i '/const pageData = await page.evaluate(() => {/a\    console.log(`[Puppeteer] 🔍 pageData 提取结果（详细）:`);\n    console.log(`[Puppeteer] - 标题: "${pageData.title}"`);\n    console.log(`[Puppeteer] - 作者: "${pageData.author}"`);\n    console.log(`[Puppeteer] - 日期（原始，从 pageData）: "${pageData.date}"`);' feishu-puppeteer.ts

echo "修复完成！请检查代码，然后重新构建和部署。"


#!/bin/bash

cd /www/wwwroot/feihub/backend/src/lib

# 备份
cp feishu-puppeteer.ts feishu-puppeteer.ts.backup3

# 在第165行之后插入等待日期元素的代码
sed -i '165a\
\
    // 额外等待，确保日期元素也加载完成（飞书的日期元素可能需要更长时间）\
    console.log(`[Puppeteer] 额外等待，确保日期元素加载完成...`);\
\
    // 等待日期元素出现（最多等待10秒）\
    try {\
      await page.waitForSelector(".doc-info-time-item", { timeout: 10000 });\
      console.log(`[Puppeteer] ✅ 找到日期元素 .doc-info-time-item`);\
\
      // 立即提取日期元素的内容，用于调试\
      const dateElementText = await page.evaluate(() => {\
        const el = document.querySelector(".doc-info-time-item");\
        if (el) {\
          return (el.innerText || el.textContent || "").trim();\
        }\
        return null;\
      });\
      console.log(`[Puppeteer] 📅 日期元素内容: "${dateElementText}"`);\
    } catch (e) {\
      console.warn(`[Puppeteer] ⚠️ 未找到日期元素 .doc-info-time-item，继续提取...`);\
    }\
\
    // 再等待3秒，确保所有内容完全渲染\
    await new Promise(resolve => setTimeout(resolve, 3000));
' feishu-puppeteer.ts

echo "✅ 代码已添加"

# 验证
echo ""
echo "验证添加结果："
grep -n "额外等待，确保日期元素加载完成" feishu-puppeteer.ts
grep -n "找到日期元素" feishu-puppeteer.ts


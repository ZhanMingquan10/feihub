#!/bin/bash

cd /www/wwwroot/feihub/backend/src/lib

# 备份
cp feishu-puppeteer.ts feishu-puppeteer.ts.backup6

# 先删除重复的日志行
sed -i '363d' feishu-puppeteer.ts  # 删除重复的 "准备解析日期"
sed -i '367d' feishu-puppeteer.ts  # 删除重复的 "解析后的日期"

# 在第363行（"准备解析日期"）之后，parseChineseDate 之前插入英文日期解析代码
sed -i '363a\
      // 先尝试解析英文日期格式（如 "Modified January 9, 2024"）\
      let parsedDate = null;\
      const englishDateMatch = dateText.match(/(?:Modified|Updated)?\\s*(January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{1,2}),\\s*(\\d{4})/i);\
      if (englishDateMatch) {\
        const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];\
        const monthIndex = monthNames.findIndex(m => m.toLowerCase() === englishDateMatch[1].toLowerCase());\
        if (monthIndex !== -1) {\
          const year = parseInt(englishDateMatch[3]);\
          const month = monthIndex + 1;\
          const day = parseInt(englishDateMatch[2]);\
          parsedDate = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;\
          console.log(`[Puppeteer] ✅ 解析英文日期成功: "${dateText}" -> "${parsedDate}"`);\
        }\
      }\
\
      // 如果英文日期解析失败，使用 parseChineseDate\
      if (!parsedDate) {
' feishu-puppeteer.ts

# 在 parseChineseDate 调用后添加结束括号和赋值
sed -i '/dateText = parseChineseDate(dateText);/a\
      } else {\
        dateText = parsedDate;\
      }
' feishu-puppeteer.ts

echo "✅ 修复完成"

# 验证
sed -n '355,390p' feishu-puppeteer.ts


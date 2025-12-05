#!/bin/bash

# 逐步排查内容提取问题

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：查看内容提取的完整代码结构 ==="
echo ""
echo "1.1 查找 page.evaluate 的开始位置："
grep -n "content = await page.evaluate" feishu-puppeteer.ts

echo ""
echo "1.2 查找 page.evaluate 的结束位置："
grep -n "});" feishu-puppeteer.ts | head -5

echo ""
echo "=== 第二步：查看提取文本的代码 ==="
echo "2.1 查找 let text = clone.innerText 的位置："
grep -n "let text = clone.innerText\|let text = clone.textContent" feishu-puppeteer.ts

echo ""
echo "2.2 查看提取文本后的处理逻辑："
grep -A 30 "let text = clone.innerText" feishu-puppeteer.ts | head -40

echo ""
echo "=== 第三步：查看验证逻辑 ==="
echo "3.1 查找验证代码："
grep -n "Help Center\|Keyboard Shortcuts\|立即验证" feishu-puppeteer.ts | head -10

echo ""
echo "3.2 查看验证代码的上下文："
grep -B 5 -A 10 "立即验证\|Help Center" feishu-puppeteer.ts | head -30

echo ""
echo "=== 第四步：查看 return text.trim() 的位置 ==="
echo "4.1 查找所有 return text.trim()："
grep -n "return text.trim()" feishu-puppeteer.ts

echo ""
echo "4.2 查看 return text.trim() 的上下文："
grep -B 20 -A 5 "return text.trim()" feishu-puppeteer.ts | head -30

echo ""
echo "=== 第五步：查看 cheerio 备用方案 ==="
echo "5.1 查找 cheerio 备用方案："
grep -n "cheerio 备用方案\|使用 cheerio" feishu-puppeteer.ts

echo ""
echo "5.2 查看 cheerio 提取的代码："
grep -A 50 "cheerio 备用方案" feishu-puppeteer.ts | head -60

echo ""
echo "=== 第六步：查看完整的提取流程 ==="
echo "6.1 查看从页面直接提取内容的代码："
grep -B 10 -A 50 "从页面直接提取内容" feishu-puppeteer.ts | head -70

echo ""
echo "=== 完成 ==="
echo "请把以上输出发给我，我会根据实际代码结构提供精确的修复方案"


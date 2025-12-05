#!/bin/bash

cd /www/wwwroot/feihub/backend/src/lib

# 备份
cp feishu-puppeteer.ts feishu-puppeteer.ts.backup4

# 修复：将第193行的重复代码替换为正确的代码
sed -i '193s/if (el) { return (el.innerText || el.textContent || "").trim(); } return null;/return (el.innerText || el.textContent || "").trim();/' feishu-puppeteer.ts

# 验证修复
echo "修复后的代码："
sed -n '185,200p' feishu-puppeteer.ts


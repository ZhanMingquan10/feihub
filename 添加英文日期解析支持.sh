#!/bin/bash

cd /www/wwwroot/feihub/backend/src/lib

# 备份
cp feishu-puppeteer.ts feishu-puppeteer.ts.backup5

# 查找 parseChineseDate 调用的位置
grep -n "parseChineseDate" feishu-puppeteer.ts

# 在调用 parseChineseDate 之前，添加英文日期解析
# 找到 "准备解析日期" 之后，parseChineseDate 之前的位置
# 添加一个函数来解析英文日期格式

# 方法：在文件开头添加英文日期解析函数，然后在调用 parseChineseDate 之前先调用它


#!/bin/bash

# 查看服务器实际提取的内容

echo "=== 第一步：查看最近的提取日志 ==="
echo ""

cd /www/wwwroot/feihub/backend

# 查看最近的日志，特别是内容提取相关的
pm2 logs feihub-backend --lines 200 --nostream | grep -E "(提取|content|内容|正文|bodyText|Help Center|Keyboard)" | tail -50

echo ""
echo "=== 第二步：查看特定文档的提取日志 ==="
echo ""

# 查找包含这个链接的日志
pm2 logs feihub-backend --lines 500 --nostream | grep -A 20 -B 5 "VGoXdFXmooasHUxsZ0icAD2WnGe" | tail -50

echo ""
echo "=== 第三步：查看内容提取的详细日志 ==="
echo ""

# 查看所有内容相关的日志
pm2 logs feishu-backend --lines 500 --nostream 2>/dev/null | grep -E "(内容长度|内容预览|最终内容|提取的)" | tail -30

echo ""
echo "=== 第四步：查看实际使用的提取文件 ==="
echo ""

cd /www/wwwroot/feihub/backend/src/lib

# 检查实际使用的文件
echo "文件列表："
ls -la feishu*.ts

echo ""
echo "检查导入："
cd ../services
grep "from.*feishu" documentProcessor.ts

echo ""
echo "=== 第五步：查看提取代码的关键部分 ==="
echo ""

cd ../lib
for file in feishu*.ts; do
    if [ -f "$file" ]; then
        echo "=== $file 的内容提取部分 ==="
        # 显示内容提取相关的代码
        grep -A 30 -B 5 "提取内容\|querySelector.*content\|bodyText\|innerText.*textContent" "$file" | head -50
        echo ""
    fi
done

echo ""
echo "=== 完成 ==="
echo "请把以上输出发给我，我会分析问题所在"


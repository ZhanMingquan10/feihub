#!/bin/bash

# 修复正文提取问题 - 服务器执行脚本

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：检查实际使用的文件 ==="

# 检查哪些文件存在
echo "检查文件："
ls -la feishu*.ts 2>/dev/null || echo "未找到 feishu*.ts 文件"

# 检查 feishu.ts 是否存在
if [ -f "feishu.ts" ]; then
    echo "✅ 找到 feishu.ts"
    echo "检查它导出了什么："
    grep -n "export.*fetchFeishuDocument" feishu.ts || echo "未找到 fetchFeishuDocument 导出"
    grep -n "from.*feishu-puppeteer\|from.*feishu-server" feishu.ts || echo "未找到导入"
fi

# 检查 feishu-puppeteer.ts 是否存在
if [ -f "feishu-puppeteer.ts" ]; then
    echo "✅ 找到 feishu-puppeteer.ts"
    echo "文件大小："
    wc -l feishu-puppeteer.ts
fi

# 检查 feishu-server.ts
if [ -f "feishu-server.ts" ]; then
    echo "✅ 找到 feishu-server.ts"
    echo "文件大小："
    wc -l feishu-server.ts
fi

echo ""
echo "=== 第二步：检查实际调用的文件 ==="
cd /www/wwwroot/feihub/backend/src/services
echo "检查 documentProcessor.ts 导入："
grep -n "from.*feishu" documentProcessor.ts

echo ""
echo "=== 第三步：查找内容提取的代码位置 ==="
cd /www/wwwroot/feihub/backend/src/lib

# 在所有 feishu 相关文件中查找内容提取逻辑
for file in feishu*.ts; do
    if [ -f "$file" ]; then
        echo ""
        echo "检查文件: $file"
        echo "查找内容提取相关代码："
        grep -n "querySelector\|innerText\|textContent" "$file" | head -20
    fi
done

echo ""
echo "=== 第四步：检查是否有 Help Center 相关代码 ==="
for file in feishu*.ts; do
    if [ -f "$file" ]; then
        echo ""
        echo "检查文件: $file"
        grep -n "Help Center\|Keyboard Shortcuts" "$file" || echo "未找到"
    fi
done

echo ""
echo "=== 完成检查 ==="
echo "请把以上输出发给我，我会根据实际情况提供修复方案"


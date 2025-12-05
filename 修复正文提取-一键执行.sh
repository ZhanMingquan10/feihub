#!/bin/bash

# 修复正文提取问题 - 一键执行脚本
# 在服务器上执行：bash 修复正文提取-一键执行.sh

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：上传修复脚本 ==="
echo "如果脚本不在服务器上，请先上传 修复正文提取-服务器直接修复.py 到 /www/wwwroot/feihub/backend/src/lib/"

# 检查脚本是否存在
if [ ! -f "修复正文提取-服务器直接修复.py" ]; then
    echo "❌ 未找到修复脚本"
    echo "请先上传 修复正文提取-服务器直接修复.py 到当前目录"
    exit 1
fi

echo "✅ 找到修复脚本"

echo ""
echo "=== 第二步：执行修复 ==="
python3 修复正文提取-服务器直接修复.py

if [ $? -ne 0 ]; then
    echo "❌ 修复脚本执行失败"
    exit 1
fi

echo ""
echo "=== 第三步：重新构建 ==="
cd /www/wwwroot/feihub/backend

echo "正在构建..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ 构建失败，请检查错误信息"
    echo "可以恢复备份："
    echo "  cd /www/wwwroot/feihub/backend/src/lib"
    echo "  cp feishu*.ts.bak feishu*.ts"
    exit 1
fi

echo "✅ 构建成功"

echo ""
echo "=== 第四步：重启服务 ==="
pm2 restart feihub-backend

if [ $? -eq 0 ]; then
    echo ""
    echo "✅✅✅ 修复完成！"
    echo ""
    echo "请重新测试文档提取功能："
    echo "1. 访问网站"
    echo "2. 提交一个飞书文档链接"
    echo "3. 检查正文是否正确显示（不应该包含 Help Center、Keyboard Shortcuts 等）"
else
    echo "❌ 重启服务失败，请手动执行：pm2 restart feihub-backend"
fi


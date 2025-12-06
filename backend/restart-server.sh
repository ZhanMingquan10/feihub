#!/bin/bash
# 重启FeiHub服务器脚本

echo "正在重启FeiHub服务器..."

# 1. 停止所有Node进程
echo "停止现有Node进程..."
pkill -f "node.*dist/index.js" 2>/dev/null || true

# 2. 等待进程完全停止
sleep 2

# 3. 构建项目
echo "构建项目..."
cd /www/wwwroot/feihub/backend
npm run build

# 4. 启动服务器
echo "启动服务器..."
nohup node dist/index.js > app.log 2>&1 &
SERVER_PID=$!

# 5. 等待服务器启动
sleep 3

# 6. 检查服务器状态
if ps -p $SERVER_PID > /dev/null; then
    echo "服务器启动成功，PID: $SERVER_PID"
    echo "查看日志: tail -f /www/wwwroot/feihub/backend/app.log"
else
    echo "服务器启动失败"
    exit 1
fi
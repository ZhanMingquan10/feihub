#!/bin/bash

echo "=== 飞书项目服务器更新脚本 ==="
echo "更新时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 配置信息
PROJECT_DIR="/www/wwwroot/feihub.top"
BACKUP_DIR="/www/wwwroot/feihub.top/backup/$(date +%Y%m%d_%H%M%S)"

echo "项目目录: $PROJECT_DIR"
echo "备份目录: $BACKUP_DIR"
echo ""

# 1. 创建备份
echo "1. 创建项目备份..."
mkdir -p $BACKUP_DIR
cp -r $PROJECT_DIR/backend $BACKUP_DIR/
echo "✅ 备份完成"
echo ""

# 2. 进入项目目录
echo "2. 进入项目目录..."
cd $PROJECT_DIR
echo "✅ 当前目录: $(pwd)"
echo ""

# 3. 停止后端服务
echo "3. 停止后端服务..."
pm2 stop feishu-backend
echo "✅ 后端服务已停止"
echo ""

# 4. 拉取最新代码
echo "4. 从GitHub拉取最新代码..."
git pull origin main
if [ $? -ne 0 ]; then
    echo "❌ Git拉取失败，正在恢复备份..."
    cp -r $BACKUP_DIR/backend $PROJECT_DIR/
    pm2 restart feishu-backend
    exit 1
fi
echo "✅ 代码拉取成功"
echo ""

# 5. 进入后端目录
echo "5. 进入后端目录..."
cd backend
echo "✅ 当前目录: $(pwd)"
echo ""

# 6. 检查是否有新的依赖
echo "6. 检查依赖更新..."
if [ -f "package-lock.json" ]; then
    npm install
    echo "✅ 依赖安装完成"
fi
echo ""

# 7. 构建后端
echo "7. 构建后端代码..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ 构建失败，正在恢复备份..."
    cd ..
    cp -r $BACKUP_DIR/backend $PROJECT_DIR/
    pm2 restart feishu-backend
    exit 1
fi
echo "✅ 构建成功"
echo ""

# 8. 重启后端服务
echo "8. 重启后端服务..."
pm2 restart feishu-backend
sleep 3
echo "✅ 服务重启完成"
echo ""

# 9. 检查服务状态
echo "9. 检查服务状态..."
pm2 status
echo ""

# 10. 查看最近日志
echo "10. 查看最近日志..."
pm2 logs feishu-backend --lines 10
echo ""

echo "=== 更新完成 ==="
echo "✅ 项目已成功更新！"
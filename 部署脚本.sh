#!/bin/bash

# FeiHub 一键部署脚本
# 使用方法: bash 部署脚本.sh

set -e

echo "=========================================="
echo "  FeiHub 部署脚本"
echo "=========================================="
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
  echo "❌ 请使用 root 用户运行此脚本"
  exit 1
fi

# 1. 更新系统
echo "[1/10] 更新系统..."
if [ -f /etc/debian_version ]; then
  apt update && apt upgrade -y
  apt install -y git curl wget vim
elif [ -f /etc/redhat-release ]; then
  yum update -y
  yum install -y git curl wget vim
fi

# 2. 安装 Node.js
echo "[2/10] 安装 Node.js..."
if ! command -v node &> /dev/null; then
  if [ -f /etc/debian_version ]; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
  elif [ -f /etc/redhat-release ]; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs
  fi
fi

echo "✅ Node.js 版本: $(node -v)"
echo "✅ npm 版本: $(npm -v)"

# 3. 安装 PM2
echo "[3/10] 安装 PM2..."
if ! command -v pm2 &> /dev/null; then
  npm install -g pm2
fi
echo "✅ PM2 已安装"

# 4. 安装 Docker 和 Docker Compose
echo "[4/10] 安装 Docker..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | bash
  systemctl enable docker
  systemctl start docker
fi

if ! command -v docker-compose &> /dev/null; then
  curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

echo "✅ Docker 已安装"

# 5. 安装 PostgreSQL 和 Redis（使用 Docker）
echo "[5/10] 启动 PostgreSQL 和 Redis..."
cd /var/www/feihub || mkdir -p /var/www/feihub && cd /var/www/feihub

if [ ! -f docker-compose.prod.yml ]; then
  echo "❌ 未找到 docker-compose.prod.yml 文件"
  exit 1
fi

docker-compose -f docker-compose.prod.yml up -d
echo "✅ 数据库服务已启动"

# 6. 等待数据库就绪
echo "[6/10] 等待数据库就绪..."
sleep 10

# 7. 安装后端依赖
echo "[7/10] 安装后端依赖..."
cd /var/www/feihub/backend
npm install --production

# 8. 配置环境变量
echo "[8/10] 配置环境变量..."
if [ ! -f .env ]; then
  echo "⚠️  请手动配置 .env 文件"
  echo "   必需配置项："
  echo "   - DATABASE_URL"
  echo "   - REDIS_URL"
  echo "   - DEEPSEEK_API_KEY 或 OPENAI_API_KEY"
  echo "   - CORS_ORIGIN"
  read -p "按 Enter 继续..."
fi

# 9. 运行数据库迁移
echo "[9/10] 运行数据库迁移..."
npx prisma generate
npx prisma migrate deploy
echo "✅ 数据库迁移完成"

# 10. 构建并启动后端
echo "[10/10] 构建并启动后端..."
npm run build

# 创建日志目录
mkdir -p logs

# 启动 PM2
if pm2 list | grep -q "feihub-backend"; then
  pm2 restart feihub-backend
else
  pm2 start ecosystem.config.js
fi

pm2 save
pm2 startup

echo ""
echo "=========================================="
echo "  ✅ 后端部署完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 配置前端并构建"
echo "2. 配置 Nginx"
echo "3. 配置 SSL 证书"
echo ""
echo "查看日志: pm2 logs feihub-backend"
echo ""



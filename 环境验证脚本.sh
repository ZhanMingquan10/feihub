#!/bin/bash

# FeiHub 环境验证脚本
# 在宝塔面板的"终端"中执行此脚本，或保存为文件后执行

echo "=========================================="
echo "  FeiHub 环境验证"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查结果
PASS=0
FAIL=0

# 检查函数
check_command() {
    if command -v $1 &> /dev/null; then
        VERSION=$($1 $2 2>&1 | head -n 1)
        echo -e "${GREEN}✅ $1 已安装${NC}"
        echo "   版本: $VERSION"
        ((PASS++))
        return 0
    else
        echo -e "${RED}❌ $1 未安装${NC}"
        ((FAIL++))
        return 1
    fi
}

check_service() {
    if systemctl is-active --quiet $1; then
        echo -e "${GREEN}✅ $1 服务正在运行${NC}"
        ((PASS++))
        return 0
    else
        echo -e "${RED}❌ $1 服务未运行${NC}"
        ((FAIL++))
        return 1
    fi
}

# 1. 检查 Node.js
echo "1. 检查 Node.js..."
if check_command node "-v"; then
    NODE_VERSION=$(node -v)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_MAJOR" -ge 18 ]; then
        echo -e "   ${GREEN}版本符合要求 (>= 18)${NC}"
    else
        echo -e "   ${YELLOW}⚠️  版本过低，建议升级到 18+${NC}"
    fi
fi
echo ""

# 2. 检查 npm
echo "2. 检查 npm..."
check_command npm "-v"
echo ""

# 3. 检查 PM2
echo "3. 检查 PM2..."
check_command pm2 "-v"
echo ""

# 4. 检查 Nginx
echo "4. 检查 Nginx..."
if check_command nginx "-v"; then
    check_service nginx
fi
echo ""

# 5. 检查 PostgreSQL
echo "5. 检查 PostgreSQL..."
if check_command psql "--version"; then
    check_service postgresql
    # 尝试连接数据库
    echo "   测试数据库连接..."
    if PGPASSWORD=your_password psql -U feihub_user -d feihub -h localhost -c "SELECT 1;" &> /dev/null; then
        echo -e "   ${GREEN}✅ 数据库连接成功${NC}"
        ((PASS++))
    else
        echo -e "   ${YELLOW}⚠️  数据库连接失败（可能数据库还未创建）${NC}"
    fi
else
    check_service postgresql
fi
echo ""

# 6. 检查 Redis
echo "6. 检查 Redis..."
if check_command redis-cli "--version"; then
    check_service redis
    # 测试 Redis 连接
    echo "   测试 Redis 连接..."
    if redis-cli ping &> /dev/null; then
        echo -e "   ${GREEN}✅ Redis 连接成功${NC}"
        ((PASS++))
    else
        echo -e "   ${RED}❌ Redis 连接失败${NC}"
        ((FAIL++))
    fi
else
    check_service redis
fi
echo ""

# 7. 检查端口
echo "7. 检查端口占用..."
PORTS=(4000 5432 6379 80 443)
for PORT in "${PORTS[@]}"; do
    if netstat -tuln | grep -q ":$PORT "; then
        echo -e "   ${GREEN}✅ 端口 $PORT 已占用（服务可能正在运行）${NC}"
    else
        echo -e "   ${YELLOW}⚠️  端口 $PORT 未占用${NC}"
    fi
done
echo ""

# 8. 检查项目目录
echo "8. 检查项目目录..."
if [ -d "/www/wwwroot/feihub" ]; then
    echo -e "   ${GREEN}✅ 项目目录存在: /www/wwwroot/feihub${NC}"
    if [ -f "/www/wwwroot/feihub/backend/.env" ]; then
        echo -e "   ${GREEN}✅ 后端配置文件存在${NC}"
    else
        echo -e "   ${YELLOW}⚠️  后端配置文件不存在 (.env)${NC}"
    fi
    if [ -d "/www/wwwroot/feihub/dist" ]; then
        echo -e "   ${GREEN}✅ 前端构建目录存在${NC}"
    else
        echo -e "   ${YELLOW}⚠️  前端构建目录不存在 (需要运行 npm run build)${NC}"
    fi
    ((PASS++))
else
    echo -e "   ${RED}❌ 项目目录不存在${NC}"
    ((FAIL++))
fi
echo ""

# 9. 检查 PM2 进程
echo "9. 检查 PM2 进程..."
if command -v pm2 &> /dev/null; then
    PM2_LIST=$(pm2 list 2>&1)
    if echo "$PM2_LIST" | grep -q "feihub-backend"; then
        echo -e "   ${GREEN}✅ feihub-backend 进程正在运行${NC}"
        ((PASS++))
    else
        echo -e "   ${YELLOW}⚠️  feihub-backend 进程未运行${NC}"
    fi
fi
echo ""

# 总结
echo "=========================================="
echo "  验证结果"
echo "=========================================="
echo -e "${GREEN}通过: $PASS${NC}"
echo -e "${RED}失败: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ 所有检查通过！环境已准备就绪。${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  部分检查未通过，请根据上述提示进行修复。${NC}"
    exit 1
fi



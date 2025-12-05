#!/bin/bash

# 配置 Git 凭据并推送代码到 GitHub

cd /www/wwwroot/feihub

# 配置 Git 用户名（如果还没配置）
git config user.name "ZhanMingquan" || true
git config user.email "ZhanMingquan@users.noreply.github.com" || true

# 配置远程仓库 URL（使用 PAT 认证）
# 注意：这里使用 PAT 作为密码
git remote set-url origin https://ZhanMingquan:@github.com/ZhanMingquan/feihub.git

# 检查状态
echo "========================================="
echo "检查 Git 状态..."
echo "========================================="
git status

# 添加所有更改
echo ""
echo "========================================="
echo "添加所有更改..."
echo "========================================="
git add .

# 提交
echo ""
echo "========================================="
echo "提交更改..."
echo "========================================="
git commit -m "修复日期提取问题：添加详细调试日志和日期元素查找" || echo "没有需要提交的更改"

# 推送到 GitHub
echo ""
echo "========================================="
echo "推送到 GitHub..."
echo "========================================="
git push origin main

echo ""
echo "========================================="
echo "完成！"
echo "========================================="


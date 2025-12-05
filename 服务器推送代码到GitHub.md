# 服务器推送代码到 GitHub

## 🚀 方法一：使用脚本（推荐）

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub

# 下载并执行脚本
curl -o /tmp/push-to-github.sh https://raw.githubusercontent.com/ZhanMingquan/feihub/main/服务器推送代码到GitHub.sh 2>/dev/null || cat > /tmp/push-to-github.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/feihub
git config user.name "ZhanMingquan" || true
git config user.email "ZhanMingquan@users.noreply.github.com" || true
git remote set-url origin https://ZhanMingquan:@github.com/ZhanMingquan/feihub.git
git status
git add .
git commit -m "修复日期提取问题：添加详细调试日志和日期元素查找" || echo "没有需要提交的更改"
git push origin main
EOF

chmod +x /tmp/push-to-github.sh
/tmp/push-to-github.sh
```

---

## 🔧 方法二：手动执行（如果脚本失败）

```bash
cd /www/wwwroot/feihub

# 1. 配置 Git 用户信息
git config user.name "ZhanMingquan"
git config user.email "ZhanMingquan@users.noreply.github.com"

# 2. 配置远程仓库 URL（包含认证信息）
git remote set-url origin https://ZhanMingquan:@github.com/ZhanMingquan/feihub.git

# 3. 检查状态
git status

# 4. 添加所有更改
git add .

# 5. 提交
git commit -m "修复日期提取问题：添加详细调试日志和日期元素查找"

# 6. 推送
git push origin main
```

---

## ✅ 推送成功后，重新部署

```bash
cd /www/wwwroot/feihub/backend

# 重新构建
npm run build

# 完全重启 PM2
pm2 stop feihub-backend
pm2 delete feihub-backend
pm2 start npm --name feihub-backend -- run start

# 等待启动
sleep 5

# 查看启动日志
pm2 logs feihub-backend --lines 30 --nostream | grep -E "(启动|CHROME_PATH)" | tail -10
```

---

## 🔒 安全提示

⚠️ **重要**：PAT（Personal Access Token）是敏感信息，建议：
1. 推送完成后，考虑撤销并重新生成新的 PAT
2. 不要在代码中硬编码 PAT
3. 使用 Git 凭据存储（如果可能）

---

执行方法一或方法二，把结果发给我。


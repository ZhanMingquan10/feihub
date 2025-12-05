# 回退修复 - 从 GitHub 恢复

## 🚀 从 GitHub 恢复原始代码

在服务器上执行：

```bash
cd /www/wwwroot/feihub

# 恢复 feishu-puppeteer.ts 到最新提交的状态
git checkout HEAD -- backend/src/lib/feishu-puppeteer.ts

# 或者恢复到特定提交（如果需要）
# git log --oneline backend/src/lib/feishu-puppeteer.ts | head -5
# git checkout <commit-hash> -- backend/src/lib/feishu-puppeteer.ts

# 重新构建
cd backend
npm run build && pm2 restart feihub-backend && echo "✅ 恢复完成！"
```

---

## 📝 或者查看所有备份，选择一个更早的

```bash
cd /www/wwwroot/feihub/backend/src/lib

# 查看所有备份文件
ls -la feishu-puppeteer.ts.bak* | tail -10

# 选择一个更早的备份（比如 .bak 或 .bak1）
cp feishu-puppeteer.ts.bak feishu-puppeteer.ts

# 或者查看备份的时间
ls -lt feishu-puppeteer.ts.bak* | tail -10

# 重新构建
cd /www/wwwroot/feihub/backend
npm run build && pm2 restart feihub-backend
```

---

## 🚀 一键恢复（推荐）

```bash
cd /www/wwwroot/feihub && \
git checkout HEAD -- backend/src/lib/feishu-puppeteer.ts && \
cd backend && \
npm run build && \
pm2 restart feihub-backend && \
echo "✅✅✅ 已从 GitHub 恢复完成！"
```

---

推荐使用一键恢复命令，从 GitHub 恢复原始代码。


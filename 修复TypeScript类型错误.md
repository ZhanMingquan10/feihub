# 修复 TypeScript 类型错误

## 🔧 在服务器上执行

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend/src/lib

# 查看第193行附近的代码
sed -n '190,195p' feishu-puppeteer.ts

# 修复类型错误：将 Element 断言为 HTMLElement
sed -i '193s/const el = document.querySelector(".doc-info-time-item");/const el = document.querySelector(".doc-info-time-item") as HTMLElement | null;/' feishu-puppeteer.ts

# 验证修复
sed -n '190,195p' feishu-puppeteer.ts
```

---

## ✅ 如果修复成功，重新构建

```bash
cd /www/wwwroot/feihub/backend

# 重新构建
npm run build

# 检查构建是否成功
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    
    # 完全重启 PM2
    pm2 stop feihub-backend
    pm2 delete feihub-backend
    pm2 start npm --name feihub-backend -- run start
    
    echo "✅ 部署完成"
else
    echo "❌ 构建失败，请检查错误信息："
    npm run build 2>&1 | tail -30
fi
```


# 安装 Chrome 指南

## 🚀 快速安装（推荐）

在宝塔终端执行以下命令：

```bash
# 1. 下载 Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# 2. 安装依赖
sudo apt-get update
sudo apt-get install -y libxss1 libappindicator1 libindicator7

# 3. 安装 Chrome
sudo apt-get install -y ./google-chrome-stable_current_amd64.deb

# 4. 验证安装
google-chrome-stable --version

# 5. 设置环境变量
cd /www/wwwroot/feihub/backend
echo "CHROME_PATH=/usr/bin/google-chrome-stable" >> .env

# 6. 验证环境变量
cat .env | grep CHROME_PATH

# 7. 重启服务
pm2 restart feihub-backend --update-env

# 8. 查看启动日志
pm2 logs feihub-backend --lines 50 --nostream | grep -E "(启动|CHROME_PATH|getChromePath|Puppeteer|Using browser)" | tail -30
```

---

## ✅ 验证安装

应该看到：
```
[启动] 环境变量 CHROME_PATH: "/usr/bin/google-chrome-stable"
[getChromePath] ✅ 找到 Chrome: /usr/bin/google-chrome-stable
[Puppeteer] Using browser at: /usr/bin/google-chrome-stable
```

---

## 🆘 如果安装失败

如果遇到错误，请把错误信息发给我，我会帮你解决。

常见问题：
1. **网络问题**：如果下载失败，可能需要配置代理或使用镜像
2. **依赖问题**：如果安装失败，可能需要先安装依赖
3. **权限问题**：确保有 sudo 权限



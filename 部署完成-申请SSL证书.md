# 部署完成 - 申请 SSL 证书

## ✅ 已完成
- [x] 后端服务运行正常
- [x] 前端构建成功
- [x] Nginx 配置正确
- [x] 网站可以通过 IP 访问
- [x] 域名可以访问（DNS 已生效）

---

## 🔐 最后一步：申请 SSL 证书（启用 HTTPS）

### 步骤 1：打开站点设置

在宝塔面板：
1. 点击左侧 **"网站"**
2. 找到 `feihub.top` 网站
3. 点击右侧 **"设置"** 按钮

---

### 步骤 2：申请 SSL 证书

1. 在站点设置页面，点击 **"SSL"** 标签
2. 选择 **"Let's Encrypt"** 标签
3. 勾选域名：
   - `feihub.top`
   - `www.feihub.top`（如果也支持）
4. 点击 **"申请"** 按钮
5. 等待申请完成（可能需要几分钟）

**注意**：
- 申请前确保域名解析已生效（你已经确认可以访问了）
- 确保 80 端口已开放（用于验证）

---

### 步骤 3：启用 HTTPS

1. 申请成功后，点击 **"强制HTTPS"** 按钮
2. 这样所有 HTTP 请求会自动跳转到 HTTPS

---

### 步骤 4：验证 HTTPS

1. **访问**：`https://feihub.top`
2. **应该看到**：
   - 浏览器地址栏显示锁图标（🔒）
   - 网站正常显示
   - 所有 HTTP 请求自动跳转到 HTTPS

---

## ✅ 完成后的检查清单

- [x] 网站可以通过 IP 访问
- [x] 域名可以访问
- [ ] SSL 证书已申请
- [ ] HTTPS 已启用
- [ ] 网站功能正常（搜索、分享、查看文档）
- [ ] 客服功能正常

---

## 🎉 部署完成！

完成 SSL 证书申请后，你的 FeiHub 网站就完全部署好了！

---

## 📝 后续维护

### 更新代码

当你在本地修改代码后：

1. **本地推送**：
   ```bash
   git add .
   git commit -m "描述修改内容"
   git push
   ```

2. **服务器更新**：
   ```bash
   cd /www/wwwroot/feihub
   git pull
   
   # 更新后端
   cd backend
   npm install --production
   npm run build
   pm2 restart feihub-backend
   
   # 更新前端
   cd ..
   npm install
   npm run build
   ```

---

### 查看日志

```bash
# 后端日志
pm2 logs feihub-backend

# Nginx 访问日志
tail -f /www/wwwlogs/feihub.top.log

# Nginx 错误日志
tail -f /www/wwwlogs/feihub.top.error.log
```

---

### 重启服务

```bash
# 重启后端
pm2 restart feihub-backend

# 重载 Nginx
nginx -s reload
```

---

## 🎯 现在执行

1. **申请 SSL 证书**（在宝塔面板）
2. **启用 HTTPS**
3. **测试所有功能**（搜索、分享、查看文档、客服）

完成后告诉我结果，我们完成部署！



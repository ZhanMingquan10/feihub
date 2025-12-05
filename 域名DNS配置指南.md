# 域名 DNS 配置指南 - feihub.top

## ⚠️ 问题说明
提示"未接入使用云解析DNS"表示域名还没有使用阿里云的DNS服务器，解析记录不会生效。

## 🔧 解决方案

### 方法一：使用阿里云DNS（推荐）

#### 步骤1：检查域名DNS服务器
1. 登录阿里云控制台
2. 进入"域名" → "域名列表"
3. 找到 `feihub.top`，点击"管理"
4. 查看"DNS服务器"部分

#### 步骤2：修改DNS服务器为阿里云
1. 在域名管理页面，点击"修改DNS"
2. 选择"使用阿里云DNS"
3. 系统会自动填入阿里云DNS服务器地址（通常是）：
   ```
   dns1.hichina.com
   dns2.hichina.com
   ```
   或者
   ```
   ns1.alidns.com
   ns2.alidns.com
   ```
4. 点击"确认"
5. **注意**：DNS修改后，需要等待几分钟到几小时才能生效（通常5-30分钟）

#### 步骤3：添加解析记录
1. 在域名管理页面，点击"解析"
2. 点击"添加记录"
3. 配置：
   - **记录类型**：A
   - **主机记录**：@（表示 feihub.top）
   - **记录值**：你的服务器公网IP
   - **TTL**：10分钟
4. 点击"确认"
5. 如果也要支持 www 访问，再添加一条：
   - **记录类型**：A
   - **主机记录**：www
   - **记录值**：你的服务器公网IP

#### 步骤4：验证DNS是否生效
等待5-30分钟后，在本地电脑执行：
```bash
# Windows PowerShell 或 CMD
ping feihub.top

# 或者使用 nslookup
nslookup feihub.top
```

如果返回你的服务器IP，说明DNS已生效。

---

### 方法二：如果域名在其他服务商注册

如果 `feihub.top` 是在其他服务商（如GoDaddy、Namecheap等）注册的：

1. **登录域名注册商的控制台**
2. **找到DNS设置或Name Servers设置**
3. **修改为阿里云DNS服务器**：
   ```
   dns1.hichina.com
   dns2.hichina.com
   ```
4. **保存并等待生效**（可能需要几小时）

---

## 📋 完整DNS配置检查清单

- [ ] 域名已修改为使用阿里云DNS服务器
- [ ] 已添加 A 记录：@ → 服务器IP
- [ ] 已添加 A 记录：www → 服务器IP（可选）
- [ ] 等待DNS生效（5-30分钟）
- [ ] 验证DNS解析：`ping feihub.top` 返回服务器IP
- [ ] 可以访问：`http://feihub.top`（HTTP）
- [ ] 配置SSL后可以访问：`https://feihub.top`（HTTPS）

---

## 🔍 如何验证DNS是否生效

### 方法1：使用 ping 命令
```bash
ping feihub.top
```
应该返回你的服务器IP地址。

### 方法2：使用在线工具
访问以下网站查询DNS解析：
- https://www.whatsmydns.net/
- https://dnschecker.org/
- 输入域名 `feihub.top`，查看是否解析到你的服务器IP

### 方法3：在浏览器访问
- 访问：`http://feihub.top`
- 如果能看到网站（或Nginx默认页面），说明DNS已生效

---

## ⏰ DNS生效时间

- **通常**：5-30分钟
- **最长**：24-48小时（很少见）
- **建议**：修改DNS后，等待30分钟再测试

---

## 🚨 常见问题

### 1. DNS修改后仍然不生效
- ✅ 确认DNS服务器已正确修改
- ✅ 确认解析记录已添加
- ✅ 等待足够的时间（至少30分钟）
- ✅ 清除本地DNS缓存：
  ```bash
  # Windows
  ipconfig /flushdns
  
  # Mac/Linux
  sudo dscacheutil -flushcache
  ```

### 2. 解析记录显示"未生效"
- ✅ 确认已使用阿里云DNS服务器
- ✅ 确认解析记录配置正确
- ✅ 等待DNS传播完成

---

## 📝 下一步

DNS配置完成后：
1. 等待DNS生效（5-30分钟）
2. 验证DNS解析：`ping feihub.top`
3. 继续按照 `feihub.top部署指南.md` 进行部署



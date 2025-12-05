# 修复 IP 访问问题

## 🔍 问题说明

通过服务器 IP 访问显示"没有找到站点"，说明：
- Nginx 配置中，`server_name` 只配置了域名（`feihub.top`）
- 当通过 IP 访问时，Nginx 找不到匹配的 server 块，返回默认错误页面

---

## 🔧 解决方案

### 方案一：修改网站配置支持 IP 访问（推荐，用于测试）

在宝塔文件管理器中：
1. 进入 `/www/server/panel/vhost/nginx/`
2. 编辑 `feihub.top.conf`
3. 找到 `server_name` 行：
   ```nginx
   server_name feihub.top www.feihub.top;
   ```
4. 修改为（添加服务器 IP 和 localhost）：
   ```nginx
   server_name feihub.top www.feihub.top _;
   ```

**或者使用终端命令**：

```bash
# 获取服务器 IP
SERVER_IP=$(curl -s ifconfig.me)

# 修改配置文件，添加 _ 作为默认匹配
sed -i 's/server_name feihub.top www.feihub.top;/server_name feihub.top www.feihub.top _;/' /www/server/panel/vhost/nginx/feihub.top.conf

# 重载 Nginx
nginx -s reload
```

---

### 方案二：检查默认站点

可能是有默认站点覆盖了配置。

```bash
# 查看所有站点配置
ls -la /www/server/panel/vhost/nginx/*.conf

# 检查是否有默认站点
grep -r "default_server" /www/server/panel/vhost/nginx/*.conf
```

---

### 方案三：临时添加默认 server 块（不推荐，仅用于测试）

如果需要临时测试，可以添加一个默认 server 块，但这不是最佳实践。

---

## 🚀 快速修复（推荐方案一）

在宝塔终端执行：

```bash
# 修改配置文件，添加 _ 作为默认匹配
sed -i 's/server_name feihub.top www.feihub.top;/server_name feihub.top www.feihub.top _;/' /www/server/panel/vhost/nginx/feihub.top.conf

# 检查配置语法
nginx -t

# 重载 Nginx
nginx -s reload

# 测试访问
curl -I http://localhost
```

---

## ✅ 验证修复

修复后，测试：

1. **通过 IP 访问**（在浏览器）：
   - `http://你的服务器IP`
   - 应该能看到网站首页

2. **通过域名访问**（DNS 生效后）：
   - `http://feihub.top`
   - 应该能看到网站首页

---

## 📝 说明

- `_` 是 Nginx 的默认 server_name，匹配所有未匹配的请求
- 添加 `_` 后，通过 IP 访问也能匹配到这个站点
- 这是临时方案，主要用于测试
- DNS 生效后，通过域名访问会更规范

---

## 🎯 现在执行

先执行快速修复命令：

```bash
sed -i 's/server_name feihub.top www.feihub.top;/server_name feihub.top www.feihub.top _;/' /www/server/panel/vhost/nginx/feihub.top.conf
nginx -t
nginx -s reload
```

然后：
1. **在浏览器访问**：`http://你的服务器IP`
2. **应该能看到网站首页**

同时：
1. **在阿里云配置 DNS 解析**（按照之前的步骤）
2. **等待 DNS 生效**（10-30 分钟）

完成后告诉我结果，我们继续！



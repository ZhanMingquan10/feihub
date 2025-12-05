# 宝塔面板 PostgreSQL 安装检查

## 问题说明

`systemctl status postgresql` 显示服务不存在，说明：
1. PostgreSQL 可能没有安装
2. 或者使用了不同的服务名称
3. 或者宝塔面板使用不同的管理方式

---

## 🔍 第一步：检查 PostgreSQL 是否已安装

在宝塔终端执行：

```bash
# 检查 PostgreSQL 是否安装
which psql
psql --version

# 检查宝塔面板的 PostgreSQL 目录
ls -la /www/server/pgsql/ 2>/dev/null

# 检查进程
ps aux | grep postgres
```

---

## 📦 第二步：在宝塔面板安装 PostgreSQL

如果 PostgreSQL 没有安装：

1. **在宝塔面板安装 PostgreSQL**
   - 点击左侧 **"软件商店"**
   - 搜索 **"PostgreSQL"**
   - 找到 **"PostgreSQL"**（不是 "PostgreSQL 管理器"）
   - 点击 **"安装"**
   - 选择版本（建议选择最新稳定版，如 15.x 或 16.x）
   - 等待安装完成（可能需要几分钟）

2. **启动 PostgreSQL 服务**
   - 安装完成后，点击 **"设置"**
   - 查看服务状态
   - 如果未运行，点击 **"启动"**

---

## 🔧 第三步：检查宝塔面板的 PostgreSQL 服务名称

宝塔面板的 PostgreSQL 可能使用不同的服务名称：

```bash
# 检查所有 PostgreSQL 相关服务
systemctl list-units | grep postgres
systemctl list-units | grep pgsql

# 检查宝塔面板的服务管理
/etc/init.d/postgresql status
/etc/init.d/pgsql status

# 或者查看宝塔面板的进程管理
bt process
```

---

## 🎯 推荐方案：通过宝塔面板管理 PostgreSQL

### 方案 A：在宝塔面板检查 PostgreSQL

1. **检查 PostgreSQL 是否安装**
   - 在宝塔面板，点击左侧 **"软件商店"**
   - 查看已安装的软件
   - 确认是否有 **"PostgreSQL"**

2. **如果没有安装，安装它**
   - 搜索 **"PostgreSQL"**
   - 点击 **"安装"**
   - 选择版本并安装

3. **启动 PostgreSQL**
   - 安装完成后，点击 **"设置"**
   - 点击 **"启动"**（如果未运行）

4. **创建数据库**
   - 点击左侧 **"数据库"** → **"PostgreSQL"**
   - 点击 **"添加数据库"**
   - 填写：
     - **数据库名**：`feihub`
     - **用户名**：`feihub_user`
     - **密码**：设置一个强密码
   - 点击 **"提交"**

---

## 🔍 诊断命令

在宝塔终端执行以下命令，把结果告诉我：

```bash
# 1. 检查 PostgreSQL 是否安装
which psql
psql --version 2>&1

# 2. 检查宝塔面板的 PostgreSQL 目录
ls -la /www/server/pgsql/ 2>/dev/null || echo "PostgreSQL 目录不存在"

# 3. 检查 PostgreSQL 进程
ps aux | grep postgres | grep -v grep

# 4. 检查端口 5432 是否被占用
netstat -tlnp | grep 5432

# 5. 检查宝塔面板的服务
/etc/init.d/postgresql status 2>&1
/etc/init.d/pgsql status 2>&1
```

---

## 📝 如果 PostgreSQL 未安装

### 在宝塔面板安装 PostgreSQL

1. **打开宝塔面板**
   - 访问：`http://你的服务器IP:8888`

2. **安装 PostgreSQL**
   - 点击左侧 **"软件商店"**
   - 搜索 **"PostgreSQL"**
   - 找到 **"PostgreSQL"**（注意：不是 "PostgreSQL 管理器"）
   - 点击 **"安装"**
   - 选择版本（建议 15.x 或 16.x）
   - 点击 **"提交"**
   - 等待安装完成

3. **启动 PostgreSQL**
   - 安装完成后，在软件商店找到 PostgreSQL
   - 点击 **"设置"**
   - 点击 **"启动"**（如果未运行）

4. **创建数据库**
   - 点击左侧 **"数据库"** → **"PostgreSQL"**
   - 点击 **"添加数据库"**
   - 填写数据库信息并提交

---

## 🆘 如果宝塔面板没有 PostgreSQL

如果宝塔面板的软件商店中没有 PostgreSQL，可能需要：

1. **更新宝塔面板**
   - 在宝塔面板，点击右上角 **"更新"**
   - 更新到最新版本

2. **或者手动安装 PostgreSQL**

```bash
# Ubuntu/Debian
apt update
apt install postgresql postgresql-contrib -y

# 启动服务
systemctl start postgresql
systemctl enable postgresql

# 设置 postgres 用户密码
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'your_password';"
```

---

## ✅ 验证安装

安装完成后，验证：

```bash
# 检查服务状态
systemctl status postgresql

# 或者
/etc/init.d/postgresql status

# 测试连接
psql -U postgres -d postgres -c "SELECT version();"
```

---

## 📋 完整流程

1. **检查 PostgreSQL 是否安装**（在宝塔面板或终端）
2. **如果没有安装，安装它**（在宝塔面板软件商店）
3. **启动 PostgreSQL 服务**（在宝塔面板或终端）
4. **创建数据库**（在宝塔面板数据库管理）
5. **运行迁移**（在终端）

---

## 🎯 下一步

请先执行诊断命令，把结果告诉我：

```bash
which psql
ls -la /www/server/pgsql/ 2>/dev/null || echo "PostgreSQL 目录不存在"
ps aux | grep postgres | grep -v grep
```

或者直接在宝塔面板检查：
- 软件商店 → 查看是否有 PostgreSQL
- 数据库 → PostgreSQL → 查看是否可以创建数据库



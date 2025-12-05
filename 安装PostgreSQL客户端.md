# 安装 PostgreSQL 客户端工具

## 问题
PostgreSQL 服务已安装，但 `psql` 命令找不到。

## 解决方案

### 方法一：安装 PostgreSQL 客户端（推荐）

```bash
apt update
apt install postgresql-client -y
```

或者：

```bash
apt install postgresql-client-common -y
```

### 方法二：查找 PostgreSQL 安装位置

如果 PostgreSQL 是通过宝塔面板安装的，可能安装在非标准位置：

```bash
# 查找 psql 命令
find /www/server -name psql 2>/dev/null
find /usr -name psql 2>/dev/null

# 如果找到了，添加到 PATH
# 例如：/www/server/postgresql/15/bin/psql
export PATH=$PATH:/www/server/postgresql/15/bin
```

### 方法三：检查宝塔面板中的 PostgreSQL 路径

1. 在宝塔面板，点击"数据库" → "PostgreSQL"
2. 查看 PostgreSQL 的安装路径
3. 在终端中使用完整路径访问

## 验证安装

安装完成后，执行：

```bash
psql --version
```

应该显示版本号（如 `psql (PostgreSQL) 15.x`）

## 检查服务状态

```bash
# 检查 PostgreSQL 服务
systemctl status postgresql

# 或者
systemctl status postgresql-15
# 或
systemctl status postgresql-16
```



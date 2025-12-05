# 解决 Docker 镜像拉取失败问题

## 问题：TLS handshake timeout

这是网络问题，Docker 无法从官方仓库拉取镜像。

## 解决方案

### 方案一：配置 Docker 镜像加速器（推荐）

1. **打开 Docker Desktop**
2. **进入设置**：点击右上角齿轮图标
3. **Docker Engine**：在左侧菜单找到 "Docker Engine"
4. **添加镜像源**：在 JSON 配置中添加以下内容：

```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
```

5. **点击 Apply & Restart**
6. **重新运行启动脚本**

### 方案二：手动拉取镜像

打开命令行执行：

```bash
# 拉取 PostgreSQL 镜像
docker pull postgres:15-alpine

# 拉取 Redis 镜像
docker pull redis:7-alpine

# 然后运行启动脚本
```

### 方案三：使用国内镜像源（修改 docker-compose.yml）

如果上述方法都不行，可以修改 `docker-compose.yml` 使用国内镜像：

```yaml
services:
  postgres:
    image: registry.cn-hangzhou.aliyuncs.com/acs/postgres:15-alpine
    # ... 其他配置保持不变
```

## 验证 Docker 镜像加速器

执行以下命令测试：

```bash
docker info | findstr "Registry Mirrors"
```

应该能看到你配置的镜像源。

## 临时解决方案

如果急需启动服务，可以：

1. **跳过 Docker**：先不启动数据库，直接启动后端服务测试
2. **使用本地数据库**：如果你本地已安装 PostgreSQL 和 Redis，可以直接使用

修改 `.env` 文件中的连接字符串指向本地服务。



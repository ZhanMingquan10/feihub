# 安装 PM2 指南

## 前提条件
- ✅ Node.js 已安装
- ✅ npm 已安装

## 安装 PM2

在宝塔终端执行：

```bash
npm install -g pm2
```

## 验证安装

安装完成后，执行：

```bash
pm2 -v
```

应该显示版本号（如 `5.x.x`）

## 如果安装失败

如果遇到权限问题，可以尝试：

```bash
sudo npm install -g pm2
```

## 安装 PM2 后的常用命令

```bash
# 查看版本
pm2 -v

# 查看进程列表
pm2 list

# 查看日志
pm2 logs

# 保存配置
pm2 save

# 设置开机自启
pm2 startup
```



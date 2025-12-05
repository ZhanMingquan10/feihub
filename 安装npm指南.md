# 安装 npm 指南

## 问题
Node.js 已安装，但 npm 未安装。

## 解决方案

### 方法一：使用 apt 安装（推荐）
在宝塔终端执行：
```bash
apt update
apt install npm -y
```

### 方法二：使用 Node.js 版本管理器（如果已安装）
如果在宝塔面板中安装了 "Node.js版本管理器"：
1. 在宝塔面板，点击"软件商店"
2. 找到"Node.js版本管理器"
3. 点击"设置"
4. 确保 Node.js 18.x 已安装（npm 会随 Node.js 一起安装）

### 方法三：重新安装 Node.js（包含 npm）
如果上述方法不行，可以：
1. 在宝塔面板，软件商店中卸载当前的 Node.js
2. 重新安装 "Node.js版本管理器"
3. 安装 Node.js 18.x（会自动包含 npm）

## 验证安装
安装完成后，执行：
```bash
npm -v
```
应该显示版本号（如 `9.x.x` 或 `10.x.x`）



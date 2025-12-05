# 修复 TypeScript 构建问题

## 问题说明

错误：`tsc: command not found`

这是因为之前使用了 `npm install --production`，跳过了开发依赖（devDependencies），而 TypeScript 通常在开发依赖中。

---

## 🔧 解决方案

### 方法一：安装所有依赖（推荐）

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 安装所有依赖（包括开发依赖）
npm install

# 然后重新构建
npm run build
```

---

### 方法二：只安装 TypeScript（如果不想安装所有开发依赖）

```bash
cd /www/wwwroot/feihub/backend

# 安装 TypeScript
npm install --save-dev typescript

# 然后重新构建
npm run build
```

---

## 📝 说明

### 为什么需要开发依赖？

- **生产环境**：运行代码时只需要运行时依赖
- **构建时**：需要编译工具（如 TypeScript），这些在开发依赖中

### 推荐做法

1. **开发/构建时**：使用 `npm install`（安装所有依赖）
2. **生产运行时**：使用 `npm install --production`（只安装运行时依赖）

---

## 🚀 完整操作步骤

```bash
# 1. 安装所有依赖
cd /www/wwwroot/feihub/backend
npm install

# 2. 构建后端
npm run build

# 3. 启动服务
mkdir -p logs
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

---

## ✅ 成功标志

运行 `npm run build` 后，应该看到：

```
> feihub-backend@1.0.0 build
> tsc

```

没有错误信息，并且会生成 `dist/` 目录。

---

## 🆘 如果还是失败

### 检查 TypeScript 是否安装

```bash
cd /www/wwwroot/feihub/backend
npx tsc --version
```

如果显示版本号，说明已安装。

### 检查 package.json

```bash
cat package.json | grep -A 5 "devDependencies"
```

应该能看到 `typescript` 在 devDependencies 中。

---

## 🎯 下一步

安装完依赖并构建成功后，继续：
1. 启动后端服务：`pm2 start ecosystem.config.js`
2. 验证后端运行：`pm2 status`
3. 安装前端依赖：`cd .. && npm install`
4. 构建前端：`npm run build`



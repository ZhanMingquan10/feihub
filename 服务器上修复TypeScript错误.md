# 在服务器上修复 TypeScript 错误

## 🔧 快速修复方案

### 方法一：在服务器上直接修复（最快）

#### 1. 修复 tsconfig.json

在宝塔文件管理器中：
1. 进入 `/www/wwwroot/feihub/backend`
2. 编辑 `tsconfig.json`
3. 找到第 5 行：`"lib": ["ES2022"],`
4. 修改为：`"lib": ["ES2022", "DOM"],`

**修改前：**
```json
"lib": ["ES2022"],
```

**修改后：**
```json
"lib": ["ES2022", "DOM"],
```

---

#### 2. 修复 feishu-server.ts

在宝塔文件管理器中：
1. 进入 `/www/wwwroot/feihub/backend/src/lib`
2. 编辑 `feishu-server.ts`

**修改 1：** 第 1 行
- **修改前：** `import puppeteer from "puppeteer";`
- **修改后：** `import puppeteer from "puppeteer-core";`

**修改 2：** 第 67 行
- **修改前：** `page.on('request', (req) => {`
- **修改后：** `page.on('request', (req: any) => {`

**修改 3：** 第 177 行
- **修改前：** `unwanted.forEach(el => el.remove());`
- **修改后：** `unwanted.forEach((el: Element) => el.remove());`

**修改 4：** 第 188 行
- **修改前：** `unwanted.forEach(el => el.remove());`
- **修改后：** `unwanted.forEach((el: Element) => el.remove());`

---

#### 3. 修复 feishu-puppeteer.ts

在宝塔文件管理器中：
1. 进入 `/www/wwwroot/feihub/backend/src/lib`
2. 编辑 `feishu-puppeteer.ts`

**修改 1：** 第 351 行
- **修改前：** `unwanted.forEach(el => el.remove());`
- **修改后：** `unwanted.forEach((el: Element) => el.remove());`

**修改 2：** 第 417 行
- **修改前：** `unwanted.forEach(el => el.remove());`
- **修改后：** `unwanted.forEach((el: Element) => el.remove());`

---

### 方法二：从 GitHub 拉取（如果已推送）

#### 1. 在本地推送修复

在本地终端执行：

```bash
git add .
git commit -m "fix: 修复 TypeScript 编译错误"
git push
```

#### 2. 在服务器拉取

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub
git pull
```

---

## 🚀 修复后重新构建

修复完成后，在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend
npm run build
```

---

## 📝 快速修复命令（如果使用终端编辑器）

如果你想用终端编辑器快速修复，可以执行：

```bash
cd /www/wwwroot/feihub/backend

# 修复 tsconfig.json
sed -i 's/"lib": \["ES2022"\]/"lib": ["ES2022", "DOM"]/' tsconfig.json

# 修复 feishu-server.ts
sed -i 's/import puppeteer from "puppeteer";/import puppeteer from "puppeteer-core";/' src/lib/feishu-server.ts
sed -i 's/page.on('\''request'\'', (req) => {/page.on('\''request'\'', (req: any) => {/' src/lib/feishu-server.ts
sed -i 's/unwanted.forEach(el => el.remove());/unwanted.forEach((el: Element) => el.remove());/g' src/lib/feishu-server.ts

# 修复 feishu-puppeteer.ts
sed -i 's/unwanted.forEach(el => el.remove());/unwanted.forEach((el: Element) => el.remove());/g' src/lib/feishu-puppeteer.ts

# 重新构建
npm run build
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

## 🎯 推荐操作

**推荐使用方法一（在服务器上直接修复）**，因为最快。

1. 在宝塔文件管理器中修复 `tsconfig.json`
2. 修复 `feishu-server.ts` 和 `feishu-puppeteer.ts`
3. 重新构建：`npm run build`



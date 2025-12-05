# 修复 TypeScript 编译错误

## 问题说明

编译时出现以下错误：
1. `Cannot find name 'document'` - 缺少 DOM 类型
2. `Cannot find module 'puppeteer'` - 应该使用 `puppeteer-core`
3. 隐式 any 类型错误

---

## ✅ 已修复

我已经在本地修复了这些问题。你需要：

### 方法一：从 GitHub 拉取最新代码（推荐）

在服务器终端执行：

```bash
cd /www/wwwroot/feihub
git pull
```

然后重新构建：

```bash
cd backend
npm run build
```

---

### 方法二：直接在服务器上修复

如果还没有推送到 GitHub，可以在服务器上直接修复：

#### 1. 修复 tsconfig.json

在宝塔文件管理器中：
1. 进入 `/www/wwwroot/feihub/backend`
2. 编辑 `tsconfig.json`
3. 找到 `"lib": ["ES2022"],`
4. 修改为：`"lib": ["ES2022", "DOM"],`

#### 2. 修复 feishu-server.ts

在宝塔文件管理器中：
1. 进入 `/www/wwwroot/feihub/backend/src/lib`
2. 编辑 `feishu-server.ts`
3. 找到第 1 行：`import puppeteer from "puppeteer";`
4. 修改为：`import puppeteer from "puppeteer-core";`
5. 找到第 67 行：`page.on('request', (req) => {`
6. 修改为：`page.on('request', (req: any) => {`
7. 找到第 177 行和第 188 行：`unwanted.forEach(el => el.remove());`
8. 修改为：`unwanted.forEach((el: Element) => el.remove());`

#### 3. 修复 feishu-puppeteer.ts

在宝塔文件管理器中：
1. 进入 `/www/wwwroot/feihub/backend/src/lib`
2. 编辑 `feishu-puppeteer.ts`
3. 找到第 351 行和第 417 行：`unwanted.forEach(el => el.remove());`
4. 修改为：`unwanted.forEach((el: Element) => el.remove());`

---

## 🚀 重新构建

修复完成后，重新构建：

```bash
cd /www/wwwroot/feihub/backend
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

**推荐使用方法一**（从 GitHub 拉取），因为我已经在本地修复了这些问题。

1. **在本地推送修复**（如果需要）：
   ```bash
   git add .
   git commit -m "fix: 修复 TypeScript 编译错误"
   git push
   ```

2. **在服务器拉取**：
   ```bash
   cd /www/wwwroot/feihub
   git pull
   ```

3. **重新构建**：
   ```bash
   cd backend
   npm run build
   ```

---

## 📝 修复内容总结

1. ✅ `tsconfig.json` - 添加 `"DOM"` 到 `lib`
2. ✅ `feishu-server.ts` - 修复 `puppeteer` 导入为 `puppeteer-core`
3. ✅ `feishu-server.ts` - 添加类型注解
4. ✅ `feishu-puppeteer.ts` - 添加类型注解



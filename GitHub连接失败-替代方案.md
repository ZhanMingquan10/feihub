# GitHub 连接失败 - 替代方案

## 问题说明

错误：`Failed to connect to github.com port 443`

这是因为服务器无法连接到 GitHub（可能是网络问题或被墙）。

---

## 🔧 解决方案

### 方案一：直接在服务器上修复文件（推荐，最快）

由于修改内容较多，我提供一个**简化的修复脚本**，可以一次性修复所有问题。

---

## 🚀 快速修复脚本

在宝塔终端执行以下命令（**一次性修复所有问题**）：

```bash
cd /www/wwwroot/feihub/backend

# 1. 修复 tsconfig.json（添加 DOM 类型）
sed -i 's/"lib": \["ES2022"\]/"lib": ["ES2022", "DOM"]/' tsconfig.json

# 2. 修复 feishu-server.ts
# 修复导入
sed -i 's/import puppeteer from "puppeteer";/import puppeteer from "puppeteer-core";/' src/lib/feishu-server.ts

# 修复 waitForTimeout
sed -i 's/await page.waitForTimeout(5000);/await new Promise(resolve => setTimeout(resolve, 5000));/' src/lib/feishu-server.ts

# 修复类型转换（titleEl）
sed -i 's/const titleEl = document.querySelector('\''.wiki-title, .doc-title, .title'\'');/const titleEl = document.querySelector('\''.wiki-title, .doc-title, .title'\'') as HTMLElement | null;/' src/lib/feishu-server.ts

# 修复类型转换（authorEl）
sed -i 's/const authorEl = document.querySelector('\''\[data-author\], .author, .doc-author'\'');/const authorEl = document.querySelector('\''\[data-author\], .author, .doc-author'\'') as HTMLElement | null;/' src/lib/feishu-server.ts

# 修复 forEach 类型
sed -i 's/unwanted.forEach(el => el.remove());/unwanted.forEach((el: Element) => el.remove());/g' src/lib/feishu-server.ts

# 3. 修复 feishu-puppeteer.ts
# 修复 element 类型
sed -i '126s/const element = document.querySelector(selector);/const element = document.querySelector(selector) as HTMLElement | null;/' src/lib/feishu-puppeteer.ts

# 修复 titleEl 类型
sed -i '197s/const titleEl = document.querySelector/const titleEl = document.querySelector/' src/lib/feishu-puppeteer.ts
sed -i '197s/);/') as HTMLElement | null;/' src/lib/feishu-puppeteer.ts

# 修复 timeEl 类型
sed -i '235s/const timeEl = document.querySelector(selector);/const timeEl = document.querySelector(selector) as HTMLElement | null;/' src/lib/feishu-puppeteer.ts

# 修复 clone 类型
sed -i 's/const clone = element.cloneNode(true);/const clone = element.cloneNode(true) as HTMLElement;/' src/lib/feishu-puppeteer.ts

# 修复 body 类型
sed -i 's/const body = document.body.cloneNode(true);/const body = document.body.cloneNode(true) as HTMLElement;/' src/lib/feishu-puppeteer.ts

# 修复 forEach 类型
sed -i 's/unwanted.forEach(el => el.remove());/unwanted.forEach((el: Element) => el.remove());/g' src/lib/feishu-puppeteer.ts

# 4. 重新构建
npm run build
```

---

## 📝 手动修复（如果脚本失败）

如果上面的脚本执行失败，可以手动在宝塔文件管理器中修复：

### 1. 修复 tsconfig.json

文件：`/www/wwwroot/feihub/backend/tsconfig.json`

找到第 5 行：
```json
"lib": ["ES2022"],
```

修改为：
```json
"lib": ["ES2022", "DOM"],
```

---

### 2. 修复 feishu-server.ts

文件：`/www/wwwroot/feihub/backend/src/lib/feishu-server.ts`

**修改 1：** 第 1 行
- 修改为：`import puppeteer from "puppeteer-core";`

**修改 2：** 第 86 行
- 修改为：`await new Promise(resolve => setTimeout(resolve, 5000));`

**修改 3：** 第 108-109 行
- 修改为：
```typescript
const titleEl = document.querySelector('.wiki-title, .doc-title, .title') as HTMLElement | null;
if (titleEl) return titleEl.innerText.trim();
```

**修改 4：** 第 140-141 行
- 修改为：
```typescript
const authorEl = document.querySelector('[data-author], .author, .doc-author') as HTMLElement | null;
if (authorEl) return authorEl.innerText.trim() || authorEl.getAttribute('data-author') || '';
```

**修改 5：** 第 177 行和第 188 行
- 修改为：`unwanted.forEach((el: Element) => el.remove());`

---

### 3. 修复 feishu-puppeteer.ts

文件：`/www/wwwroot/feihub/backend/src/lib/feishu-puppeteer.ts`

**修改 1：** 第 126-128 行
- 修改为：
```typescript
const element = document.querySelector(selector) as HTMLElement | null;
if (element) {
  const text = element.innerText || element.textContent || '';
```

**修改 2：** 第 197-199 行
- 修改为：
```typescript
const titleEl = document.querySelector('.wiki-title, .doc-title, .title, [class*="title"]') as HTMLElement | null;
if (titleEl) {
  const titleText = titleEl.innerText || titleEl.textContent || '';
```

**修改 3：** 第 235-237 行
- 修改为：
```typescript
const timeEl = document.querySelector(selector) as HTMLElement | null;
if (timeEl) {
  const timeText = timeEl.innerText || timeEl.textContent ||
```

**修改 4：** 第 336 行
- 修改为：`const clone = element.cloneNode(true) as HTMLElement;`

**修改 5：** 第 415-417 行
- 修改为：
```typescript
const body = document.body.cloneNode(true) as HTMLElement;
const unwanted = body.querySelectorAll('script, style, iframe, noscript, nav, header, footer, .sidebar, .menu, h1, .title, .author, .user-name, .header, .footer, [class*="header"], [class*="footer"], [class*="image"], [class*="attachment"], [class*="media"], [class*="comment"], [class*="Comment"], [class*="highlight"], [class*="Highlight"], [class*="annotation"], [class*="Annotation"], button, .button, [role="button"], [class*="action"], [class*="Action"], img, picture, video, audio');
unwanted.forEach((el: Element) => el.remove());
```

**修改 6：** 第 351 行和第 417 行
- 修改为：`unwanted.forEach((el: Element) => el.remove());`

---

## ✅ 验证修复

修复完成后，重新构建：

```bash
cd /www/wwwroot/feihub/backend
npm run build
```

**成功标志**：没有错误信息，生成 `dist/` 目录。

---

## 🎯 推荐操作

**推荐使用快速修复脚本**（方案一），因为可以一次性修复所有问题。

如果脚本执行失败，再使用手动修复方法。

执行后告诉我结果，我们继续。



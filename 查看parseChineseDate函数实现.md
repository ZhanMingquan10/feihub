# 查看 parseChineseDate 函数实现

## 🔍 在服务器上执行

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend/src/lib

# 查找 parseChineseDate 函数
grep -n "parseChineseDate" feishu-puppeteer.ts

# 查看 parseChineseDate 函数的完整实现（通常在 700-800 行）
grep -A 80 "function parseChineseDate\|const parseChineseDate" feishu-puppeteer.ts | head -100
```

---

或者直接查看函数定义的行号附近：

```bash
# 找到函数定义的行号
grep -n "function parseChineseDate" feishu-puppeteer.ts

# 查看该行附近的代码（假设在 732 行）
sed -n '732,800p' feishu-puppeteer.ts
```

---

请把结果发给我，我会修复 "X月X日" 格式的日期解析问题。


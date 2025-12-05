# 查看 parseChineseDate 调用位置

## 🔍 在服务器上执行

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend/src/lib

# 查找 parseChineseDate 调用的位置和上下文
grep -n "parseChineseDate" feishu-puppeteer.ts

# 查看调用 parseChineseDate 的完整上下文（前后10行）
grep -B 10 -A 10 "parseChineseDate" feishu-puppeteer.ts | head -30
```

---

请把结果发给我，我会提供精确的修复方案。


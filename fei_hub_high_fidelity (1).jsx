import React, { useState } from "react";
import { motion } from "framer-motion";

export default function FeiHubHighFidelity() {
  const isLoggedIn = false;

  const documents = [
    {
      title: "手把手教你用 N8N 做定时推送的自动化工作流",
      author: "AI 卷王龙哥",
      date: "2025-09-11",
      views: 9821,
      tags: ["自动化", "N8N"],
      preview: "深入解析 N8N 从零搭建流程的方法，包含定时任务、资讯抓取与自动邮件发送…",
    },
    {
      title: "小红书蓝海流量：用虚拟资料跑通被动收入闭环（实战分享）",
      author: "更绪",
      date: "2024-11-11",
      views: 7211,
      tags: ["小红书", "变现"],
      preview: "基于小红书搜索流量的变现路径，从测试到闭环的完整经验…",
    },
    {
      title: "如何从 0-1 搭建个人知识库（含模板）",
      author: "阿远",
      date: "2025-02-19",
      views: 5500,
      tags: ["知识库", "效率"],
      preview: "完整讲解如何搭建可持续迭代的个人知识管理系统…",
    },
    {
      title: "AI 自动化提升 10 倍效率的 12 个案例",
      author: "程一",
      date: "2025-01-02",
      views: 11300,
      tags: ["AI", "自动化"],
      preview: "精选 12 个真实 AI 自动化案例，覆盖 SOP、内容、客服与数据处理…",
    },
    {
      title: "2025 年最全 Notion 工作流合集",
      author: "Mia",
      date: "2025-03-01",
      views: 4900,
      tags: ["Notion", "模板"],
      preview: "包含 40+ Notion 工作流模板，覆盖学习、管理、记录、创作…",
    },
    {
      title: "如何用 Feishu API 构建内部系统",
      author: "云雀",
      date: "2024-12-10",
      views: 3200,
      tags: ["飞书", "API"],
      preview: "利用 Feishu API 搭建内部审批、自动化、机器人系统的完整思路…",
    },
    {
      title: "增长黑客：AARRR 模型在飞书环境下的使用指南",
      author: "Lily",
      date: "2025-03-11",
      views: 8900,
      tags: ["增长", "AARRR"],
      preview: "结合实际案例拆解如何用飞书文档提升留存、转化与引导率…",
    },
    {
      title: "效率神器：如何用自动化升级你的工作流",
      author: "Neo",
      date: "2025-02-10",
      views: 7600,
      tags: ["效率", "自动化"],
      preview: "从邮件、汇报、排期到备份，全面讲解工作流自动化的方法…",
    },
    {
      title: "飞书多维表格进阶技巧（含演示）",
      author: "Timo",
      date: "2024-12-22",
      views: 6100,
      tags: ["飞书", "表格"],
      preview: "进阶使用方法：多维表格关联、自动化、筛选器与视图设计…",
    },
    {
      title: "2025 新媒体选题与爆文写作指南",
      author: "Kara",
      date: "2025-01-28",
      views: 10200,
      tags: ["内容", "新媒体"],
      preview: "详细拆解选题方法、爆文框架、数据分析与执行 SOP…",
    },
  ];

  const [sortType, setSortType] = useState("date");

  const sortedDocs = [...documents].sort((a, b) => {
    if (sortType === "views") return b.views - a.views;
    return new Date(b.date) - new Date(a.date);
  });

  return (
    <div className="min-h-screen bg-gradient-to-b from-white via-gray-100 to-gray-200 text-black font-sans flex flex-col relative overflow-hidden">
      <header className="w-full flex items-center justify-between px-8 md:px-20 py-6 backdrop-blur-xl bg-white/40 border-b border-white/50 sticky top-0 z-30 shadow-sm">
        <div className="text-3xl font-semibold tracking-tight select-none">FeiHub</div>

        {isLoggedIn ? (
          <button className="px-5 py-2 rounded-full border border-gray-300 hover:bg-gray-100 transition">登出</button>
        ) : (
          <button className="px-5 py-2 rounded-full border border-gray-300 hover:bg-gray-100 transition">登录</button>
        )}
      </header>

      {/* Hero */}
      <section className="relative w-full px-6 md:px-20 pt-20 pb-12 flex flex-col items-center text-center overflow-hidden">
        <motion.h1 className="text-5xl md:text-6xl font-semibold tracking-tight mb-4">
          FeiHub
        </motion.h1>
        <motion.p className="text-gray-700 text-xl md:text-2xl font-light max-w-xl mb-10">
          让知识被看见
        </motion.p>

        <div className="w-full max-w-2xl mb-4">
          <input
            placeholder="搜索飞书文档..."
            className="w-full border border-white/40 bg-white/70 backdrop-blur-2xl shadow-xl rounded-3xl px-6 py-4 text-lg focus:outline-none focus:ring-4 focus:ring-black/10 transition"
          />
        </div>
      </section>

      {/* Sort */}
      <div className="w-full max-w-6xl mx-auto px-6 md:px-20 mb-4 flex gap-4 text-sm">
        <button
          onClick={() => setSortType("date")}
          className={`px-4 py-2 rounded-full border ${
            sortType === "date" ? "bg-black text-white" : "bg-white/80"
          }`}
        >
          按时间排序
        </button>
        <button
          onClick={() => setSortType("views")}
          className={`px-4 py-2 rounded-full border ${
            sortType === "views" ? "bg-black text-white" : "bg-white/80"
          }`}
        >
          按热度排序
        </button>
      </div>

      {/* Document List */}
      <section className="flex-1 w-full max-w-6xl mx-auto px-6 md:px-20 pb-24 flex flex-col gap-5">
        {sortedDocs.map((item, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            className="w-full bg-white/80 backdrop-blur-xl border border-white rounded-2xl p-5 shadow-md hover:shadow-xl transition relative"
          >
            {/* View badge */}
            <div className="absolute top-3 right-4 bg-black text-white text-xs px-3 py-1 rounded-full opacity-90">
              {item.views.toLocaleString()} 次查看
            </div>

            <div className="text-xl font-medium leading-snug">{item.title}</div>
            <div className="text-sm text-gray-600 mt-1">{item.author} · 更新于 {item.date}</div>
            <div className="text-sm text-gray-700 mt-3 line-clamp-2">{item.preview}</div>

            <div className="flex gap-2 mt-4">
              {item.tags.map((t) => (
                <span key={t} className="px-3 py-1 text-xs bg-gray-100 rounded-full border">
                  {t}
                </span>
              ))}
            </div>
          </motion.div>
        ))}
      </section>

      {/* Upload Button */}
      <button className="fixed bottom-8 right-8 bg-black text-white px-6 py-3 text-sm md:text-base rounded-full shadow-xl hover:bg-gray-800 transition">
        分享文档
      </button>
    </div>
  );
}

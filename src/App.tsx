import { useMemo, useState, useEffect } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Upload, Search, Eye, Moon, Sun, FileText, Activity, MessageCircle, Share2, ArrowUp } from "lucide-react";
import dayjs from "dayjs";
import clsx from "clsx";
// 移除静态热搜词导入，改为动态获取
import { useAntiScrapeShield } from "./hooks/useAntiScrapeShield";
import { useDocumentStore } from "./store/useDocumentStore";
import type { FeishuDocument, SortType } from "./types";
import { ModalShell } from "./components/ModalShell";
import { highlightKeyword, renderHighlightedText } from "./utils/highlightKeyword";
import { formatDateForFeishu } from "./utils/formatDate";

export default function App() {
  const { docs, search, sort, setSearch, setSort, loadDocuments, uploadDoc } = useDocumentStore();
  
  // 前端过滤和排序（后端已做，这里做二次过滤）
  // 同时排除处理中的临时文档
  const filteredDocs = useMemo(() => {
    return docs
      .filter((doc) => {
        // 排除处理中的临时文档
        if (doc.title === "内容正在联网获取...") {
          return false;
        }
        // 搜索过滤
        if (!search) return true;
        const tagsStr = doc.tags && Array.isArray(doc.tags) ? doc.tags.join(",") : "";
        const haystack = `${doc.title || ""}${doc.preview || ""}${tagsStr}`.toLowerCase();
        return haystack.includes(search.toLowerCase());
      })
      .sort((a, b) => {
        if (sort === "views") return b.views - a.views;
        return new Date(b.date).valueOf() - new Date(a.date).valueOf();
      });
  }, [docs, search, sort]);
  const [showUpload, setShowUpload] = useState(false);
  const [showAIRead, setShowAIRead] = useState(true);
  const [displayedCount, setDisplayedCount] = useState(10);
  const [isDarkMode, setIsDarkMode] = useState(true);
  const [uploadLoading, setUploadLoading] = useState(false);
  const [uploadMessage, setUploadMessage] = useState<string | null>(null);
  const [totalViews, setTotalViews] = useState(0); // 全站总查看次数
  const [showCustomerService, setShowCustomerService] = useState(false); // 客服弹窗
  const [hotKeywords, setHotKeywords] = useState<string[]>([]); // 动态热搜词，初始为空
  const [copied, setCopied] = useState(false); // 是否已复制微信号
  const [isScrolled, setIsScrolled] = useState(false); // 滚动状态，用于分享按钮折叠
  useAntiScrapeShield();

  // 加载全站统计信息
  const loadStats = async () => {
    try {
      const { getStats } = await import("./lib/api");
      const response = await getStats();
      if (response.success && response.data) {
        setTotalViews(response.data.totalViews || 0);
      }
    } catch (error) {
      console.error("加载统计信息失败:", error);
    }
  };

  // 加载热门关键词
  const loadHotKeywords = async () => {
    try {
      console.log("[前端] ========== 开始加载热门关键词 ==========");
      console.log("[前端] 当前文档数量:", docs.length);
      const { getHotKeywords } = await import("./lib/api");
      const response = await getHotKeywords();
      console.log("[前端] API响应:", response);
      console.log("[前端] response.success:", response?.success);
      console.log("[前端] response.data:", response?.data);
      console.log("[前端] response.data类型:", typeof response?.data);
      console.log("[前端] response.data是否为数组:", Array.isArray(response?.data));
      
      if (response) {
        // 检查响应格式
        if (response.success === true && Array.isArray(response.data)) {
          const keywords = response.data.filter(k => k && k.trim().length > 0);
          console.log("[前端] ✅ 成功获取热门关键词:", keywords);
          console.log("[前端] 关键词数量:", keywords.length);
          setHotKeywords(keywords);
        } else if (response.success === false) {
          console.warn("[前端] ⚠️ API返回失败:", response.error);
          setHotKeywords([]);
        } else if (Array.isArray(response.data)) {
          // 兼容直接返回数组的情况
          const keywords = response.data.filter(k => k && k.trim().length > 0);
          console.log("[前端] ✅ 兼容格式获取热门关键词:", keywords);
          setHotKeywords(keywords);
        } else {
          console.warn("[前端] ⚠️ 数据格式不正确:", response);
          setHotKeywords([]);
        }
      } else {
        console.warn("[前端] ⚠️ 响应为空");
        setHotKeywords([]);
      }
      console.log("[前端] ========== 热门关键词加载完成 ==========");
    } catch (error) {
      console.error("[前端] ❌ 加载热门关键词异常:", error);
      setHotKeywords([]);
    }
  };

  // 初始化加载文档、统计信息和热门关键词
  useEffect(() => {
    const init = async () => {
      console.log("[前端] ========== 开始初始化 ==========");
      await loadDocuments();
      await loadStats();
      // 等待文档加载完成后再加载热门关键词
      setTimeout(() => {
        console.log("[前端] 初始化时加载热门关键词");
        loadHotKeywords();
      }, 1000);
    };
    init();
  }, [loadDocuments]);
  
  // 当文档列表更新时，重新加载热门关键词
  useEffect(() => {
    console.log("[前端] 文档列表已更新，文档数量:", docs.length);
    // 延迟加载，确保文档数据已完全加载
    const timer = setTimeout(() => {
      loadHotKeywords();
    }, 1000);
    return () => clearTimeout(timer);
  }, [docs.length]);

  // 监听文档更新事件，定期刷新热门关键词
  useEffect(() => {
    const handleRefresh = () => {
      console.log("[前端] 收到刷新热门关键词事件");
      loadHotKeywords();
    };
    
    window.addEventListener('refreshHotKeywords', handleRefresh);
    
    // 定期刷新热门关键词（每30秒），确保数据实时更新
    const interval = setInterval(() => {
      console.log("[前端] 定期刷新热门关键词");
      loadHotKeywords();
    }, 30000);
    
    return () => {
      window.removeEventListener('refreshHotKeywords', handleRefresh);
      clearInterval(interval);
    };
  }, []);

  useEffect(() => {
    setDisplayedCount(10);
  }, [search, sort]);

  useEffect(() => {
    const handleScroll = () => {
      const scrollTop = window.scrollY || document.documentElement.scrollTop;
      const windowHeight = window.innerHeight;
      const documentHeight = document.documentElement.scrollHeight;

      if (scrollTop + windowHeight >= documentHeight - 100 && displayedCount < filteredDocs.length) {
        setDisplayedCount((prev) => Math.min(prev + 10, filteredDocs.length));
      }
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, [filteredDocs.length, displayedCount]);

  // 监听滚动，实现分享按钮折叠效果
  useEffect(() => {
    const handleScrollForButton = () => {
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop || window.scrollY;
      setIsScrolled(scrollTop > 50);
    };

    window.addEventListener("scroll", handleScrollForButton);
    handleScrollForButton(); // 初始检查
    return () => window.removeEventListener("scroll", handleScrollForButton);
  }, []);

  const handleUpload = async (link: string) => {
    setUploadLoading(true);
    setUploadMessage(null);
    try {
      const result = await uploadDoc(link);
      if (result.success) {
        setUploadMessage(result.message || "感谢您的分享，AI处理中，预计需要几分钟...");
        setTimeout(() => {
          setShowUpload(false);
          setUploadMessage(null);
        }, 2000);
      } else {
        setUploadMessage(result.error || "提交失败，请重试");
      }
    } catch (error: any) {
      setUploadMessage(error.message || "提交失败");
    } finally {
      setUploadLoading(false);
    }
  };

  return (
    <div className={clsx("min-h-screen transition-colors duration-300", isDarkMode ? "bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 text-gray-100" : "bg-gradient-to-br from-gray-100 via-gray-50 to-gray-100 text-carbon")}>
      <header className={clsx("sticky top-0 z-40 w-full backdrop-blur-xl transition-colors duration-300", isDarkMode ? "bg-gray-950/95" : "bg-gray-100/95")}>
        <div className="mx-auto flex max-w-6xl items-center justify-between px-3 py-2 md:px-8 md:py-4">
          <div className="flex flex-col items-start">
            <p className={clsx("text-lg md:text-2xl font-semibold tracking-tight", isDarkMode ? "text-gray-100" : "text-gray-900")}>FeiHub</p>
            <p className={clsx("text-[10px] md:text-xs uppercase tracking-[0.3em]", isDarkMode ? "text-gray-400" : "text-gray-500")}>分享让知识被看见</p>
          </div>

          <div className="flex items-center gap-2 md:gap-3">
            <span className={clsx("text-[10px] md:text-xs font-bold uppercase tracking-[0.05em] md:tracking-[0.3em] bg-gradient-to-r bg-clip-text text-transparent", isDarkMode ? "from-cyan-400 via-blue-400 to-indigo-400 drop-shadow-[0_0_8px_rgba(96,165,250,0.6)]" : "from-blue-600 via-indigo-600 to-purple-600")}>
              AI速读
            </span>
            <button
              onClick={() => setShowCustomerService(true)}
              className={clsx("flex items-center justify-center rounded-full border w-8 h-8 md:w-10 md:h-10 transition-all duration-300 hover:scale-110", isDarkMode ? "border-gray-600 bg-gray-800/80 text-blue-400 hover:border-blue-500/50 hover:bg-blue-500/10 hover:shadow-[0_0_20px_rgba(96,165,250,0.3)]" : "border-gray-300 bg-white text-blue-600 hover:border-blue-400 hover:bg-blue-50 hover:shadow-lg")}
              title="联系客服"
            >
              <MessageCircle size={14} className="md:w-[18px] md:h-[18px]" />
            </button>
            <button
              onClick={() => setIsDarkMode(!isDarkMode)}
              className={clsx("flex items-center justify-center rounded-full border w-8 h-8 md:w-10 md:h-10 transition-all duration-300 hover:scale-110", isDarkMode ? "border-gray-600 bg-gray-800/80 text-yellow-400 hover:border-yellow-500/50 hover:bg-yellow-500/10 hover:shadow-[0_0_20px_rgba(250,204,21,0.3)]" : "border-gray-300 bg-white text-gray-700 hover:border-gray-400 hover:bg-gray-50 hover:shadow-lg")}
              title={isDarkMode ? "切换到浅色样式" : "切换到深色样式"}
            >
              {isDarkMode ? <Sun size={14} className="md:w-[18px] md:h-[18px]" /> : <Moon size={14} className="md:w-[18px] md:h-[18px]" />}
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 md:gap-6 px-4 pb-28 pt-3 md:pt-8 md:px-8">
        <section className={clsx("relative overflow-hidden rounded-3xl border-2 p-4 md:p-8 text-center shadow-glass transition-colors duration-300", isDarkMode ? "border-gray-500/60 bg-gray-700 shadow-2xl" : "border-gray-200 bg-white shadow-2xl")}>
          <motion.h1 layout className={clsx("relative inline-block text-2xl md:text-4xl font-semibold md:text-5xl", isDarkMode ? "text-gray-100" : "text-gray-900")}>
            分享让知识被看见
          </motion.h1>
          <div className={clsx("mt-6 flex flex-wrap items-center justify-center gap-8 text-xs", isDarkMode ? "text-gray-400" : "text-gray-500")}>
            <span className={clsx("font-medium whitespace-nowrap", isDarkMode ? "text-gray-300" : "text-gray-700")}>
              {docs.length.toLocaleString()}篇文章
            </span>
            <span className={clsx("font-medium whitespace-nowrap", isDarkMode ? "text-gray-300" : "text-gray-700")}>
              {totalViews.toLocaleString()}次查看
            </span>
            <span className={clsx("font-medium whitespace-nowrap", isDarkMode ? "text-gray-300" : "text-gray-700")}>
              {Math.floor(dayjs().diff(dayjs("2025-11-27"), "day"))}天运行
            </span>
          </div>
          <div className="mt-6 md:mt-8 flex flex-col gap-3 md:flex-row">
            <div className={clsx("mx-auto w-full max-w-3xl rounded-full border-2 px-3 py-1.5 md:px-6 md:py-3 transition-all duration-300", isDarkMode ? "border-gray-500/60 bg-gray-800/90 shadow-[0_8px_20px_rgba(0,0,0,0.3)] focus-within:border-blue-500/60 focus-within:shadow-[0_10px_25px_rgba(59,130,246,0.25)] focus-within:ring-2 focus-within:ring-blue-500/20" : "border-gray-200 bg-white shadow-[0_8px_20px_rgba(0,0,0,0.1)] focus-within:border-blue-500 focus-within:shadow-[0_10px_25px_rgba(59,130,246,0.25)] focus-within:ring-2 focus-within:ring-blue-500/40")}>
              <div className={clsx("flex items-center gap-2 md:gap-3", isDarkMode ? "text-gray-400" : "text-gray-600")}>
                <Search size={14} className="md:w-4 md:h-4" />
                <input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="搜索文档 / 关键词..."
                  className={clsx("w-full border-none bg-transparent text-sm md:text-base outline-none", isDarkMode ? "text-gray-100 placeholder:text-gray-500" : "text-gray-900 placeholder:text-gray-400")}
                />
              </div>
            </div>
          </div>

          {/* 热搜词展示 */}
          {hotKeywords && hotKeywords.length > 0 && (
            <div className={clsx("mt-4 md:mt-6 flex flex-nowrap items-center justify-center gap-2 md:flex-wrap md:gap-3 overflow-x-auto text-xs", isDarkMode ? "text-gray-400" : "text-gray-500")}>
              <span className={clsx("flex-shrink-0", isDarkMode ? "text-gray-500" : "text-gray-400")}>热搜：</span>
              {hotKeywords.slice(0, 6).map((keyword, index) => (
                <button
                  key={keyword}
                  className={clsx(
                    "rounded-full border-2 px-3 py-1 transition flex-shrink-0",
                    // 移动端只显示前3个，PC端显示全部6个
                    index >= 3 ? "hidden md:inline-flex" : "",
                    search === keyword
                      ? isDarkMode
                        ? "border-blue-500 bg-blue-500/20 text-blue-300"
                        : "border-blue-500 bg-blue-50 text-blue-600"
                      : isDarkMode
                      ? "border-gray-500/80 text-gray-300 bg-gray-800/50 hover:border-gray-400 hover:text-gray-100 hover:bg-gray-800/60"
                      : "border-gray-200 text-gray-500 hover:border-gray-300 hover:text-gray-700 hover:bg-gray-50"
                  )}
                  onClick={() => {
                    // 如果当前已选中该热搜词，再次点击则取消选中
                    if (search === keyword) {
                      setSearch("");
                    } else {
                      setSearch(keyword);
                      // 滚动到文档列表区域
                      setTimeout(() => {
                        const docListSection = document.querySelector('section[class*="grid"]');
                        if (docListSection) {
                          docListSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
                        }
                      }, 100);
                    }
                  }}
                >
                  {keyword}
                </button>
              ))}
            </div>
          )}
        </section>

        <section className="flex flex-wrap gap-2 md:gap-3 text-[10px] md:text-xs">
          {(["latest", "views"] as SortType[]).map((type) => (
            <button
              key={type}
              onClick={() => setSort(type)}
              className={clsx(
                "rounded-full border-2 px-1.5 py-1 md:px-3 md:py-1.5 capitalize transition-all duration-200 font-medium",
                sort === type
                  ? isDarkMode
                    ? "bg-blue-600 text-white border-blue-500 shadow-[0_0_20px_rgba(59,130,246,0.5)] scale-105"
                    : "bg-blue-600 text-white border-blue-500 shadow-lg scale-105"
                  : isDarkMode
                  ? "bg-gray-800/80 text-gray-400 border-gray-600 hover:border-gray-500 hover:text-gray-200 hover:bg-gray-700/80"
                  : "bg-white text-gray-600 border-gray-200 hover:border-gray-300 hover:text-gray-800 hover:bg-gray-50 shadow-sm"
              )}
            >
              {type === "latest" ? "最新发布" : "最多查看"}
            </button>
          ))}
          <button
            onClick={() => setShowAIRead(!showAIRead)}
            className={clsx(
              "rounded-full border-2 px-1.5 py-1 md:px-3 md:py-1.5 transition-all duration-200 font-medium",
              showAIRead
                ? isDarkMode
                  ? "bg-blue-600 text-white border-blue-500 shadow-[0_0_20px_rgba(59,130,246,0.5)] scale-105"
                  : "bg-blue-600 text-white border-blue-500 shadow-lg scale-105"
                : isDarkMode
                ? "bg-gray-800/80 text-gray-400 border-gray-600 hover:border-gray-500 hover:text-gray-200 hover:bg-gray-700/80"
                  : "bg-white text-gray-600 border-gray-200 hover:border-gray-300 hover:text-gray-800 hover:bg-gray-50 shadow-sm"
            )}
          >
            AI速读
          </button>
        </section>

        <section className="grid gap-4">
          {filteredDocs.slice(0, displayedCount).map((doc) => {
            return (
            <motion.a
              key={doc.id}
              layout
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              href={doc.link}
              target="_blank"
              rel="noreferrer"
              onClick={async (e) => {
                // 增加查看次数
                try {
                  const { incrementDocumentViews } = await import("./lib/api");
                  await incrementDocumentViews(doc.id);
                  // 更新本地状态
                  loadDocuments();
                  loadStats();
                  // 查看次数更新后，重新加载热门关键词（因为热度计算包含查看次数）
                  loadHotKeywords();
                } catch (error) {
                  console.error("增加查看次数失败:", error);
                }
              }}
              className={clsx(
                "relative block overflow-hidden rounded-3xl border-2 p-4 md:p-6 shadow-glass transition-all duration-300 hover:shadow-2xl hover:-translate-y-1",
                isDarkMode 
                  ? "border-gray-500/60 bg-gray-700 shadow-xl" 
                  : "border-gray-200 bg-white shadow-xl"
              )}
            >
              <div className={clsx("absolute right-3 top-3 md:right-5 md:top-5 flex items-center gap-1 rounded-full px-2 py-0.5 md:px-3 md:py-1 text-[10px] md:text-xs z-10 backdrop-blur-sm", isDarkMode ? "bg-gray-800/90 border border-gray-600/50 text-gray-200 shadow-lg" : "bg-gray-100 border border-gray-200 text-gray-500 shadow-sm")}>
                <Eye size={12} className="md:w-3.5 md:h-3.5" />
                {doc.views.toLocaleString()}
              </div>
              <div className={clsx("flex items-start gap-2 pr-16 md:pr-20", isDarkMode ? "text-gray-100" : "text-gray-900")}>
                <h2 className={clsx("text-lg md:text-2xl font-medium line-clamp-2 break-words flex-1 overflow-hidden", isDarkMode ? "text-gray-100" : "text-gray-900")}>
                  {search ? renderHighlightedText(highlightKeyword(doc.title, search), isDarkMode) : doc.title}
                </h2>
              </div>
              <div className={clsx("mt-2 text-sm", isDarkMode ? "text-gray-400" : "text-gray-500")}>
                {`更新于 ${formatDateForFeishu(doc.date)}`}
              </div>
              <div className="mt-2 flex flex-wrap items-center gap-2">
                {doc.tags && doc.tags.length > 0 ? (
                  doc.tags.map((tag) => {
                    const tagHighlighted = search ? highlightKeyword(tag, search) : null;
                    return (
                      <span key={tag} className={clsx("rounded-full border-2 px-3 py-1 text-xs font-medium transition-all duration-200 hover:scale-105", isDarkMode ? "border-blue-500/60 bg-blue-500/20 text-blue-300 shadow-[0_0_15px_rgba(59,130,246,0.3)]" : "border-blue-500 bg-gradient-to-r from-blue-100 to-indigo-100 text-blue-700 shadow-[0_0_12px_rgba(59,130,246,0.25)] font-semibold")}>
                        {search && tagHighlighted ? renderHighlightedText(tagHighlighted, isDarkMode) : tag}
                      </span>
                    );
                  })
                ) : (
                  <span className={clsx("rounded-full border px-3 py-1 text-xs animate-pulse", isDarkMode ? "border-gray-600 bg-gray-700/50 text-gray-400" : "border-gray-300 bg-gray-100 text-gray-500")}>
                    AI生成中
                  </span>
                )}
              </div>
              <div className={clsx("mt-4 text-sm whitespace-pre-wrap overflow-hidden", isDarkMode ? "text-gray-300" : "text-gray-700")} style={{ display: '-webkit-box', WebkitLineClamp: 10, WebkitBoxOrient: 'vertical', lineHeight: '1.4' }}>
                {search && doc.content ? renderHighlightedText(highlightKeyword(doc.content, search), isDarkMode) : (doc.content || "暂无内容")}
              </div>
              {showAIRead && (
                <div className={clsx("mt-4 rounded-2xl border-2 px-4 py-3 text-sm shadow-lg backdrop-blur-sm", isDarkMode ? "border-blue-500/60 bg-gradient-to-br from-blue-500/25 via-indigo-500/20 to-purple-500/25 text-gray-200 shadow-[0_0_30px_rgba(59,130,246,0.4)]" : "border-blue-500 bg-gradient-to-br from-blue-100 via-indigo-100 to-purple-100 text-gray-800 shadow-[0_0_25px_rgba(59,130,246,0.3)]")}>
                  <div className={clsx("mb-2 text-xs font-bold uppercase tracking-widest flex items-center gap-2", isDarkMode ? "text-cyan-300 drop-shadow-[0_0_8px_rgba(103,232,249,0.6)]" : "text-blue-700 drop-shadow-[0_0_6px_rgba(37,99,235,0.4)] font-extrabold")}>
                    <span className="text-base">✨</span> AI 速读
                  </div>
                  {doc.aiAngle1 && doc.aiSummary1 && doc.aiAngle2 && doc.aiSummary2 ? (
                    // 新的结构化格式
                    <div className={clsx("space-y-2 text-sm", isDarkMode ? "text-gray-300" : "text-gray-800")}>
                      <div>
                        <span className={clsx("font-bold", isDarkMode ? "text-cyan-300" : "text-blue-700 drop-shadow-[0_0_4px_rgba(37,99,235,0.3)]")}>{doc.aiAngle1}：</span>
                        <span className={clsx(isDarkMode ? "text-gray-200" : "text-gray-800 font-medium")}>{doc.aiSummary1}</span>
                      </div>
                      <div>
                        <span className={clsx("font-bold", isDarkMode ? "text-cyan-300" : "text-blue-700 drop-shadow-[0_0_4px_rgba(37,99,235,0.3)]")}>{doc.aiAngle2}：</span>
                        <span className={clsx(isDarkMode ? "text-gray-200" : "text-gray-800 font-medium")}>{doc.aiSummary2}</span>
                      </div>
                    </div>
                  ) : doc.aiSummary && doc.aiSummary.trim().length > 0 ? (
                    // 兼容旧格式
                    <p className={clsx("text-sm", isDarkMode ? "text-gray-300" : "text-gray-800")}>
                      {doc.aiSummary}
                    </p>
                  ) : (
                    <span className={clsx("italic animate-pulse", isDarkMode ? "text-gray-400" : "text-gray-500")}>AI生成中...</span>
                  )}
                </div>
              )}
            </motion.a>
            );
          })}
          {displayedCount >= filteredDocs.length && filteredDocs.length > 0 && (
            <div className={clsx("mt-8 text-center text-sm", isDarkMode ? "text-gray-400" : "text-gray-500")}>
              ——  知识没有尽头，欢迎您的分享  ——
            </div>
          )}
        </section>
      </main>

      {/* 回到顶部按钮 */}
      {isScrolled && (
        <button
          className={clsx(
            "fixed bottom-24 right-6 flex items-center justify-center rounded-full text-white shadow-2xl transition-all duration-300 hover:scale-110 hover:shadow-[0_0_30px_rgba(0,0,0,0.5)] z-50 px-3 py-3 w-12 h-12 md:w-14 md:h-14",
            isDarkMode 
              ? "bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 border border-blue-400/50" 
              : "bg-gradient-to-r from-gray-900 to-black hover:from-gray-800 hover:to-gray-900 border-2 border-gray-700 shadow-[0_0_20px_rgba(0,0,0,0.3)]"
          )}
          onClick={() => {
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          title="回到顶部"
        >
          <ArrowUp size={18} className="flex-shrink-0" />
        </button>
      )}

      {/* 分享文档按钮 */}
      <button
        className={clsx(
          "fixed bottom-6 right-6 flex items-center justify-center rounded-full text-white shadow-2xl transition-all duration-300 hover:scale-110 hover:shadow-[0_0_30px_rgba(0,0,0,0.5)] z-50",
          isDarkMode 
            ? "bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 border border-blue-400/50" 
            : "bg-gradient-to-r from-gray-900 to-black hover:from-gray-800 hover:to-gray-900 border-2 border-gray-700 shadow-[0_0_20px_rgba(0,0,0,0.3)]",
          isScrolled 
            ? "px-3 py-3 w-12 h-12 md:w-14 md:h-14 gap-0" 
            : "px-5 py-3 gap-2 w-auto h-auto"
        )}
        onClick={() => setShowUpload(true)}
        title={isScrolled ? "分享文档" : ""}
      >
        <Share2 size={isScrolled ? 18 : 16} className="flex-shrink-0" />
        <span className={clsx(
          "transition-all duration-300 whitespace-nowrap overflow-hidden",
          isScrolled ? "w-0 opacity-0" : "w-auto opacity-100"
        )}>
          分享文档
        </span>
      </button>

      <footer className={clsx("mt-12 transition-colors duration-300", isDarkMode ? "bg-gray-950" : "bg-gray-100")}>
        <div className={clsx("mx-auto flex max-w-6xl flex-col gap-4 px-4 py-10 text-xs md:flex-row md:items-center md:justify-between md:px-8", isDarkMode ? "text-gray-400" : "text-gray-500")}>
          <div>
            <p className={clsx("text-sm font-semibold", isDarkMode ? "text-gray-200" : "text-gray-800")}>FeiHub</p>
            <p className="mt-1 text-xs">分享让知识被看见 · 文档分享社区</p>
          </div>
          <div className="flex flex-wrap gap-4 text-xs">
            {["隐私条款", "服务条款", "关于我们", "产品服务", "广告合作", "社区规范"].map((item) => (
              <span key={item} className={clsx("cursor-default transition-colors", isDarkMode ? "text-gray-400 hover:text-gray-200" : "text-gray-500 hover:text-gray-800")}>
                {item}
              </span>
            ))}
          </div>
          <div className={clsx("text-xs", isDarkMode ? "text-gray-500" : "text-gray-400")}>© {new Date().getFullYear()} FeiHub. All rights reserved.</div>
        </div>
      </footer>

      <UploadModal 
        open={showUpload} 
        isDarkMode={isDarkMode} 
        loading={uploadLoading}
        message={uploadMessage}
        onClose={() => {
          setShowUpload(false);
          setUploadMessage(null);
        }} 
        onSubmit={handleUpload} 
      />
      
      {/* 客服弹窗 */}
      <ModalShell 
        open={showCustomerService} 
        title="联系客服" 
        isDarkMode={isDarkMode} 
        onClose={() => {
          setShowCustomerService(false);
          setCopied(false); // 关闭弹窗时重置复制状态
        }}
      >
        <div className="space-y-4">
          <div className="flex justify-center">
            <img 
              src="/kefu.png" 
              alt="客服二维码" 
              className="max-w-full max-h-[60vh] h-auto rounded-lg object-contain"
              onError={(e) => {
                // 如果图片加载失败，尝试使用环境变量中的链接
                const img = e.target as HTMLImageElement;
                const customerServiceImageUrl = import.meta.env.VITE_CUSTOMER_SERVICE_IMAGE_URL;
                if (customerServiceImageUrl) {
                  img.src = customerServiceImageUrl;
                } else {
                  console.error("客服图片加载失败，请检查图片路径或配置 VITE_CUSTOMER_SERVICE_IMAGE_URL");
                }
              }}
            />
          </div>
          <div className="flex justify-center">
            <motion.button
              onClick={async (e) => {
                if (copied) return; // 如果已复制，不再执行
                
                try {
                  await navigator.clipboard.writeText("starcitybro");
                  setCopied(true);
                } catch (err) {
                  console.error("复制失败:", err);
                  // 降级方案：使用传统方法
                  const textArea = document.createElement("textarea");
                  textArea.value = "starcitybro";
                  textArea.style.position = "fixed";
                  textArea.style.opacity = "0";
                  document.body.appendChild(textArea);
                  textArea.select();
                  try {
                    document.execCommand("copy");
                    setCopied(true);
                  } catch (fallbackErr) {
                    console.error("降级复制也失败:", fallbackErr);
                  }
                  document.body.removeChild(textArea);
                }
              }}
              disabled={copied}
              whileHover={copied ? {} : { scale: 1.05 }}
              whileTap={copied ? {} : { scale: 0.95 }}
              className={clsx(
                "rounded-lg border px-6 py-3 text-sm font-medium transition-colors whitespace-nowrap min-w-[140px]",
                copied
                  ? isDarkMode
                    ? "border-gray-500 bg-gray-600 text-gray-200 cursor-not-allowed"
                    : "border-gray-400 bg-gray-300 text-gray-600 cursor-not-allowed"
                  : isDarkMode
                  ? "border-gray-600 bg-gray-700 text-gray-100 hover:bg-gray-600"
                  : "border-gray-300 bg-gray-50 text-gray-700 hover:bg-gray-100"
              )}
            >
              {copied ? "已复制" : "复制微信号"}
            </motion.button>
          </div>
        </div>
      </ModalShell>
    </div>
  );
}

type UploadModalProps = {
  open: boolean;
  isDarkMode: boolean;
  loading?: boolean;
  message?: string | null;
  onClose: () => void;
  onSubmit: (link: string) => void;
};

function UploadModal({ open, isDarkMode, loading = false, message, onClose, onSubmit }: UploadModalProps) {
  const [link, setLink] = useState("");
  const [showConfetti, setShowConfetti] = useState(false);
  
  // 预生成随机值，避免每次渲染时重新计算
  const confettiData = useMemo(() => {
    return Array.from({ length: 20 }, (_, i) => {
      const angle = (i * 360) / 20;
      const distance = 100 + Math.random() * 80;
      const x = Math.cos((angle * Math.PI) / 180) * distance;
      const y = Math.sin((angle * Math.PI) / 180) * distance;
      const delay = Math.random() * 0.2;
      const duration = 1.5 + Math.random() * 0.5;
      const rotate = 360 + Math.random() * 360;
      return { x, y, delay, duration, rotate };
    });
  }, [showConfetti]);
  
  // 验证链接格式：必须是有效的 http/https URL，且长度合理
  const isValid = (() => {
    if (!link || link.trim().length === 0) return false;
    try {
      const url = new URL(link.trim());
      return (url.protocol === "http:" || url.protocol === "https:") && link.trim().length >= 10;
    } catch {
      return false;
    }
  })();

  const handleSubmit = () => {
    if (isValid && !loading) {
      onSubmit(link.trim());
      setLink("");
    }
  };

  // 当消息显示时触发撒花动画
  useEffect(() => {
    if (message) {
      // 检查是否是成功消息（不包含"失败"或"错误"）
      const isSuccessMessage = !message.includes("失败") && !message.includes("错误");
      
      if (isSuccessMessage) {
        // 延迟100ms触发，确保消息已经显示
        const showTimer = setTimeout(() => {
          setShowConfetti(true);
        }, 100);
        
        const hideTimer = setTimeout(() => {
          setShowConfetti(false);
        }, 2600);
        
        return () => {
          clearTimeout(showTimer);
          clearTimeout(hideTimer);
          setShowConfetti(false);
        };
      } else {
        setShowConfetti(false);
      }
    } else {
      setShowConfetti(false);
    }
  }, [message]);

  // 当弹窗关闭时重置动画状态
  useEffect(() => {
    if (!open) {
      setShowConfetti(false);
    }
  }, [open]);

  if (!open) return null;

  return (
    <ModalShell open title="分享文档" isDarkMode={isDarkMode} onClose={onClose}>
      <div className="space-y-4 text-sm relative">
        {/* 撒花动画 - 使用fixed定位，覆盖整个屏幕 */}
        {showConfetti && (
          <div className="fixed inset-0 pointer-events-none z-[60] flex items-center justify-center">
            {confettiData.map((data, i) => (
              <motion.div
                key={i}
                className="absolute text-3xl"
                initial={{ 
                  x: 0, 
                  y: 0, 
                  opacity: 1, 
                  scale: 1,
                  rotate: 0
                }}
                animate={{ 
                  x: data.x, 
                  y: data.y, 
                  opacity: 0, 
                  scale: 0.2,
                  rotate: data.rotate
                }}
                transition={{ 
                  duration: data.duration,
                  delay: data.delay,
                  ease: "easeOut"
                }}
                style={{
                  left: '50%',
                  top: '50%',
                }}
              >
                🎉
              </motion.div>
            ))}
          </div>
        )}
        <div>
          <label className={clsx("text-xs", isDarkMode ? "text-gray-400" : "text-gray-500")}>文档链接</label>
          <input
            value={link}
            onChange={(e) => setLink(e.target.value)}
            disabled={loading}
            className={clsx("mt-2 w-full rounded-2xl border px-4 py-3 text-sm outline-none transition-colors disabled:opacity-50", isDarkMode ? "border-gray-600/60 bg-gray-800/80 text-gray-100 placeholder:text-gray-400 focus:border-gray-500 focus:bg-gray-800" : "border-gray-200 bg-white text-gray-900 placeholder:text-gray-400 focus:border-gray-300")}
            placeholder="https://feishu.cn/docx/..."
          />
        </div>
        {message && (
          <div className={clsx("rounded-2xl px-4 py-2 text-xs relative", message.includes("成功") || message.includes("感谢") ? (isDarkMode ? "bg-green-900/30 text-green-300" : "bg-green-50 text-green-700") : (isDarkMode ? "bg-red-900/30 text-red-300" : "bg-red-50 text-red-700"))}>
            {message}
          </div>
        )}
        <button
          disabled={!isValid || loading}
          onClick={handleSubmit}
          className={clsx("w-full rounded-full py-3 text-sm text-white disabled:opacity-40 disabled:cursor-not-allowed transition-colors", isDarkMode ? "bg-blue-600 hover:bg-blue-500 disabled:hover:bg-blue-600" : "bg-black hover:bg-gray-900 disabled:hover:bg-black")}
        >
          {loading ? "提交中..." : "确定"}
        </button>
      </div>
    </ModalShell>
  );
}


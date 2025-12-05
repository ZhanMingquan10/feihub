import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useMemo, useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Upload, Search, Eye, Moon, Sun, MessageCircle } from "lucide-react";
import dayjs from "dayjs";
import clsx from "clsx";
// 移除静态热搜词导入，改为动态获取
import { useAntiScrapeShield } from "./hooks/useAntiScrapeShield";
import { useDocumentStore } from "./store/useDocumentStore";
import { ModalShell } from "./components/ModalShell";
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
            if (!search)
                return true;
            const tagsStr = doc.tags && Array.isArray(doc.tags) ? doc.tags.join(",") : "";
            const haystack = `${doc.title || ""}${doc.preview || ""}${tagsStr}`.toLowerCase();
            return haystack.includes(search.toLowerCase());
        })
            .sort((a, b) => {
            if (sort === "views")
                return b.views - a.views;
            return new Date(b.date).valueOf() - new Date(a.date).valueOf();
        });
    }, [docs, search, sort]);
    const [showUpload, setShowUpload] = useState(false);
    const [showAIRead, setShowAIRead] = useState(true);
    const [displayedCount, setDisplayedCount] = useState(10);
    const [isDarkMode, setIsDarkMode] = useState(true);
    const [uploadLoading, setUploadLoading] = useState(false);
    const [uploadMessage, setUploadMessage] = useState(null);
    const [totalViews, setTotalViews] = useState(0); // 全站总查看次数
    const [showCustomerService, setShowCustomerService] = useState(false); // 客服弹窗
    const [hotKeywords, setHotKeywords] = useState([]); // 动态热搜词，初始为空
    const [copied, setCopied] = useState(false); // 是否已复制微信号
    useAntiScrapeShield();
    // 加载全站统计信息
    const loadStats = async () => {
        try {
            const { getStats } = await import("./lib/api");
            const response = await getStats();
            if (response.success && response.data) {
                setTotalViews(response.data.totalViews || 0);
            }
        }
        catch (error) {
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
                }
                else if (response.success === false) {
                    console.warn("[前端] ⚠️ API返回失败:", response.error);
                    setHotKeywords([]);
                }
                else if (Array.isArray(response.data)) {
                    // 兼容直接返回数组的情况
                    const keywords = response.data.filter(k => k && k.trim().length > 0);
                    console.log("[前端] ✅ 兼容格式获取热门关键词:", keywords);
                    setHotKeywords(keywords);
                }
                else {
                    console.warn("[前端] ⚠️ 数据格式不正确:", response);
                    setHotKeywords([]);
                }
            }
            else {
                console.warn("[前端] ⚠️ 响应为空");
                setHotKeywords([]);
            }
            console.log("[前端] ========== 热门关键词加载完成 ==========");
        }
        catch (error) {
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
    const handleUpload = async (link) => {
        setUploadLoading(true);
        setUploadMessage(null);
        try {
            const result = await uploadDoc(link);
            if (result.success) {
                setUploadMessage(result.message || "文档已提交成功！");
                setTimeout(() => {
                    setShowUpload(false);
                    setUploadMessage(null);
                }, 2000);
            }
            else {
                setUploadMessage(result.error || "提交失败，请重试");
            }
        }
        catch (error) {
            setUploadMessage(error.message || "提交失败");
        }
        finally {
            setUploadLoading(false);
        }
    };
    return (_jsxs("div", { className: clsx("min-h-screen transition-colors duration-300", isDarkMode ? "bg-gradient-to-b from-gray-900 via-gray-800 to-gray-900 text-gray-100" : "bg-gradient-to-b from-white via-gray-50 to-gray-200 text-carbon"), children: [_jsx("header", { className: clsx("sticky top-0 z-40 w-full border-b backdrop-blur-2xl transition-colors duration-300", isDarkMode ? "border-gray-700/40 bg-gray-900/70" : "border-white/40 bg-white/70"), children: _jsxs("div", { className: "mx-auto flex max-w-6xl items-center justify-between px-4 py-4 md:px-8", children: [_jsxs("div", { className: "flex flex-col items-start", children: [_jsx("p", { className: clsx("text-2xl font-semibold tracking-tight", isDarkMode ? "text-gray-100" : "text-gray-900"), children: "FeiHub" }), _jsx("p", { className: clsx("text-xs uppercase tracking-[0.3em]", isDarkMode ? "text-gray-400" : "text-gray-500"), children: "\u5206\u4EAB\u8BA9\u77E5\u8BC6\u88AB\u770B\u89C1" })] }), _jsxs("div", { className: "flex items-center gap-3", children: [_jsxs("button", { onClick: () => setShowCustomerService(true), className: clsx("flex items-center gap-2 rounded-full border px-4 py-1.5 text-xs transition", isDarkMode ? "border-gray-700 bg-gray-800/50 text-gray-300 hover:border-gray-600 hover:text-gray-100" : "border-gray-200 text-gray-600 hover:border-gray-400 hover:text-gray-800"), title: "\u8054\u7CFB\u5BA2\u670D", children: [_jsx(MessageCircle, { size: 14 }), _jsx("span", { children: "\u5BA2\u670D" })] }), _jsxs("button", { onClick: () => setIsDarkMode(!isDarkMode), className: clsx("flex items-center gap-2 rounded-full border px-4 py-1.5 text-xs transition", isDarkMode ? "border-gray-700 bg-gray-800/50 text-gray-300 hover:border-gray-600 hover:text-gray-100" : "border-gray-200 text-gray-600 hover:border-gray-400 hover:text-gray-800"), title: isDarkMode ? "切换到浅色样式" : "切换到深色样式", children: [isDarkMode ? _jsx(Sun, { size: 14 }) : _jsx(Moon, { size: 14 }), _jsx("span", { children: isDarkMode ? "浅色" : "深色" })] })] })] }) }), _jsxs("main", { className: "mx-auto flex w-full max-w-6xl flex-col gap-10 px-4 pb-28 pt-16 md:px-8", children: [_jsxs("section", { className: clsx("relative overflow-hidden rounded-3xl border p-8 text-center shadow-glass transition-colors duration-300", isDarkMode ? "border-gray-700/60 bg-gray-800/85" : "border-white/60 bg-white/85"), children: [_jsxs(motion.h1, { layout: true, className: clsx("relative inline-block text-4xl font-semibold md:text-5xl", isDarkMode ? "text-gray-100" : "text-gray-900"), children: ["\u5206\u4EAB\u8BA9\u77E5\u8BC6\u88AB\u770B\u89C1", _jsx("span", { className: "pointer-events-none absolute -right-14 -top-4 text-xs font-bold uppercase tracking-[0.5em] bg-gradient-to-r from-sky-400 via-blue-500 to-indigo-500 bg-clip-text text-transparent drop-shadow-[0_0_10px_rgba(56,189,248,0.8)] animate-pulse", children: "AI\u901F\u8BFB" })] }), _jsxs("div", { className: clsx("mt-6 flex flex-wrap items-center justify-center gap-8 text-xs", isDarkMode ? "text-gray-400" : "text-gray-500"), children: [_jsxs("span", { className: clsx("font-medium whitespace-nowrap", isDarkMode ? "text-gray-300" : "text-gray-700"), children: [docs.length.toLocaleString(), "\u7BC7\u6587\u7AE0"] }), _jsxs("span", { className: clsx("font-medium whitespace-nowrap", isDarkMode ? "text-gray-300" : "text-gray-700"), children: [totalViews.toLocaleString(), "\u6B21\u67E5\u770B"] }), _jsxs("span", { className: clsx("font-medium whitespace-nowrap", isDarkMode ? "text-gray-300" : "text-gray-700"), children: [Math.floor(dayjs().diff(dayjs("2025-11-27"), "day")), "\u5929\u8FD0\u884C"] })] }), _jsx("div", { className: "mt-8 flex flex-col gap-3 md:flex-row", children: _jsx("div", { className: clsx("mx-auto w-full max-w-3xl rounded-full border px-6 py-3 transition", isDarkMode ? "border-gray-600/30 bg-gray-700/50 shadow-[0_20px_45px_rgba(0,0,0,0.3)] focus-within:border-gray-500/50 focus-within:shadow-[0_25px_60px_rgba(0,0,0,0.4)]" : "border-black/10 bg-white shadow-[0_20px_45px_rgba(0,0,0,0.08)] focus-within:border-black/30 focus-within:shadow-[0_25px_60px_rgba(0,0,0,0.12)]"), children: _jsxs("div", { className: clsx("flex items-center gap-3", isDarkMode ? "text-gray-400" : "text-gray-600"), children: [_jsx(Search, { size: 16 }), _jsx("input", { value: search, onChange: (e) => setSearch(e.target.value), placeholder: "\u641C\u7D22\u6587\u6863 / \u5173\u952E\u8BCD...", className: clsx("w-full border-none bg-transparent text-base outline-none", isDarkMode ? "text-gray-100 placeholder:text-gray-500" : "text-gray-900 placeholder:text-gray-400") })] }) }) }), hotKeywords && hotKeywords.length > 0 && (_jsxs("div", { className: clsx("mt-6 flex flex-wrap items-center justify-center gap-3 text-xs", isDarkMode ? "text-gray-400" : "text-gray-500"), children: [_jsx("span", { className: isDarkMode ? "text-gray-500" : "text-gray-400", children: "\u70ED\u641C\uFF1A" }), hotKeywords.map((keyword) => (_jsx("button", { className: clsx("rounded-full border px-3 py-1 transition", search === keyword
                                            ? isDarkMode
                                                ? "border-blue-500 bg-blue-500/20 text-blue-300"
                                                : "border-blue-500 bg-blue-50 text-blue-600"
                                            : isDarkMode
                                                ? "border-gray-700 text-gray-300 hover:border-gray-500 hover:text-gray-100 hover:bg-gray-800/50"
                                                : "border-gray-200 text-gray-600 hover:border-black hover:text-black hover:bg-gray-50"), onClick: () => {
                                            setSearch(keyword);
                                            // 滚动到文档列表区域
                                            setTimeout(() => {
                                                const docListSection = document.querySelector('section[class*="grid"]');
                                                if (docListSection) {
                                                    docListSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
                                                }
                                            }, 100);
                                        }, children: keyword }, keyword)))] }))] }), _jsxs("section", { className: "flex flex-wrap gap-3 text-sm", children: [["latest", "views"].map((type) => (_jsx("button", { onClick: () => setSort(type), className: clsx("rounded-full border px-4 py-2 capitalize transition", sort === type
                                    ? isDarkMode
                                        ? "bg-gray-500 text-white border-gray-400 shadow-lg"
                                        : "bg-black text-white"
                                    : isDarkMode
                                        ? "bg-gray-900/80 text-gray-400 border-gray-800 hover:border-gray-700 hover:text-gray-300"
                                        : "bg-white/70 text-gray-600 hover:border-black"), children: type === "latest" ? "最新发布" : "最多查看" }, type))), _jsx("button", { onClick: () => setShowAIRead(!showAIRead), className: clsx("rounded-full border px-4 py-2 transition", showAIRead
                                    ? isDarkMode
                                        ? "bg-gray-500 text-white border-gray-400 shadow-lg"
                                        : "bg-black text-white"
                                    : isDarkMode
                                        ? "bg-gray-900/80 text-gray-400 border-gray-800 hover:border-gray-700 hover:text-gray-300"
                                        : "bg-white/70 text-gray-600 hover:border-black"), children: "AI\u901F\u8BFB" })] }), _jsxs("section", { className: "grid gap-4", children: [filteredDocs.slice(0, displayedCount).map((doc) => {
                                return (_jsxs(motion.a, { layout: true, initial: { opacity: 0, y: 12 }, animate: { opacity: 1, y: 0 }, href: doc.link, target: "_blank", rel: "noreferrer", onClick: async (e) => {
                                        // 增加查看次数
                                        try {
                                            const { incrementDocumentViews } = await import("./lib/api");
                                            await incrementDocumentViews(doc.id);
                                            // 更新本地状态
                                            loadDocuments();
                                            loadStats();
                                            // 查看次数更新后，重新加载热门关键词（因为热度计算包含查看次数）
                                            loadHotKeywords();
                                        }
                                        catch (error) {
                                            console.error("增加查看次数失败:", error);
                                        }
                                    }, className: clsx("relative block overflow-hidden rounded-3xl border p-6 shadow-glass transition hover:shadow-2xl duration-300", isDarkMode
                                        ? "border-gray-700/60 bg-gray-800/90"
                                        : "border-white/60 bg-white/90"), children: [_jsxs("div", { className: clsx("absolute right-5 top-5 flex items-center gap-1 rounded-full px-3 py-1 text-xs z-10", isDarkMode ? "bg-gray-700 text-gray-300" : "bg-gray-200 text-gray-700"), children: [_jsx(Eye, { size: 14 }), doc.views.toLocaleString()] }), _jsx("div", { className: clsx("flex items-start gap-2 pr-20", isDarkMode ? "text-gray-100" : "text-gray-900"), children: _jsx("h2", { className: clsx("text-2xl font-medium line-clamp-2 break-words flex-1 overflow-hidden", isDarkMode ? "text-gray-100" : "text-gray-900"), children: doc.title }) }), _jsx("div", { className: clsx("mt-2 text-sm", isDarkMode ? "text-gray-400" : "text-gray-500"), children: `更新于 ${dayjs(doc.date).format("YYYY 年 M 月 D 日")}` }), _jsx("div", { className: "mt-2 flex flex-wrap items-center gap-2", children: doc.tags && doc.tags.length > 0 ? (doc.tags.map((tag) => (_jsx("span", { className: clsx("rounded-full border px-3 py-1 text-xs", isDarkMode ? "border-blue-800/50 bg-blue-900/30 text-blue-300" : "border-blue-100 bg-blue-50/80 text-blue-700"), children: tag }, tag)))) : (_jsx("span", { className: clsx("rounded-full border px-3 py-1 text-xs animate-pulse", isDarkMode ? "border-gray-600 bg-gray-700/50 text-gray-400" : "border-gray-300 bg-gray-100 text-gray-500"), children: "AI\u751F\u6210\u4E2D" })) }), _jsx("p", { className: clsx("mt-4 text-sm leading-relaxed whitespace-pre-wrap", isDarkMode ? "text-gray-300" : "text-gray-600"), children: doc.preview && doc.preview.length > 500 ? `${doc.preview.slice(0, 500)}...` : (doc.preview || "暂无预览") }), showAIRead && (_jsxs("div", { className: clsx("mt-4 rounded-2xl border px-4 py-3 text-sm shadow-inner", isDarkMode ? "border-blue-900/50 bg-blue-900/20 text-gray-300" : "border-blue-100 bg-blue-50/80 text-gray-600"), children: [_jsx("div", { className: clsx("mb-2 text-xs font-semibold uppercase tracking-widest", isDarkMode ? "text-blue-400" : "text-blue-500"), children: "AI \u901F\u8BFB" }), doc.aiAngle1 && doc.aiSummary1 && doc.aiAngle2 && doc.aiSummary2 ? (
                                                // 新的结构化格式
                                                _jsxs("div", { className: clsx("space-y-2 text-sm", isDarkMode ? "text-gray-300" : "text-gray-600"), children: [_jsxs("div", { children: [_jsxs("span", { className: clsx("font-medium", isDarkMode ? "text-blue-300" : "text-blue-600"), children: [doc.aiAngle1, "\uFF1A"] }), _jsx("span", { children: doc.aiSummary1 })] }), _jsxs("div", { children: [_jsxs("span", { className: clsx("font-medium", isDarkMode ? "text-blue-300" : "text-blue-600"), children: [doc.aiAngle2, "\uFF1A"] }), _jsx("span", { children: doc.aiSummary2 })] })] })) : doc.aiSummary && doc.aiSummary.trim().length > 0 ? (
                                                // 兼容旧格式
                                                _jsx("p", { className: clsx("text-sm", isDarkMode ? "text-gray-300" : "text-gray-600"), children: doc.aiSummary })) : (_jsx("span", { className: clsx("italic animate-pulse", isDarkMode ? "text-gray-400" : "text-gray-500"), children: "AI\u751F\u6210\u4E2D..." }))] }))] }, doc.id));
                            }), displayedCount >= filteredDocs.length && filteredDocs.length > 0 && (_jsx("div", { className: clsx("mt-8 text-center text-sm", isDarkMode ? "text-gray-400" : "text-gray-500"), children: "\u2014\u2014  \u77E5\u8BC6\u6CA1\u6709\u5C3D\u5934\uFF0C\u6B22\u8FCE\u60A8\u7684\u5206\u4EAB  \u2014\u2014" }))] })] }), _jsxs("button", { className: clsx("fixed bottom-6 right-6 flex items-center gap-2 rounded-full px-5 py-3 text-sm text-white shadow-2xl transition-colors duration-300", isDarkMode ? "bg-gray-700 hover:bg-gray-600" : "bg-black hover:bg-gray-900"), onClick: () => setShowUpload(true), children: [_jsx(Upload, { size: 16 }), "\u5206\u4EAB\u6587\u6863"] }), _jsx("footer", { className: clsx("mt-12 border-t transition-colors duration-300", isDarkMode ? "border-gray-700/60 bg-gray-900/70" : "border-white/60 bg-white/70"), children: _jsxs("div", { className: clsx("mx-auto flex max-w-6xl flex-col gap-4 px-4 py-10 text-xs md:flex-row md:items-center md:justify-between md:px-8", isDarkMode ? "text-gray-400" : "text-gray-500"), children: [_jsxs("div", { children: [_jsx("p", { className: clsx("text-sm font-semibold", isDarkMode ? "text-gray-200" : "text-gray-800"), children: "FeiHub" }), _jsx("p", { className: "mt-1 text-xs", children: "\u5206\u4EAB\u8BA9\u77E5\u8BC6\u88AB\u770B\u89C1 \u00B7 \u6587\u6863\u5206\u4EAB\u793E\u533A" })] }), _jsx("div", { className: "flex flex-wrap gap-4 text-xs", children: ["隐私条款", "服务条款", "关于我们", "产品服务", "广告合作", "社区规范"].map((item) => (_jsx("span", { className: clsx("cursor-default transition-colors", isDarkMode ? "text-gray-400 hover:text-gray-200" : "text-gray-500 hover:text-gray-800"), children: item }, item))) }), _jsxs("div", { className: clsx("text-xs", isDarkMode ? "text-gray-500" : "text-gray-400"), children: ["\u00A9 ", new Date().getFullYear(), " FeiHub. All rights reserved."] })] }) }), _jsx(UploadModal, { open: showUpload, isDarkMode: isDarkMode, loading: uploadLoading, message: uploadMessage, onClose: () => {
                    setShowUpload(false);
                    setUploadMessage(null);
                }, onSubmit: handleUpload }), _jsx(ModalShell, { open: showCustomerService, title: "\u8054\u7CFB\u5BA2\u670D", isDarkMode: isDarkMode, onClose: () => {
                    setShowCustomerService(false);
                    setCopied(false); // 关闭弹窗时重置复制状态
                }, children: _jsxs("div", { className: "space-y-4", children: [_jsx("div", { className: "flex justify-center", children: _jsx("img", { src: "/kefu.png", alt: "\u5BA2\u670D\u4E8C\u7EF4\u7801", className: "max-w-full max-h-[60vh] h-auto rounded-lg object-contain", onError: (e) => {
                                    // 如果图片加载失败，尝试使用环境变量中的链接
                                    const img = e.target;
                                    const customerServiceImageUrl = import.meta.env.VITE_CUSTOMER_SERVICE_IMAGE_URL;
                                    if (customerServiceImageUrl) {
                                        img.src = customerServiceImageUrl;
                                    }
                                    else {
                                        console.error("客服图片加载失败，请检查图片路径或配置 VITE_CUSTOMER_SERVICE_IMAGE_URL");
                                    }
                                } }) }), _jsx("div", { className: "flex justify-center", children: _jsx(motion.button, { onClick: async (e) => {
                                    if (copied)
                                        return; // 如果已复制，不再执行
                                    try {
                                        await navigator.clipboard.writeText("starcitybro");
                                        setCopied(true);
                                    }
                                    catch (err) {
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
                                        }
                                        catch (fallbackErr) {
                                            console.error("降级复制也失败:", fallbackErr);
                                        }
                                        document.body.removeChild(textArea);
                                    }
                                }, disabled: copied, whileHover: copied ? {} : { scale: 1.05 }, whileTap: copied ? {} : { scale: 0.95 }, className: clsx("rounded-lg border px-6 py-3 text-sm font-medium transition-colors whitespace-nowrap min-w-[140px]", copied
                                    ? isDarkMode
                                        ? "border-gray-500 bg-gray-600 text-gray-200 cursor-not-allowed"
                                        : "border-gray-400 bg-gray-300 text-gray-600 cursor-not-allowed"
                                    : isDarkMode
                                        ? "border-gray-600 bg-gray-700 text-gray-100 hover:bg-gray-600"
                                        : "border-gray-300 bg-gray-50 text-gray-700 hover:bg-gray-100"), children: copied ? "已复制" : "复制微信号" }) })] }) })] }));
}
function UploadModal({ open, isDarkMode, loading = false, message, onClose, onSubmit }) {
    const [link, setLink] = useState("");
    // 验证链接格式：必须是有效的 http/https URL，且长度合理
    const isValid = (() => {
        if (!link || link.trim().length === 0)
            return false;
        try {
            const url = new URL(link.trim());
            return (url.protocol === "http:" || url.protocol === "https:") && link.trim().length >= 10;
        }
        catch {
            return false;
        }
    })();
    const handleSubmit = () => {
        if (isValid && !loading) {
            onSubmit(link.trim());
            setLink("");
        }
    };
    if (!open)
        return null;
    return (_jsx(ModalShell, { open: true, title: "\u5206\u4EAB\u6587\u6863", isDarkMode: isDarkMode, onClose: onClose, children: _jsxs("div", { className: "space-y-4 text-sm", children: [_jsxs("div", { children: [_jsx("label", { className: clsx("text-xs", isDarkMode ? "text-gray-400" : "text-gray-500"), children: "\u6587\u6863\u94FE\u63A5" }), _jsx("input", { value: link, onChange: (e) => setLink(e.target.value), disabled: loading, className: clsx("mt-2 w-full rounded-2xl border px-4 py-3 text-sm outline-none transition-colors disabled:opacity-50", isDarkMode ? "border-gray-700 bg-gray-700/50 text-gray-100 placeholder:text-gray-500 focus:border-gray-600" : "border-gray-200 bg-white text-gray-900 placeholder:text-gray-400 focus:border-gray-400"), placeholder: "https://feishu.cn/docx/..." })] }), message && (_jsx("div", { className: clsx("rounded-2xl px-4 py-2 text-xs", message.includes("成功") ? (isDarkMode ? "bg-green-900/30 text-green-300" : "bg-green-50 text-green-700") : (isDarkMode ? "bg-red-900/30 text-red-300" : "bg-red-50 text-red-700")), children: message })), _jsx("button", { disabled: !isValid || loading, onClick: handleSubmit, className: clsx("w-full rounded-full py-3 text-sm text-white disabled:opacity-40 disabled:cursor-not-allowed transition-colors", isDarkMode ? "bg-gray-700 hover:bg-gray-600 disabled:hover:bg-gray-700" : "bg-black hover:bg-gray-900 disabled:hover:bg-black"), children: loading ? "提交中..." : "确定" })] }) }));
}

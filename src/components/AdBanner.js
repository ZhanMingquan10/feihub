import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Sparkles } from "lucide-react";
export function AdBanner({ variant = "inline" }) {
    if (variant === "card") {
        return (_jsxs("div", { className: "rounded-2xl border border-gray-200 bg-gradient-to-br from-white to-gray-50 p-5 shadow-glass", children: [_jsxs("div", { className: "flex items-center gap-2 text-sm font-semibold text-gray-600", children: [_jsx(Sparkles, { size: 16 }), "\u54C1\u724C\u5408\u4F5C\u4F4D \u00B7 \u4E0D\u6253\u6270\u4F53\u9A8C"] }), _jsx("p", { className: "mt-2 text-sm text-gray-500", children: "\u5728\u8FD9\u91CC\u6295\u653E\u4E13\u4E1A\u8BFE\u7A0B\u3001\u5DE5\u5177\u6216\u5E7F\u544A\u3002\u6211\u4EEC\u4F1A\u5728 48 \u5C0F\u65F6\u5185\u5B8C\u6210\u5BA1\u6838\u3002" })] }));
    }
    return (_jsxs("div", { className: "flex items-center justify-between rounded-2xl border border-gray-200 bg-white/80 px-6 py-4 text-sm text-gray-600 shadow-glass", children: [_jsxs("div", { children: [_jsx("span", { className: "font-semibold text-gray-900", children: "FeiHub \u5E7F\u544A\u8BA1\u5212" }), _jsx("p", { className: "text-xs text-gray-500", children: "\u6295\u653E\u7CBE\u51C6\u77E5\u8BC6\u4EBA\u7FA4\uFF0C\u5E7F\u544A\u4F4D\u9ED8\u8BA4\u4FDD\u6301\u6536\u8D77\u72B6\u6001\u3002" })] }), _jsx("button", { className: "rounded-full border border-gray-300 px-4 py-1 text-xs hover:bg-gray-100", children: "\u4E86\u89E3\u66F4\u591A" })] }));
}

import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { motion } from "framer-motion";
import { X } from "lucide-react";
import clsx from "clsx";
export function ModalShell({ open, title, widthClass = "max-w-lg", isDarkMode = false, onClose, children }) {
    if (!open)
        return null;
    return (_jsx("div", { className: "fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4 py-4", onClick: onClose, children: _jsxs(motion.div, { layout: true, initial: { opacity: 0, y: 16 }, animate: { opacity: 1, y: 0 }, onClick: (e) => e.stopPropagation(), className: clsx("w-full rounded-3xl p-6 shadow-2xl transition-colors duration-300 max-h-[90vh] flex flex-col", isDarkMode ? "bg-gray-800" : "bg-white", widthClass), children: [_jsxs("div", { className: clsx("flex items-center justify-between border-b pb-4 flex-shrink-0", isDarkMode ? "border-gray-700" : "border-gray-100"), children: [_jsx("h3", { className: clsx("text-lg font-semibold", isDarkMode ? "text-gray-100" : "text-gray-900"), children: title }), _jsx("button", { onClick: onClose, className: clsx("rounded-full border p-1 transition-colors", isDarkMode ? "border-gray-700 hover:bg-gray-700 text-gray-300" : "border-gray-200 hover:bg-gray-50 text-gray-600"), "aria-label": "\u5173\u95ED\u5F39\u7A97", children: _jsx(X, { size: 18 }) })] }), _jsx("div", { className: "pt-4 overflow-hidden flex-1", children: children })] }) }));
}

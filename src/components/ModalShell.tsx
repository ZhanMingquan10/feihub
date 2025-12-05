import { PropsWithChildren } from "react";
import { motion } from "framer-motion";
import { X } from "lucide-react";
import clsx from "clsx";

type ModalShellProps = {
  open: boolean;
  title: string;
  widthClass?: string;
  isDarkMode?: boolean;
  onClose: () => void;
};

export function ModalShell({ open, title, widthClass = "max-w-lg", isDarkMode = false, onClose, children }: PropsWithChildren<ModalShellProps>) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4 py-4" onClick={onClose}>
      <motion.div
        layout
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        onClick={(e) => e.stopPropagation()}
        className={clsx("w-full rounded-3xl p-6 shadow-2xl transition-colors duration-300 max-h-[90vh] flex flex-col", isDarkMode ? "bg-gray-900 border border-gray-700/50" : "bg-white", widthClass)}
      >
        <div className={clsx("flex items-center justify-between border-b pb-4 flex-shrink-0", isDarkMode ? "border-gray-600/60" : "border-gray-100")}>
          <h3 className={clsx("text-lg font-semibold", isDarkMode ? "text-gray-100" : "text-gray-900")}>{title}</h3>
          <button onClick={onClose} className={clsx("rounded-full border p-1 transition-colors", isDarkMode ? "border-gray-600/60 hover:bg-gray-800 text-gray-300" : "border-gray-200 hover:bg-gray-50 text-gray-600")} aria-label="关闭弹窗">
            <X size={18} />
          </button>
        </div>
        <div className="pt-4 overflow-hidden flex-1">{children}</div>
      </motion.div>
    </div>
  );
}


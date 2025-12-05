import { create } from "zustand";
import type { FeishuDocument, SortType } from "../types";
import { getDocuments, submitDocument, type Document } from "../lib/api";

type DocumentState = {
  docs: FeishuDocument[];
  sort: SortType;
  search: string;
  loading: boolean;
  total: number;
  setSearch: (value: string) => void;
  setSort: (value: SortType) => void;
  loadDocuments: () => Promise<void>;
  uploadDoc: (link: string) => Promise<{ success: boolean; message?: string; error?: string }>;
};

  // 将API的Document格式转换为前端FeishuDocument格式
  function convertDocument(doc: Document): FeishuDocument {
    return {
      id: doc.id,
      title: doc.title,
      author: doc.author,
      date: doc.date,
      views: doc.views,
      tags: doc.tags,
      preview: doc.preview,
      content: doc.content, // 完整内容（保留格式）
      link: doc.link,
      aiSummary: doc.aiSummary, // 兼容旧格式
      aiAngle1: doc.aiAngle1,
      aiSummary1: doc.aiSummary1,
      aiAngle2: doc.aiAngle2,
      aiSummary2: doc.aiSummary2
    };
  }

export const useDocumentStore = create<DocumentState>((set, get) => ({
  docs: [],
  sort: "latest",
  search: "",
  loading: false,
  total: 0,
  setSearch: (value) => {
    set({ search: value });
    get().loadDocuments();
  },
  setSort: (value) => {
    set({ sort: value });
    get().loadDocuments();
  },
  loadDocuments: async () => {
    set({ loading: true });
    try {
      const { search, sort } = get();
      const response = await getDocuments({
        search: search || undefined,
        sort: sort === "latest" ? "latest" : "views",
        page: 1,
        limit: 1000 // 加载更多，前端做分页
      });

      console.log("加载文档响应:", response);

      if (response.success && response.data) {
        const documents = response.data.data || [];
        console.log("文档列表:", documents);
        set({
          docs: documents.map(convertDocument),
          total: response.data.pagination?.total || documents.length,
          loading: false
        });
      } else {
        console.error("加载文档失败:", response.error);
        set({ loading: false });
      }
    } catch (error) {
      console.error("加载文档异常:", error);
      set({ loading: false });
    }
  },
  uploadDoc: async (link: string) => {
    try {
      const response = await submitDocument(link);
      if (response.success) {
        // 不立即添加临时文档到列表，等待后端处理完成
        // 启动轮询，检查文档是否已处理完成
        if (response.data?.documentId) {
          let pollCount = 0;
          const maxPolls = 20; // 最多轮询20次（约60秒）
          
          const pollInterval = setInterval(async () => {
            try {
              pollCount++;
              await get().loadDocuments();
              
              // 检查文档是否已处理完成（标题不再是"内容正在联网获取..."）
              const updatedDocs = get().docs;
              const completedDoc = updatedDocs.find(doc => doc.id === response.data?.documentId);
              
              if (completedDoc && completedDoc.title !== "内容正在联网获取...") {
                // 文档已处理完成，停止轮询
                clearInterval(pollInterval);
                console.log("文档处理完成，已显示在列表中");
                
                // 文档更新后，触发热门关键词刷新
                if (typeof window !== 'undefined') {
                  window.dispatchEvent(new CustomEvent('refreshHotKeywords'));
                }
              } else if (pollCount >= maxPolls) {
                // 超时，停止轮询
                clearInterval(pollInterval);
                console.log("轮询超时，停止检查");
              }
            } catch (error) {
              console.error("轮询检查文档状态失败:", error);
            }
          }, 3000); // 每3秒检查一次
        } else {
          // 如果没有返回documentId，直接重新加载
          await get().loadDocuments();
        }
        
        return {
          success: true,
          message: response.message || "感谢您的分享，AI处理中，预计需要几分钟..."
        };
      } else {
        return {
          success: false,
          error: response.error || "提交失败"
        };
      }
    } catch (error: any) {
      return {
        success: false,
        error: error.message || "提交失败"
      };
    }
  }
}));


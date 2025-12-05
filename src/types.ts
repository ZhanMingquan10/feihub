export type FeishuDocument = {
  id: string;
  title: string;
  author: string;
  date: string;
  views: number;
  tags: string[];
  preview: string;
  content?: string; // 完整正文内容（保留格式）
  cover?: string;
  link?: string;
  aiSummary?: string; // AI速读内容（兼容旧格式）
  aiAngle1?: string; // AI总结角度1
  aiSummary1?: string; // AI总结角度1的内容
  aiAngle2?: string; // AI总结角度2
  aiSummary2?: string; // AI总结角度2的内容
};

export type SortType = "latest" | "views";


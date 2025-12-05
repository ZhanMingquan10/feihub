/**
 * 飞书文档数据接口
 */
export interface FeishuDocumentData {
  title: string;          // 文档标题
  author?: string;        // 作者（默认为"社区贡献者"）
  date: string;          // 更新日期 (YYYY-MM-DD)
  content: string;        // 文档正文内容

  // AI生成的信息（可选）
  tags?: string[];        // AI生成的3个标签
  aiAngle1?: string;      // AI总结角度1
  aiSummary1?: string;    // AI总结1的内容
  aiAngle2?: string;      // AI总结角度2
  aiSummary2?: string;    // AI总结2的内容
}

// 导出服务端函数，供其他模块使用
export { fetchFeishuDocumentServer as fetchFeishuDocument } from './feishu-server';
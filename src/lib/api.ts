const API_BASE = import.meta.env.VITE_API_BASE || "http://localhost:4000/api";

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface Document {
  id: string;
  title: string;
  author: string;
  link: string;
  preview: string;
  content?: string; // 完整正文内容（保留格式）
  date: string;
  views: number;
  tags: string[];
  aiSummary?: string; // 兼容旧格式
  aiAngle1?: string; // AI总结角度1
  aiSummary1?: string; // AI总结角度1的内容
  aiAngle2?: string; // AI总结角度2
  aiSummary2?: string; // AI总结角度2的内容
}

export interface DocumentListResponse {
  data: Document[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

/**
 * 提交文档链接
 */
export async function submitDocument(link: string): Promise<ApiResponse<{ submissionId: string; documentId?: string }>> {
  try {
    const response = await fetch(`${API_BASE}/submissions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ link })
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      return {
        success: false,
        error: errorData.error || `请求失败 (${response.status}): ${response.statusText}`
      };
    }

    const data = await response.json();
    return data;
  } catch (error: any) {
    console.error("提交文档错误:", error);
    return {
      success: false,
      error: error.message || "网络错误，请检查后端服务是否运行"
    };
  }
}

/**
 * 查询提交状态
 */
export async function getSubmissionStatus(submissionId: string): Promise<ApiResponse<any>> {
  try {
    const response = await fetch(`${API_BASE}/submissions/${submissionId}`);
    return await response.json();
  } catch (error: any) {
    return {
      success: false,
      error: error.message || "查询失败"
    };
  }
}

/**
 * 获取文档列表
 */
export async function getDocuments(params: {
  search?: string;
  sort?: "latest" | "views";
  page?: number;
  limit?: number;
}): Promise<ApiResponse<DocumentListResponse>> {
  try {
    const queryParams = new URLSearchParams();
    if (params.search) queryParams.append("search", params.search);
    if (params.sort) queryParams.append("sort", params.sort);
    if (params.page) queryParams.append("page", params.page.toString());
    if (params.limit) queryParams.append("limit", params.limit.toString());

    const response = await fetch(`${API_BASE}/documents?${queryParams}`);
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      return {
        success: false,
        error: errorData.error || `请求失败 (${response.status}): ${response.statusText}`
      };
    }

    const data = await response.json();
    console.log("API 返回数据:", data);
    
    // 后端返回格式: { success: true, data: [...], pagination: {...} }
    // 前端期望格式: { success: true, data: { data: [...], pagination: {...} } }
    if (data.success && Array.isArray(data.data)) {
      // 转换格式以匹配前端期望
      return {
        success: true,
        data: {
          data: data.data,
          pagination: data.pagination || {
            total: data.data.length,
            page: 1,
            limit: data.data.length,
            totalPages: 1
          }
        }
      };
    }
    
    return data;
  } catch (error: any) {
    console.error("获取文档列表错误:", error);
    return {
      success: false,
      error: error.message || "获取文档列表失败"
    };
  }
}

/**
 * 获取统计信息
 */
export async function getStats(): Promise<ApiResponse<{ totalDocuments: number; totalViews: number }>> {
  try {
    const response = await fetch(`${API_BASE}/documents/stats/summary`);
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      return {
        success: false,
        error: errorData.error || `请求失败 (${response.status}): ${response.statusText}`
      };
    }
    const data = await response.json();
    return data;
  } catch (error: any) {
    return {
      success: false,
      error: error.message || "获取统计信息失败"
    };
  }
}

/**
 * 增加文档查看次数
 */
export async function incrementDocumentViews(documentId: string): Promise<ApiResponse<Document>> {
  try {
    const response = await fetch(`${API_BASE}/documents/${documentId}`, {
      method: "GET"
    });
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      return {
        success: false,
        error: errorData.error || `请求失败 (${response.status}): ${response.statusText}`
      };
    }
    
    const data = await response.json();
    return data;
  } catch (error: any) {
    console.error("增加查看次数错误:", error);
    return {
      success: false,
      error: error.message || "增加查看次数失败"
    };
  }
}

/**
 * 获取热门关键词
 */
export async function getHotKeywords(): Promise<ApiResponse<string[]>> {
  try {
    console.log("[API] 请求热门关键词:", `${API_BASE}/documents/hot-keywords`);
    const response = await fetch(`${API_BASE}/documents/hot-keywords`, {
      method: "GET",
      headers: {
        "Content-Type": "application/json"
      }
    });
    
    console.log("[API] 热门关键词响应状态:", response.status, response.statusText);
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      console.error("[API] 热门关键词请求失败:", errorData);
      return {
        success: false,
        error: errorData.error || `请求失败 (${response.status}): ${response.statusText}`
      };
    }
    
    const data = await response.json();
    console.log("[API] 热门关键词原始数据:", JSON.stringify(data, null, 2));
    console.log("[API] data.success:", data.success);
    console.log("[API] data.data:", data.data);
    console.log("[API] data.data类型:", typeof data.data);
    console.log("[API] data.data是否为数组:", Array.isArray(data.data));
    
    // 确保返回正确的格式
    if (data.success && Array.isArray(data.data)) {
      console.log("[API] ✅ 返回热门关键词:", data.data);
      console.log("[API] 关键词数量:", data.data.length);
      return {
        success: true,
        data: data.data
      };
    } else {
      console.warn("[API] ⚠️ 数据格式不正确:");
      console.warn("[API]   - data.success:", data.success);
      console.warn("[API]   - data.data:", data.data);
      console.warn("[API]   - data.data是否为数组:", Array.isArray(data.data));
      console.warn("[API] 返回空数组");
      return {
        success: true,
        data: []
      };
    }
  } catch (error: any) {
    console.error("[API] 获取热门关键词错误:", error);
    console.error("[API] 错误堆栈:", error.stack);
    // 如果出错，返回空数组
    return {
      success: true,
      data: []
    };
  }
}



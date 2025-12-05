import express from "express";
import { prisma } from "../lib/prisma";

const router = express.Router();

/**
 * GET /api/documents
 * 获取文档列表（支持搜索和排序）
 */
router.get("/", async (req, res) => {
  try {
    const { search, sort = "latest", page = 1, limit = 10 } = req.query;

    const pageNum = parseInt(page as string) || 1;
    const limitNum = parseInt(limit as string) || 10;
    const skip = (pageNum - 1) * limitNum;

    // 构建查询条件
    const where: any = {
      // 排除处理中的临时文档
      title: { not: "内容正在联网获取..." }
    };
    if (search) {
      where.OR = [
        { title: { contains: search as string, mode: "insensitive" } },
        { preview: { contains: search as string, mode: "insensitive" } },
        { tags: { has: search as string } }
      ];
    }

    // 构建排序
    const orderBy: any = {};
    if (sort === "views") {
      orderBy.views = "desc";
    } else {
      orderBy.date = "desc";
    }

    // 查询文档（列表不返回完整内容，只返回 preview）
    const [documents, total] = await Promise.all([
      prisma.document.findMany({
        where,
        orderBy,
        skip,
        take: limitNum,
        select: {
          id: true,
          title: true,
          author: true,
          date: true,
          views: true,
          tags: true,
          preview: true,
          content: false, // 列表不返回完整内容，节省带宽
          aiSummary: true,
          aiAngle1: true,
          aiSummary1: true,
          aiAngle2: true,
          aiSummary2: true,
          link: true
        }
      }),
      prisma.document.count({ where })
    ]);

    res.json({
      success: true,
      data: documents,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum)
      }
    });
  } catch (error: any) {
    console.error("获取文档列表失败:", error);
    res.status(500).json({
      success: false,
      error: "获取文档列表失败"
    });
  }
});

/**
 * GET /api/documents/stats/summary
 * 获取统计信息
 */
router.get("/stats/summary", async (req, res) => {
  try {
    const [totalDocs, totalViews] = await Promise.all([
      prisma.document.count(),
      prisma.document.aggregate({
        _sum: { views: true }
      })
    ]);

    res.json({
      success: true,
      data: {
        totalDocuments: totalDocs,
        totalViews: totalViews._sum.views || 0
      }
    });
  } catch (error: any) {
    console.error("获取统计信息失败:", error);
    res.status(500).json({
      success: false,
      error: "获取统计信息失败"
    });
  }
});

/**
 * GET /api/documents/hot-keywords
 * 获取热门关键词（基于文档标签统计，按热度从高到低排列）
 * 注意：此路由必须在 /:id 路由之前定义，否则会被 /:id 路由拦截
 */
router.get("/hot-keywords", async (req, res) => {
  try {
    console.log("[热搜词] ========== 收到请求，开始统计热门关键词 ==========");
    console.log("[热搜词] 请求URL:", req.url);
    console.log("[热搜词] 请求方法:", req.method);
    
    // 获取所有文档的标签和查看次数
    const documents = await prisma.document.findMany({
      where: {
        title: { not: "内容正在联网获取..." } // 排除临时文档
      },
      select: {
        id: true, // 添加ID用于调试
        title: true, // 添加标题用于调试
        tags: true,
        views: true,
        date: true // 添加日期，可以用于时间加权
      }
    });

    console.log(`[热搜词] 找到 ${documents.length} 个有效文档`);
    console.log(`[热搜词] 文档列表:`, documents.map(d => ({ id: d.id, title: d.title, tagsCount: d.tags?.length || 0, tags: d.tags })));
    
    // 详细日志：显示每个文档的标签状态
    let docsWithTags = 0;
    let docsWithoutTags = 0;
    documents.forEach((doc, index) => {
      if (doc.tags && Array.isArray(doc.tags) && doc.tags.length > 0) {
        docsWithTags++;
        console.log(`[热搜词] 文档 ${index + 1}: 有 ${doc.tags.length} 个标签 - ${doc.tags.join(", ")}`);
      } else {
        docsWithoutTags++;
        console.log(`[热搜词] 文档 ${index + 1}: 无标签 (tags=${JSON.stringify(doc.tags)})`);
      }
    });
    console.log(`[热搜词] 统计: ${docsWithTags} 个文档有标签, ${docsWithoutTags} 个文档无标签`);

    // 统计标签出现次数和总查看次数
    const tagStats: Record<string, { count: number; totalViews: number; avgViews: number }> = {};
    
    documents.forEach((doc, docIndex) => {
      if (doc.tags && Array.isArray(doc.tags) && doc.tags.length > 0) {
        console.log(`[热搜词] 处理文档 ${docIndex + 1} 的标签:`, JSON.stringify(doc.tags));
        doc.tags.forEach((tag, tagIndex) => {
          console.log(`[热搜词]   标签 ${tagIndex + 1}: "${tag}" (类型: ${typeof tag}, 长度: ${tag ? tag.length : 0}, trim后长度: ${tag ? tag.trim().length : 0})`);
          if (tag && typeof tag === 'string' && tag.trim().length > 0) { // 确保标签不为空
            const trimmedTag = tag.trim();
            if (!tagStats[trimmedTag]) {
              tagStats[trimmedTag] = { count: 0, totalViews: 0, avgViews: 0 };
            }
            tagStats[trimmedTag].count += 1;
            tagStats[trimmedTag].totalViews += doc.views || 0;
            console.log(`[热搜词]   标签 "${trimmedTag}" 已统计，当前出现次数: ${tagStats[trimmedTag].count}`);
          } else {
            console.log(`[热搜词]   标签 "${tag}" 被跳过（为空或格式不正确）`);
          }
        });
      }
    });

    // 计算平均查看次数
    Object.keys(tagStats).forEach(tag => {
      tagStats[tag].avgViews = tagStats[tag].totalViews / tagStats[tag].count;
    });

    console.log(`[热搜词] 统计到 ${Object.keys(tagStats).length} 个不同标签`);
    console.log(`[热搜词] 标签统计详情:`, JSON.stringify(tagStats, null, 2));

    // 如果没有标签，返回空数组
    if (Object.keys(tagStats).length === 0) {
      console.log(`[热搜词] ⚠️ 没有找到任何有效标签，返回空数组`);
      console.log(`[热搜词] 调试信息: 文档总数=${documents.length}, 有标签文档数=${docsWithTags}, 无标签文档数=${docsWithoutTags}`);
      return res.json({
        success: true,
        data: []
      });
    }

    // 按热度排序：综合评分 = 出现次数 × 3 + 总查看次数 × 1 + 平均查看次数 × 2
    // 这样既考虑标签的流行度（出现次数），也考虑文档的受欢迎程度（查看次数）
    const hotKeywords = Object.entries(tagStats)
      .map(([tag, stats]) => ({
        tag,
        score: stats.count * 3 + stats.totalViews * 1 + Math.floor(stats.avgViews) * 2,
        count: stats.count,
        totalViews: stats.totalViews
      }))
      .sort((a, b) => {
        // 先按评分排序
        if (b.score !== a.score) {
          return b.score - a.score;
        }
        // 如果评分相同，按总查看次数排序
        if (b.totalViews !== a.totalViews) {
          return b.totalViews - a.totalViews;
        }
        // 最后按出现次数排序
        return b.count - a.count;
      })
      .slice(0, 6)
      .map(item => {
        console.log(`[热搜词] ${item.tag}: 评分=${item.score}, 出现次数=${item.count}, 总查看=${item.totalViews}`);
        return item.tag;
      });

    console.log(`[热搜词] 最终返回 ${hotKeywords.length} 个热门关键词:`, hotKeywords);
    console.log(`[热搜词] 返回数据格式:`, JSON.stringify({ success: true, data: hotKeywords }, null, 2));
    console.log(`[热搜词] ========== 统计完成 ==========`);

    // 直接返回统计结果，不补充默认关键词
    const responseData = {
      success: true,
      data: hotKeywords
    };
    console.log(`[热搜词] 发送响应:`, JSON.stringify(responseData, null, 2));
    res.json(responseData);
  } catch (error: any) {
    console.error("[热搜词] 获取热门关键词失败:", error);
    console.error("[热搜词] 错误堆栈:", error.stack);
    // 如果出错，返回空数组
    res.json({
      success: true,
      data: []
    });
  }
});

/**
 * GET /api/documents/:id
 * 获取单个文档详情
 * 注意：此路由必须在所有具体路径路由之后定义，否则会拦截其他路由
 */
router.get("/:id", async (req, res) => {
  try {
    const document = await prisma.document.findUnique({
      where: { id: req.params.id }
    });

    if (!document) {
      return res.status(404).json({
        success: false,
        error: "文档不存在"
      });
    }

    // 增加查看次数
    await prisma.document.update({
      where: { id: req.params.id },
      data: { views: { increment: 1 } }
    });

    res.json({
      success: true,
      data: document
    });
  } catch (error: any) {
    console.error("获取文档详情失败:", error);
    res.status(500).json({
      success: false,
      error: "获取文档详情失败"
    });
  }
});

export { router as documentRouter };



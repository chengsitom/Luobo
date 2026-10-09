import '../models/models.dart';

/// 有声书内容类型（§7.4 类型感知导航用）。
///
/// 编号型（叙事书：三体/鬼吹灯）章节有序、用户按编号找章；
/// 合集型（相声/曲艺）每段是独立作品、标题才是身份。
enum AudiobookContentType { numbered, collection }

/// 端上类型判断（纯客户端，服务端零改动）：
///
/// 1. 服务端 `categories[]`/`tags[]` 优先——含合集类标记（相声/曲艺/评书）
///    直接判合集型（列表项 API 已有字段，可为空）；
/// 2. 兜底标题模式启发式：章节标题「第X章/回/节/集/部/卷」或「Chapter N」
///    前缀占比 ≥ [numberedTitleRatio] → 编号型，否则合集型。
///
/// 判定依赖章节标题，须在 `_loadChapters` 成功后调用（全量列表已在内存）。
AudiobookContentType classifyAudiobookType({
  required Audiobook book,
  required List<AudiobookChapter> chapters,
}) {
  // ① 服务端分类字段优先（集合类标记 → 合集型）。
  final labels =
      [...book.categories, ...book.tags].map((s) => s.toLowerCase()).toList();
  if (labels.any((s) => _collectionLabelPattern.hasMatch(s))) {
    return AudiobookContentType.collection;
  }

  // ② 标题启发式兜底：无章节数据时默认编号型（未知按叙事书处理）。
  if (chapters.isEmpty) return AudiobookContentType.numbered;
  final numbered = chapters
      .where((c) => _numberedTitlePattern.hasMatch(c.title.trim()))
      .length;
  return numbered / chapters.length >= numberedTitleRatio
      ? AudiobookContentType.numbered
      : AudiobookContentType.collection;
}

/// 编号标题占比阈值：≥60% 判编号型（容忍个别非编号章节/脏数据）。
const double numberedTitleRatio = 0.6;

/// 编号型标题：「第一章」「第 12 回」「第100集」「Chapter 3」「卷一」，
/// 以及**数字编号前缀**「001 风起」「01. 标题」「3、标题」。
///
/// ⚠️ 2026-08-21 真机修正：三体章节标题实测为「001/002」数字编号格式，
/// 原正则只认「第X章/回/集」导致全不匹配 → 误判合集型（搜索按钮）。
final RegExp _numberedTitlePattern = RegExp(
  r'^(第\s*[0-9一二三四五六七八九十百千零两]+\s*[章回节集部卷话篇]'
  r'|\d{1,4}[\s.、:：]'
  r'|chapter\s*\d+'
  r'|卷\s*[0-9一二三四五六七八九十百千零两]+)',
  caseSensitive: false,
);

/// 合集类标记（服务端 categories/tags 中出现即判合集型）。
final RegExp _collectionLabelPattern = RegExp(
  r'相声|曲艺|评书|crosstalk|sketch|comedy',
  caseSensitive: false,
);

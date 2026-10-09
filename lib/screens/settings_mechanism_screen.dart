import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/navigation_helper.dart';

/// 「机制说明」入口：解释 App 内各功能的实现机理。
///
/// 三级导航：设置根页「关于」组 → [SettingsMechanismScreen]（按 7 大类分组的
/// 条目列表）→ [SettingsMechanismDetailScreen]（单项通俗解释 + 可折叠技术细节）。
///
/// 文案约定：34 条正文以中文写死在下方 const 数据表（避免 30 个语言文件全部
/// 膨胀）；UI 壳层（入口/页面标题/分组标题/折叠标签）走 l10n。
class SettingsMechanismScreen extends StatelessWidget {
  const SettingsMechanismScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor:
          _isDark(context) ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(l10n.settingsMechanicsEntry),
        centerTitle: false,
        backgroundColor: _isDark(context)
            ? AppTheme.darkBackground
            : AppTheme.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          for (final group in _buildGroups(l10n)) ...[
            _sectionHeader(context, group),
            const SizedBox(height: 8),
            _groupCard(context, group),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

/// 三级页：单项通俗解释 + 可折叠技术细节（默认收起）。
class SettingsMechanismDetailScreen extends StatelessWidget {
  const SettingsMechanismDetailScreen({
    super.key,
    required this.item,
  });

  final MechanismItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = _isDark(context);
    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(item.title),
        centerTitle: false,
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _summaryCard(context, item),
          const SizedBox(height: 24),
          if (item.details.isNotEmpty) ...[
            _techCard(context, l10n, item),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

// ── 数据模型 ──────────────────────────────────────────────────────────

/// 一条机制条目：标题 + 通俗解释（summary）+ 技术细节（details，可折叠）。
class MechanismItem {
  const MechanismItem({
    required this.title,
    required this.summary,
    this.details = '',
  });

  final String title;
  final String summary;
  final String details;
}

/// 一个分组：标题在构建时由 l10n 提供，条目内容为 const 中文数据表。
class _MechanismGroup {
  const _MechanismGroup({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<MechanismItem> items;
}

// ── 文案数据表（中文，const） ────────────────────────────────────────

const List<MechanismItem> _homeItems = [
  MechanismItem(
    title: '首页的数据从哪来',
    summary:
        '首页所有推荐都基于你服务器上的全部歌曲（候选池）。推荐不会每次打开都重算——只有当曲库发生变化（如新增歌曲）时才重新生成，其余时间直接复用上次结果，所以打开快、当天内容稳定。',
    details:
        '候选池 = LibraryProvider.cachedAllSongs 全量曲库，未完成全量同步时退化为 randomSongs（50 首随机池）；Feed 缓存以曲库版本为 key，仅版本变化时重算。\n依据：home_v2_screen.dart:171-187',
  ),
  MechanismItem(
    title: '每日推荐是怎么算的',
    summary:
        '每天一套固定的 30 首推荐。算法把「你爱听的行为分（70%）」和「歌曲标签的匹配度（30%）」合成一个分数给全库排序，你常听的歌天然靠前；又因为「同歌手最多 2 首、同专辑最多 1 首」的限制，多出来的名额会给没听过但风格相近的歌——所以每天既有熟悉感、也有新歌。同一套标签库内当天结果不变。',
    details:
        'dailyRecommendation 对全库（不只熟悉层）按融合分取 Top 30；缓存 key = 日期（_dayKey），当天命中不重算。\n依据：home_recommendation_service.dart:214-233',
  ),
  MechanismItem(
    title: '继续播放',
    summary: '就是「最近播放」列表——最近点过的歌按时间倒序取前 10 首，'
        '没有任何算法，方便一键回到上次没听完的地方。',
    details:
        '依据：home_v2_screen.dart:296-359、recommendation_service.dart（最近播放列表，上限 500）',
  ),
  MechanismItem(
    title: '场景 Mix（通勤 / 学习 / 睡前）',
    summary:
        '每张 Mix 对应一组场景标签（通勤=高能量/快节奏/运动…，学习=纯音乐/舒缓…，睡前=治愈/慢/安静…）。优先在你常听的歌里挑标签匹配的，凑不满 20 首再从全库按同样关键词补足。想听什么氛围，直接点一张。',
    details:
        'sceneMix 在熟悉层做标签子串匹配（_matchesScene），不足 20 首从全库补。\n依据：home_recommendation_service.dart:235-265',
  ),
  MechanismItem(
    title: '你的最爱 Mix',
    summary:
        '名字容易误会——它不是「最近播放」，而是按长期行为算出的「长期最爱」：收藏、评分、完播率高、反复听的歌排前面，相当于你的口味总结。',
    details:
        'favoritesMix 按 _favoriteScore（= 行为综合权重 _behaviorWeight）降序。\n依据：home_recommendation_service.dart:269-289',
  ),
  MechanismItem(
    title: '最近播放混合区',
    summary: '上半部分是你最近播放过的歌单和收藏（记录保存在本机，最多 10 条），'
        '下半部分是你最近浏览过的专辑，拼在一起方便继续之前的探索。',
    details:
        'PlaybackContextTracker（SharedPreferences 持久化，上限 10）+ LibraryProvider.recentAlbums（服务端）。\n依据：home_v2_screen.dart:458-505、playback_context_tracker.dart',
  ),
  MechanismItem(
    title: '探索发现',
    summary:
        '只推你没听过的歌。拿你最常听的歌当「种子」，找标签和它相似的歌（一跳邻居，相似度阈值 0.25）；不够再从你的偏好标签里补。每周固定一批，不会天天变。',
    details:
        'discoverSongs：行为分最高 10 首已听歌为种子 → findSimilar（limit 8）→ 排除全部已听歌 → 偏好标签代表歌兜底 → 内容分补齐；缓存 key = ISO 周一日期（_weekKey）。\n依据：home_recommendation_service.dart:293-370、knowledge_recommendation_engine.dart:67-84',
  ),
  MechanismItem(
    title: '推荐算法：行为 + 标签怎么融合',
    summary:
        '每个推荐分 = 行为分 × 0.7 + 标签内容分 × 0.3。行为分来自你的播放、跳过、收藏、评分（收藏 +2、讨厌 -0.8、反复听加分…）；内容分是「你的标签偏好向量」和「歌曲标签」的匹配度。只有行为没有标签时纯看行为，只有标签没有行为时纯看标签——任何情况下都能推。相似歌曲用 Jaccard 相似度（共同标签占比）。所有模块共享去重：同一首歌不重复出现，同歌手最多 2 首、同专辑最多 1 首。',
    details:
        '_fusionScore α=0.7；_effectiveAlpha 自适应退化（无图谱→1.0，无行为→0.0）；_behaviorWeight 权重表；contentScore 余弦相似度（等价点积排序）；_selectWithDedup 全局去重。\n依据：knowledge_recommendation_engine.dart:134-165、home_recommendation_service.dart:144-205',
  ),
  MechanismItem(
    title: '歌曲标签（知识图谱）从哪来',
    summary:
        '首页推荐依赖每首歌的标签。这些标签不是从外部音乐库抓的，而是把你曲库里的歌分批发给 AI（每批 50 首），让 AI 按 8 个维度（情绪氛围、节奏能量、适合场景、歌词主题、演唱风格、乐器编曲、风格子类、相似歌手）给每首歌打 8-12 个标签，结果存在本机 song_knowledge.json。标签可导出给有同样曲库的人共享；导入或生成后推荐索引自动重建。',
    details:
        'AiKnowledgeService 单例 + 进度断点续传（knowledge_progress.json）；批生成容错解析「序号|标签」格式；3 批连续失败熔断；HomeRecommendationService.refreshKnowledgeFromCache 检测 lastUpdate 变化后重建索引。\n依据：ai_playlist_service.dart:70-257、song_knowledge_cache.dart、home_recommendation_service.dart:111-118',
  ),
];

const List<MechanismItem> _reportItems = [
  MechanismItem(
    title: '「有效播放」怎么判定',
    summary:
        '报告只统计「有效播放」：一首歌听到 80% 以上才计 1 次播放；听几秒就切走不算播放、只记「跳过」；时长未知时至少要实听 30 秒。统计在「播完」或「切歌」两个时点结算，所以数据是可靠的、不会虚增。',
    details:
        'player_provider.dart:1525-1546 _recordSongEnd：playedSeconds < total×0.8 → trackSkip；否则 trackSongPlay(completed:true)；totalSeconds≤0 时 playedSeconds≥30 兜底；_trackedSongId 防重复结算。\n依据：player_provider.dart:1302-1310,1525-1546,2337-2340,2929-2941',
  ),
  MechanismItem(
    title: '报告数据存在哪、会不会上传',
    summary:
        '全部保存在本机应用数据里（每首歌一条画像：播放次数、实听时长、按小时/天/月分布等），不会上传到任何服务器。为防止无限膨胀，400 天前的按天数据、2 年前的按月数据会被自动清理。卸载 App 会一并清空。',
    details:
        'SharedPreferences 键 rec_data_v3 / rec_skips_v3 / rec_time_v3；800ms 防抖保存；_saveData 裁剪。\n依据：recommendation_service.dart:31-36,684-780',
  ),
  MechanismItem(
    title: '各项统计是怎么算的',
    summary:
        '总时长=累计实听秒数（含没听完的部分）；播放次数=有效播放次数；完播率=完整播完次数÷播放次数；陪伴天数=从你第一次打开 App 那天算起；连续听歌=每天都至少有一次有效播放；时段偏好/曲风进化只按有效播放聚合；「新发现」=最近 7 天反复听、以前听得少的歌；「歌荒预警」=最近听的歌高度集中在前 10 首。注意：推荐画像有 30 天半衰期衰减（时间越久权重越低）——这只影响推荐排序，不影响报告里展示的累计数据。',
    details:
        '_buildReport（listening_report_screen.dart:309-425）全本地实时计算；_applyDecay（recommendation_service.dart:631-657）只作用于亲和度。\n依据：listening_report_screen.dart、recommendation_service.dart:789-906',
  ),
];

const List<MechanismItem> _storageItems = [
  MechanismItem(
    title: '离线下载：存哪、怎么存',
    summary:
        '下载的文件存在 App 文档目录 offline_music/，一首歌 = 音频 + 封面 + 歌词三个文件。默认 3 个并发下载。不支持断点续传——中断后要整首重下。已下载的歌播放时优先读本地文件、不耗流量。删除 App 时一并删除。',
    details:
        '_getSongPath 一律存 {songId}.mp3（内容为服务端原始格式，不转码）+ {songId}.jpg（300px）+ {songId}.lyrics.json；并发 1-5（parallel_downloads_count，默认 3）；WakelockPlus 保持常亮；已下载清单存 prefs offline_downloaded_songs；播放时 getPlayableUrl 命中即返回 file://。\n依据：offline_service.dart:53-249,420-493',
  ),
  MechanismItem(
    title: '在线播放与进度定位',
    summary:
        '在线播放的流由 ExoPlayer 直接处理（不落本地缓存）：拖动进度条时播放器向服务器发起 HTTP Range 分段请求来定位，服务器支持断点读取时 seek 即点即到。局域网（不转码）与远程转码流都走同一裸流路径，保证各网络环境下进度条行为一致、不会从头重放。',
    details:
        'playSong/_prepareCurrentSong/_buildAudioSourceForSong 对远程流统一用 AudioSource.uri 裸流直连 ExoPlayer，不再包 LockCachingAudioSource——后者在服务器不带 Accept-Ranges 头（局域网常见）时会把 seek 降级为完整 200 响应，导致进度条回 0:00 重播。旧缓存文件由 StreamingCacheCleaner.prune() 按 mtime 清理。\n依据：player_provider.dart:1888-1912、streaming_cache_cleaner.dart:10-62',
  ),
  MechanismItem(
    title: '转码（音质 / 流量）原理',
    summary:
        '「转码」是在你的服务器上完成的，App 只负责告诉服务器要什么码率和格式（mp3 / opus / aac 或原始直出）。连接局域网时一定不转码（强制原始音质，规则 1）；其余按设置判断：开启「智能模式」后连 WiFi 用高码率（音质好）、走蜂窝数据用低码率（省流量），网络切换自动换档。道理鱼下转码照常生效（规则 2 已取消）——转码流的快进由 App 走自研 /api 层 timeOffset 重起流实现（见详情），局域网/无损仍用 format=raw 直出 + Range 原生拖动。注意：开启转码时在线播放不落本地缓存——因为转码流拖动定位更可靠，这是刻意设计。',
    details:
        'getStreamUrl 拼 maxBitRate/format 参数到 /rest/stream；TranscodingService 监听系统网络切换（net.switch 埋点）并在 WiFi/移动网间切换生效码率。局域网覆盖（规则 1）：currentBitRate 在 isUsingLocalUrl 为 true 时强制 original(0)、getCurrentFormat 返回 null → 不拼转码参数；道理鱼（原规则 2 已取消）：无转码参数时 getStreamUrl 强制 format=raw 直出（有 Content-Length + Range 可精确 seek），有转码参数时透传转码——但 Subsonic 转码流是 chunked（无 Content-Length，ExoPlayer 解析不出时长 → 拖动后从 0:00 重播）且不认 Range，所以道理鱼转码场景（_isDaoliyuTranscodeRequested）播放/seek 都改走自研 /api/tracks/{id}/stream?token=<JWT>[&timeOffset=<秒>]：播放起流、seek 重发带 timeOffset 的新流（WebUI 同款机制，2026-08-11 实测），进度/歌词按基准偏移换算；该场景强制单曲模式（不走无缝 concat）。地址切换（启动探测/后台探测/网络变化 forceProbe）经 onActiveUrlChanged 通知转码层刷新。\n依据：subsonic_service.dart:748-805、transcoding_service.dart:76-104,226-250、player_provider.dart seek/_restartDaoliyuStream/playSong/_prepareCurrentSong、main.dart:264-267',
  ),
  MechanismItem(
    title: '封面图片缓存',
    summary:
        '封面统一按 300px 请求；磁盘缓存约 10000 张（基本不淘汰），超 512MB 自动清理最旧封面，内存再缓存 300 张加速滚动。同一封面全 App 共享同一条缓存，不重复下载；换密码不影响已缓存封面。',
    details:
        'coverCacheManager（flutter_cache_manager Config：stalePeriod 60 天、maxNrOfCacheObjects 10000、共享 http.Client 复用连接）；CoverCacheCleaner 启动时按 512MB 阈值清理；语义化 key=coverArt-<serverId>-<id>-<size>（serverId=md5(baseUrl+用户名)）；ImageCache 上限 300 张/150MB；封面统一 kCoverArtRequestSize=300。\n依据：image_cache.dart:10-70、services/cover_cache_cleaner.dart',
  ),
  MechanismItem(
    title: '本地数据库与同步',
    summary:
        'App 把曲库（歌曲/专辑/歌手/歌单）和你的收藏、评分缓存到本机 SQLite 数据库，打开页面不用每次问服务器。距上次同步超过 6 小时会自动后台全量刷新，也可以手动刷新。播放历史不存这里（存在应用设置里）。',
    details:
        'musly_library.db（v2）四表 songs/albums/artists/playlists；收藏/评分本地落库 + 服务端 star() 双向同步；_refreshAllDataInBackground 分页拉取、1000 行/事务批量写；启动后延迟 5 秒、距上次 >6 小时触发。\n依据：library_database_service.dart:15-159、library_provider.dart:560-672',
  ),
  MechanismItem(
    title: '存储清理',
    summary:
        '设置 → 下载与存储 里能看到并清理：图片缓存（实时扫描目录算占用）、离线下载（数量 + 占用，可全部删除）、BPM 缓存、本地音乐扫描目录。「清除全部缓存」会清掉图片缓存和 BPM 缓存，不会动离线下载。',
    details:
        '依据：settings_storage_tab.dart:81-145,272-276,501-634,710-826,828-936',
  ),
  MechanismItem(
    title: '音乐缓存开关（现状说明）',
    summary:
        '设置页「音乐缓存」开关目前是历史遗留设置项，尚未接入实际业务逻辑——它只影响该开关本身的显示状态，不影响任何播放/缓存行为。后续版本会接入或移除。',
    details:
        '依据：settings_storage_tab.dart:75,140 仅读写 cache_music_enabled，无业务代码消费（对照 docs/图片缓存与播放性能优化技术文档.md §8.7）。',
  ),
];

const List<MechanismItem> _aiItems = [
  MechanismItem(
    title: 'AI 歌单怎么生成',
    summary:
        '分两步。先在本地用场景关键词（开车/通勤/跑步/学习/睡前…共 21 个场景）给曲库打分，预筛出 250 首候选；再把「你的听歌画像（常听歌手、完播情况、评分、当前时段）+ 候选歌曲标签」一起发给 DeepSeek，让 AI 排出一份歌单。AI 只接触歌曲 ID 和标签、不接触音频。需要自己配置 DeepSeek API Key（默认 deepseek-v4-flash）。',
    details:
        '_filterByScene（标签命中关键词数降序取 250）；_buildUserProfile（完播 3 次以上、4 星以上、常跳过为负信号）；DeepSeek chat/completions，temperature 0.7、response_format json_object；返回 ID 校验属于曲库后按序成单。\n依据：ai_playlist_service.dart:291-335,337-437,475-576,595-617',
  ),
  MechanismItem(
    title: 'AI 知识库（标签）怎么生成',
    summary:
        '就是「歌曲标签从哪来」的生成流程：每 50 首一批发给 AI 打标签，每批立即保存，中断后下次从断点继续；连续 3 批失败会自动停止（熔断），避免白烧 API 费用。标签文件可导出/导入，方便和有同样曲库的人共享同一套标签。',
    details:
        '批处理 + 每批 flush 落盘 + 进度持久化；3 批失败熔断；导出 luobo_knowledge_*.json（settings_ai_playlist_tab.dart:519-559）。\n依据：ai_playlist_service.dart:70-147,154-257、ai_knowledge_service.dart',
  ),
  MechanismItem(
    title: '歌词从哪来',
    summary:
        '歌词按四级来源依次尝试：本地缓存 → 你的服务器 → LRCLIB（全球歌词库）→ 网易云（中文歌覆盖好，可开关）。每次远程拿到就写进本地缓存，所以看过的歌词离线也能看。滚动歌词按 LRC 时间轴定位；带字级时间戳的歌词支持逐字高亮卡拉OK效果。',
    details:
        '加载管线（synced_lyrics_view.dart:302-443）；LRC 解析 + 二分查找 + 200ms 节流（lyrics_manager.dart:48-204）；逐字 <mm:ss.xx> 解析与高亮（models/lyrics.dart:18-38、synced_lyrics_view.dart:1510-1574）。\n依据：synced_lyrics_view.dart、lyrics_manager.dart、lrclib_service.dart、netease_lyrics_service.dart',
  ),
];

const List<MechanismItem> _audioItems = [
  MechanismItem(
    title: '后台播放与锁屏',
    summary:
        '播放桥接系统媒体服务：锁屏界面、控制中心、耳机按键都能控制播放；支持变速播放且不变调（iOS 走系统后台音频服务，Android 保持原生媒体服务供车载使用）。',
    details: '依据：audio_handler.dart:24-208',
  ),
  MechanismItem(
    title: '响度均衡（ReplayGain）',
    summary:
        '每首歌/专辑带内嵌的响度增益值。开启后 App 自动换算音量倍率，让不同专辑之间音量一致——跳歌不会被突然变大的音量吓到。可调 preamp（整体微调）、防削波保护。',
    details:
        '倍率 = 10^(总增益dB/20)；preamp -15~15dB；防削波（倍率 ≤ 1/峰值）；无增益数据用 -6dB 兜底。\n依据：replay_gain_service.dart:69-110',
  ),
  MechanismItem(
    title: 'BPM 是怎么算的',
    summary:
        '不是分析音频波形算出来的，而是按曲风映射经验值（电子=128、嘻哈=85、摇滚=120、爵士=90…），再按时长兜底。精度有限，主要给 Auto DJ 混音做参考。结果缓存本机，可一键清除重算。',
    details: '依据：bpm_analyzer_service.dart:68-106',
  ),
  MechanismItem(
    title: 'Dolby Atmos 检测',
    summary: '仅检测 Android 设备是否支持/开启 Dolby Atmos 空间音频，'
        '作能力展示与提示，不改变音轨本身。',
    details: '依据：dolby_atmos_service.dart:20-35',
  ),
];

const List<MechanismItem> _connectivityItems = [
  MechanismItem(
    title: '服务器连接（Navidrome / Subsonic / Jellyfin）',
    summary:
        'Luobo 是纯播放器——所有音乐都存在你自己的服务器上（Navidrome，走 Subsonic 协议；也兼容 Jellyfin）。App 通过 API 拉曲库、播放、管理收藏，不上传你的任何听歌数据（听歌报告等全部本地）。连不上服务器时，只有已下载的歌能播。',
    details:
        '依据：subsonic_service.dart、jellyfin_service.dart、auth_provider.dart',
  ),
  MechanismItem(
    title: '网络电台',
    summary: '服务端维护的在线电台列表，点播后当普通流播放，不占曲库。',
    details: '电台走 getInternetRadioStations。\n依据：subsonic_service.dart:1296',
  ),
  MechanismItem(
    title: 'Auto DJ 自动续播',
    summary:
        '队列剩余不足（默认 2 首）时自动补歌，不会听断。5 种模式：随机曲库 / 相似歌曲 / 同风格 / 同歌手 / 智能混音。智能混音按「BPM 差 ≤15、能量差 ≤0.15」的规则链式选歌，风格相近、年代接近加分；最近补过的 100 首不重复。',
    details: '依据：auto_dj_service.dart:140-192,482-515,517-614',
  ),
  MechanismItem(
    title: '投屏（Cast / UPnP）',
    summary:
        '两种投屏。Google Cast：投到 Chromecast（走 Cast 协议）；UPnP/DLNA：在局域网自动发现音箱、电视等渲染器（组播搜索 + SOAP 控制）。两者都是把播放交给外部设备、App 做遥控。',
    details: '依据：cast_service.dart:72-308、upnp_service.dart:91-156,306-380',
  ),
  MechanismItem(
    title: '车载（Android Auto / 车载模式）',
    summary:
        'Android Auto：通过系统原生媒体服务把播放状态和曲库推送到车载屏，在车上直接控制。车载模式：App 内的一键全屏简化播放页，进入后屏幕常亮、界面更适合驾驶操作，下拉即可退出。',
    details: '依据：android_auto_service.dart:55-352、car_mode_screen.dart:57-109',
  ),
];

const List<MechanismItem> _diagnosticsItems = [
  MechanismItem(
    title: '诊断日志系统',
    summary:
        'App 内置一套本地日志系统，记录播放、网络、性能等事件（每条带全局序号、会话 ID、时间戳），落盘成 JSONL 文件并自动轮转（单文件 1MB、最多 5 个）。数据只存在你的设备上，不做任何网络上报。遇到问题时可从「诊断」页导出日志文件发给开发者排查。',
    details:
        'DiagnosticsService.record() 统一埋点；内存 500 条环形缓冲 + 200ms 异步批量落盘；会话 ID（PlaybackSession ps-*/NetSession ns-*/AppSession as-*）；导出三态（移动端 SAF / 桌面目录 / Web 剪贴板）。\n依据：diagnostics_service.dart:159-429、file_store_io.dart、docs/性能监控与日志系统技术文档.md',
  ),
  MechanismItem(
    title: '性能监控',
    summary:
        '逐帧监控渲染耗时：单帧超过 50ms 记一次卡顿、25-50ms 记慢帧（按秒聚合防刷屏）；播放卡住、缓冲停滞、缓存清理撞上正在播放的文件等异常也会自动记录；崩溃被全局捕获写进日志，崩溃前最后的事件不会丢。',
    details:
        'SchedulerBinding.addTimingsCallback 采 build+raster；派生检测器 audio.silentPlayback / audio.stall / cache.prune；三路异常捕获（runZonedGuarded / FlutterError / PlatformDispatcher）。\n依据：metrics_collector.dart:124-180、docs/性能监控与日志系统技术文档.md',
  ),
  MechanismItem(
    title: '匿名统计与设备 ID',
    summary:
        '「匿名统计」开关控制的是本地数据统计，可关闭；设备 ID 是一个随机生成的匿名标识（不是手机号/IMEI），用于在本地区分设备。当前版本统计与设备 ID 均仅存本机。',
    details: '依据：analytics_service.dart、settings_about_tab.dart:110-229',
  ),
];

// ── 组装 ──────────────────────────────────────────────────────────────

List<_MechanismGroup> _buildGroups(AppLocalizations l10n) {
  return [
    _MechanismGroup(
      title: l10n.mechanicsGroupRecommendation,
      icon: CupertinoIcons.house_fill,
      items: _homeItems,
    ),
    _MechanismGroup(
      title: l10n.mechanicsGroupListeningReport,
      icon: CupertinoIcons.chart_bar,
      items: _reportItems,
    ),
    _MechanismGroup(
      title: l10n.mechanicsGroupStorage,
      icon: CupertinoIcons.folder,
      items: _storageItems,
    ),
    _MechanismGroup(
      title: l10n.mechanicsGroupAi,
      icon: Icons.auto_awesome,
      items: _aiItems,
    ),
    _MechanismGroup(
      title: l10n.mechanicsGroupAudio,
      icon: CupertinoIcons.waveform,
      items: _audioItems,
    ),
    _MechanismGroup(
      title: l10n.mechanicsGroupConnectivity,
      icon: Icons.airplay,
      items: _connectivityItems,
    ),
    _MechanismGroup(
      title: l10n.mechanicsGroupDiagnostics,
      icon: CupertinoIcons.shield,
      items: _diagnosticsItems,
    ),
  ];
}

// ── 视图组件 ──────────────────────────────────────────────────────────

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _secondaryText(BuildContext context) =>
    _isDark(context) ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

Widget _sectionHeader(BuildContext context, _MechanismGroup group) {
  final accent = Theme.of(context).colorScheme.primary;
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(group.icon, color: accent, size: 15),
        ),
        const SizedBox(width: 8),
        Text(
          group.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: _secondaryText(context),
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

Widget _groupCard(BuildContext context, _MechanismGroup group) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: _isDark(context) ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < group.items.length; i++) ...[
              if (i > 0) _divider(context),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  group.items[i].title,
                  // 飞牛实测行标题 14dp（同机同字体，见方案 §9.21.1）；
                  // 原来硬编码 16 偏大 2dp
                  style: LuoboType.body,
                ),
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: _secondaryText(context),
                ),
                onTap: () => NavigationHelper.push(
                  context,
                  SettingsMechanismDetailScreen(item: group.items[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _summaryCard(BuildContext context, MechanismItem item) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _isDark(context) ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      item.summary,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

Widget _techCard(
    BuildContext context, AppLocalizations l10n, MechanismItem item) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: _isDark(context) ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          // ExpansionTile 默认展开动画的波纹颜色随主题，这里用透明避免突兀
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(
              CupertinoIcons.gear_alt,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.mechanicsTechDetails, style: LuoboType.body),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.details,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: _secondaryText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _divider(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 56),
    child: Container(
      height: 0.5,
      color: _isDark(context) ? AppTheme.darkDivider : AppTheme.lightDivider,
    ),
  );
}

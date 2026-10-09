// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Luobo';

  @override
  String get emulatorDetected => '检测到模拟器';

  @override
  String get emulatorNotAllowed => '此应用无法在模拟器上运行。\n请使用真实设备。';

  @override
  String get goodMorning => '早上好';

  @override
  String get goodAfternoon => '下午好';

  @override
  String get goodEvening => '晚上好';

  @override
  String get forYou => '为你推荐';

  @override
  String get quickPicks => '快速选择';

  @override
  String get discoverMix => '发现混音';

  @override
  String get morningVibes => '清晨漫步';

  @override
  String get afternoonVibes => '午后时光';

  @override
  String get eveningVibes => '傍晚小憩';

  @override
  String get nightVibes => '深夜电台';

  @override
  String get recentlyPlayed => '最近播放';

  @override
  String get yourPlaylists => '你的歌单';

  @override
  String get roaming => '漫游';

  @override
  String get roamingSubtitle => '随机漫游曲库';

  @override
  String get quickStart => '快速开始';

  @override
  String get favoritePlaylists => '收藏的歌单';

  @override
  String get sectionAlbums => '专辑';

  @override
  String get sectionEPs => 'EP';

  @override
  String get sectionSingles => '单曲';

  @override
  String get madeForYou => '为你制作';

  @override
  String get dailyRecommendation => '今日推荐';

  @override
  String get continueListening => '继续播放';

  @override
  String get commuteMix => '通勤活力';

  @override
  String get studyMix => '专注学习';

  @override
  String get sleepMix => '睡前放松';

  @override
  String get favoritesMix => '你的最爱';

  @override
  String get discover => '探索发现';

  @override
  String get aiPlaylist => 'AI 歌单';

  @override
  String get aiPlaylistSubtitle => '描述你想听的歌';

  @override
  String get generating => '生成中…';

  @override
  String get addToCurrentQueue => '加入播放列表';

  @override
  String get addedToQueue => '已加入播放队列';

  @override
  String songCount(int count) {
    return '$count 首';
  }

  @override
  String get dailySubtitle => '每日更新';

  @override
  String get commuteSubtitle => '高能节奏';

  @override
  String get studySubtitle => '专注不扰';

  @override
  String get sleepSubtitle => '舒缓入眠';

  @override
  String get favoritesSubtitle => '收藏常听';

  @override
  String get discoverSubtitle => '未听过的新歌';

  @override
  String get dailySlogan1 => '让今天从一首好歌开始';

  @override
  String get dailySlogan2 => '每天都有新惊喜';

  @override
  String get dailySlogan3 => '今天想听点什么？';

  @override
  String get commuteSlogan1 => '让通勤路上电量满格';

  @override
  String get commuteSlogan2 => '出发之前，先加满油';

  @override
  String get commuteSlogan3 => '把平凡的路走成自己的节奏';

  @override
  String get studySlogan1 => '世界安静下来，只剩你和音乐';

  @override
  String get studySlogan2 => '心无旁骛，音符相伴';

  @override
  String get studySlogan3 => '让专注有它的 BGM';

  @override
  String get sleepSlogan1 => '让今晚的梦轻柔一点';

  @override
  String get sleepSlogan2 => '慢慢来，睡个好觉';

  @override
  String get sleepSlogan3 => '夜色正好，适合一首慢歌';

  @override
  String get favoritesSlogan1 => '收藏的都是心动';

  @override
  String get favoritesSlogan2 => '常听的都在这里';

  @override
  String get favoritesSlogan3 => '你爱过的歌都算数';

  @override
  String get discoverSlogan1 => '下一首可能是你的新欢';

  @override
  String get discoverSlogan2 => '去没去过的地方逛逛';

  @override
  String get discoverSlogan3 => '换个口味，听点新鲜的';

  @override
  String get topRated => '评分最高';

  @override
  String get noContentAvailable => '暂无内容';

  @override
  String get tryRefreshing => '请刷新或检查服务器连接';

  @override
  String get refresh => '刷新';

  @override
  String refreshComplete(int albumCount, int songCount) {
    return '$albumCount 张专辑，$songCount 首歌曲';
  }

  @override
  String get refreshFailed => '刷新失败';

  @override
  String get refreshLocalComplete => '本地曲库已刷新';

  @override
  String get errorLoadingSongs => '加载歌曲出错';

  @override
  String get noSongsInGenre => '该分类没有歌曲';

  @override
  String get errorLoadingAlbums => '加载专辑出错';

  @override
  String get noTopRatedAlbums => '暂无高分专辑';

  @override
  String get login => '登录';

  @override
  String get serverUrl => '服务器地址';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get selectCertificate => '选择 TLS/SSL 证书';

  @override
  String failedToSelectCertificate(String error) {
    return '选择证书失败：$error';
  }

  @override
  String get serverUrlMustStartWith => '服务器地址必须以 http:// 或 https:// 开头';

  @override
  String get failedToConnect => '连接失败';

  @override
  String get library => '音乐库';

  @override
  String get search => '搜索';

  @override
  String get settings => '设置';

  @override
  String get albums => '专辑';

  @override
  String get artists => '艺术家';

  @override
  String get songs => '歌曲';

  @override
  String get playlists => '歌单';

  @override
  String get genres => '分类';

  @override
  String get years => '年份';

  @override
  String get favorites => '收藏';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get queue => '播放队列';

  @override
  String get lyrics => '歌词';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get next => '下一首';

  @override
  String get previous => '上一首';

  @override
  String get shuffle => '随机播放';

  @override
  String get repeat => '循环';

  @override
  String get repeatOne => '单曲循环';

  @override
  String get repeatOff => '关闭循环';

  @override
  String get addToPlaylist => '添加到歌单';

  @override
  String get removeFromPlaylist => '从歌单移除';

  @override
  String get addToFavorites => '添加到收藏';

  @override
  String get removeFromFavorites => '从收藏中移除';

  @override
  String get download => '下载';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get save => '保存';

  @override
  String get close => '关闭';

  @override
  String get general => '通用';

  @override
  String get appearance => '外观';

  @override
  String get playback => '播放';

  @override
  String get storage => '存储';

  @override
  String get about => '关于';

  @override
  String get darkMode => '深色模式';

  @override
  String get language => '语言';

  @override
  String get version => '版本';

  @override
  String get githubRepository => 'GitHub 仓库';

  @override
  String get reportIssue => '报告问题';

  @override
  String get unknownArtist => '未知歌手';

  @override
  String get unknownAlbum => '未知专辑';

  @override
  String get playAll => '播放全部';

  @override
  String get shuffleAll => '随机播放全部';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortByName => '名称';

  @override
  String get sortByArtist => '艺术家';

  @override
  String get sortByAlbum => '专辑';

  @override
  String get sortByDate => '日期';

  @override
  String get sortByDuration => '时长';

  @override
  String get ascending => '升序';

  @override
  String get descending => '降序';

  @override
  String get noLyricsAvailable => '暂无歌词';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get noResults => '无结果';

  @override
  String get searchHint => '搜索歌曲、专辑、艺术家...';

  @override
  String get allSongs => '全部歌曲';

  @override
  String get allAlbums => '全部专辑';

  @override
  String get allArtists => '全部艺术家';

  @override
  String trackNumber(int number) {
    return '第 $number 首';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 首歌曲',
      one: '1 首歌曲',
      zero: '无歌曲',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张专辑',
      one: '1 张专辑',
      zero: '无专辑',
    );
    return '$_temp0';
  }

  @override
  String get topArtistsTitle => '常听';

  @override
  String playsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次',
      one: '1 次',
      zero: '未播放',
    );
    return '$_temp0';
  }

  @override
  String get logout => '退出登录';

  @override
  String get confirmLogout => '确定要退出登录吗？';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get offlineMode => '离线模式';

  @override
  String get radio => '电台';

  @override
  String get audiobooks => '有声书';

  @override
  String playedTo(String position) {
    return '已播至 $position';
  }

  @override
  String get finished => '已听完';

  @override
  String chapterCount(int count) {
    return '$count 章';
  }

  @override
  String chapterX(int count) {
    return '第 $count 章';
  }

  @override
  String get failedToLoadAudiobooks => '有声书加载失败';

  @override
  String get failedToLoadChapters => '章节加载失败，请重试';

  @override
  String get exitAudiobookFirst => '请先退出有声书';

  @override
  String get jumpToChapter => '跳转章节';

  @override
  String get searchChapters => '搜索章节/段子';

  @override
  String get noSearchResults => '未找到匹配的章节';

  @override
  String get changelog => '更新日志';

  @override
  String get platform => '平台';

  @override
  String get server => '服务器';

  @override
  String get display => '显示';

  @override
  String get playerInterface => '播放器界面';

  @override
  String get smartRecommendations => '智能推荐';

  @override
  String get showVolumeSlider => '显示音量滑块';

  @override
  String get showVolumeSliderSubtitle => '在正在播放界面显示音量控制';

  @override
  String get showStarRatings => '显示星级评分';

  @override
  String get showStarRatingsSubtitle => '为歌曲评分并查看评分';

  @override
  String get showMiniPlayerHeart => '显示收藏按钮';

  @override
  String get showMiniPlayerHeartSubtitle => '在迷你播放器中添加到收藏';

  @override
  String get showMiniPlayerRepeat => '显示循环按钮';

  @override
  String get showMiniPlayerRepeatSubtitle => '在迷你播放器中切换循环模式';

  @override
  String get showMiniPlayerShuffle => '显示随机按钮';

  @override
  String get showMiniPlayerShuffleSubtitle => '在迷你播放器中切换随机播放';

  @override
  String get enableRecommendations => '启用推荐';

  @override
  String get enableRecommendationsSubtitle => '获取个性化音乐推荐';

  @override
  String get listeningData => '收听数据';

  @override
  String totalPlays(int count) {
    return '共播放 $count 次';
  }

  @override
  String get clearListeningHistory => '清除收听历史';

  @override
  String get confirmClearHistory => '这将重置您的所有收听数据和推荐。确定吗？';

  @override
  String get historyCleared => '收听历史已清除';

  @override
  String get discordStatus => 'Discord 状态';

  @override
  String get discordStatusSubtitle => '在 Discord 个人资料上显示正在播放的歌曲';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get yourLibrary => '你的音乐库';

  @override
  String get filterAll => '全部';

  @override
  String get faves => '收藏';

  @override
  String get filterPlaylists => '歌单';

  @override
  String get filterAlbums => '专辑';

  @override
  String get filterArtists => '艺术家';

  @override
  String get likedSongs => '喜欢的歌曲';

  @override
  String get localMusicLibrary => '本地音乐库';

  @override
  String get mergeLocalLibrary => '与服务器合并';

  @override
  String get mergeLocalLibrarySubtitle => '将本地音乐与服务器音乐一起显示';

  @override
  String get localMusicStats => '本地音乐文件';

  @override
  String get addMusicFolder => '添加音乐文件夹';

  @override
  String get rescanLocalMusic => '重新扫描本地音乐';

  @override
  String get localLibraryEmpty => '音乐库为空';

  @override
  String get localLibraryEmptySubtitle => '未找到本地音乐文件。点击下方按钮重新扫描。';

  @override
  String get libraryEmpty => '音乐库为空';

  @override
  String get libraryEmptySubtitle => '添加一些歌曲开始吧。';

  @override
  String get scanForMusic => '扫描音乐';

  @override
  String get radioStations => '电台';

  @override
  String get playlist => '歌单';

  @override
  String get internetRadio => '网络电台';

  @override
  String get newPlaylist => '新建歌单';

  @override
  String get playlistName => '歌单名称';

  @override
  String get create => '创建';

  @override
  String get deletePlaylist => '删除歌单';

  @override
  String deletePlaylistConfirmation(String name) {
    return '确定要删除歌单「$name」吗？';
  }

  @override
  String playlistDeleted(String name) {
    return '歌单「$name」已删除';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return '创建歌单出错：$error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return '删除歌单出错：$error';
  }

  @override
  String playlistCreated(String name) {
    return '歌单「$name」已创建';
  }

  @override
  String get searchTitle => '搜索';

  @override
  String get searchPlaceholder => '艺术家、歌曲、专辑';

  @override
  String get tryDifferentSearch => '尝试不同的搜索';

  @override
  String get noSuggestions => '无建议';

  @override
  String get browseCategories => '浏览分类';

  @override
  String get liveSearchSection => '搜索';

  @override
  String get liveSearch => '实时搜索';

  @override
  String get liveSearchSubtitle => '输入时实时更新结果，而非显示下拉列表';

  @override
  String get categoryMadeForYou => '为你制作';

  @override
  String get categoryNewReleases => '新歌首发';

  @override
  String get categoryTopRated => '评分最高';

  @override
  String get categoryGenres => '分类';

  @override
  String get categoryFavorites => '收藏';

  @override
  String get categoryRadio => '电台';

  @override
  String get settingsTitle => '设置';

  @override
  String get tabPlayback => '播放';

  @override
  String get tabStorage => '存储';

  @override
  String get tabServer => '服务器';

  @override
  String get tabDisplay => '显示';

  @override
  String get tabAiPlaylist => 'AI 歌单';

  @override
  String get tabAbout => '关于';

  @override
  String get tabDiagnostics => '诊断';

  @override
  String get settingsGroupServer => '账号与服务器';

  @override
  String get settingsServerSettings => '服务器设置';

  @override
  String get serverManagement => '服务器管理';

  @override
  String get noSavedProfiles => '暂无已保存的服务器配置';

  @override
  String get connectedSuccessfully => '连接成功';

  @override
  String get settingsGroupPlayback => '播放与音质';

  @override
  String get settingsPlaybackSettings => '播放设置';

  @override
  String get settingsStreamingEntry => '音质与流媒体';

  @override
  String get settingsGroupStorage => '下载与存储';

  @override
  String get settingsStorageEntry => '下载与存储';

  @override
  String get settingsGroupDisplay => '显示与外观';

  @override
  String get settingsDisplayEntry => '播放器界面';

  @override
  String get settingsGroupAbout => '关于 Luobo';

  @override
  String get settingsGroupAi => 'AI 智能';

  @override
  String get settingsAiEntry => 'AI 歌单与知识库';

  @override
  String get settingsGroupSupport => '支持与帮助';

  @override
  String get settingsMechanicsEntry => '机制说明';

  @override
  String get mechanicsGroupRecommendation => '首页推荐';

  @override
  String get mechanicsGroupListeningReport => '听歌报告';

  @override
  String get mechanicsGroupStorage => '下载与存储';

  @override
  String get mechanicsGroupAi => 'AI 智能';

  @override
  String get mechanicsGroupAudio => '音频';

  @override
  String get mechanicsGroupConnectivity => '连接与投送';

  @override
  String get mechanicsGroupDiagnostics => '诊断与隐私';

  @override
  String get mechanicsTechDetails => '技术细节';

  @override
  String get diagnosticsTitle => '诊断';

  @override
  String get diagnosticsSearchHint => '搜索事件类型/内容';

  @override
  String get diagnosticsNoLogs => '暂无日志';

  @override
  String diagnosticsExported(Object path) {
    return '日志已导出：$path';
  }

  @override
  String get diagnosticsExportFailed => '导出失败，请检查存储空间';

  @override
  String get diagnosticsCopied => '日志已复制到剪贴板（最近 2000 条）';

  @override
  String get diagnosticsClearTitle => '清空诊断日志';

  @override
  String get diagnosticsClearMessage => '将删除本机全部诊断日志与指标快照，且不可恢复。建议先导出。';

  @override
  String get diagnosticsClearAction => '清空';

  @override
  String get diagnosticsMetricFps => 'FPS';

  @override
  String get diagnosticsMetricJankRate => 'jank率';

  @override
  String get diagnosticsMetricRequests => '请求数';

  @override
  String get diagnosticsMetricNetP90 => '网络p90';

  @override
  String get diagnosticsMetricErrorRate => '错误率';

  @override
  String get diagnosticsAll => '全部';

  @override
  String get diagnosticsLevelDebug => 'debug';

  @override
  String get diagnosticsLevelInfo => 'info';

  @override
  String get diagnosticsLevelWarn => 'warn';

  @override
  String get diagnosticsLevelError => 'error';

  @override
  String get diagnosticsTooltipCopy => '复制到剪贴板';

  @override
  String get diagnosticsTooltipExport => '导出到文件';

  @override
  String get diagnosticsTooltipClear => '清空';

  @override
  String renderError(Object err) {
    return '渲染异常\n$err';
  }

  @override
  String get sectionAutoDj => '自动播放';

  @override
  String get autoDjMode => '自动播放模式';

  @override
  String get autoDjModeOff => '关闭';

  @override
  String get autoDjModeShuffleLibrary => '随机播放曲库';

  @override
  String get autoDjModeSimilarSongs => '相似歌曲';

  @override
  String get autoDjModeSameGenre => '相同流派';

  @override
  String get autoDjModeSameArtist => '相同艺术家';

  @override
  String get autoDjModeSmartMix => '智能混合';

  @override
  String songsToAdd(int count) {
    return '添加歌曲数：$count';
  }

  @override
  String get sectionReplayGain => '音量标准化 (REPLAYGAIN)';

  @override
  String get replayGainMode => '模式';

  @override
  String preamp(String value) {
    return '前置增益：$value dB';
  }

  @override
  String get preventClipping => '防止削波';

  @override
  String fallbackGain(String value) {
    return '备用增益：$value dB';
  }

  @override
  String get sectionStreamingQuality => '流媒体质量';

  @override
  String get enableTranscoding => '启用转码';

  @override
  String get qualityWifi => 'WiFi 质量';

  @override
  String get qualityMobile => '移动网络质量';

  @override
  String get format => '格式';

  @override
  String get transcodingSubtitle => '降低质量以减少数据使用';

  @override
  String get modeOff => '关闭';

  @override
  String get modeTrack => '单曲';

  @override
  String get modeAlbum => '专辑';

  @override
  String get sectionServerConnection => '服务器连接';

  @override
  String get serverType => '服务器类型';

  @override
  String get notConnected => '未连接';

  @override
  String get unknown => '未知';

  @override
  String get sectionMusicFolders => '音乐文件夹';

  @override
  String get musicFolders => '音乐文件夹';

  @override
  String get noMusicFolders => '未找到音乐文件夹';

  @override
  String get sectionSavedProfiles => '已保存的配置';

  @override
  String get switchProfile => '切换配置';

  @override
  String get switchServer => '切换服务器';

  @override
  String get addProfile => '添加配置';

  @override
  String get shareQrCode => '分享二维码';

  @override
  String get scanQrCode => '扫码添加';

  @override
  String get qrCodeTitle => '服务器二维码';

  @override
  String get qrCodeSubtitle => '扫描此二维码即可添加服务器配置';

  @override
  String get saveToGallery => '保存到相册';

  @override
  String get savedToGallery => '二维码已保存到相册';

  @override
  String get failedToSaveQr => '保存二维码失败';

  @override
  String get scanFromCamera => '相机';

  @override
  String get scanFromGallery => '相册';

  @override
  String get invalidQrCode => '无效的二维码，不是有效的服务器配置。';

  @override
  String get qrConfigImported => '服务器配置导入成功';

  @override
  String switchProfileConfirmation(String profile) {
    return '连接到「$profile」？';
  }

  @override
  String get sectionAccount => '账户';

  @override
  String get logoutConfirmation => '确定要退出登录吗？这也将清除所有缓存数据。';

  @override
  String get sectionCacheSettings => '缓存设置';

  @override
  String get imageCache => '图片缓存';

  @override
  String get musicCache => '音乐缓存';

  @override
  String get bpmCache => 'BPM 缓存';

  @override
  String get saveAlbumCovers => '本地保存专辑封面';

  @override
  String get saveSongMetadata => '本地保存歌曲元数据';

  @override
  String get saveBpmAnalysis => '本地保存 BPM 分析';

  @override
  String get sectionCacheCleanup => '缓存清理';

  @override
  String get clearAllCache => '清除所有缓存';

  @override
  String get allCacheCleared => '所有缓存已清除';

  @override
  String get sectionOfflineDownloads => '离线下载';

  @override
  String get downloadedSongs => '已下载歌曲';

  @override
  String downloadingLibrary(int progress, int total) {
    return '正在下载音乐库... $progress/$total';
  }

  @override
  String get downloadAllLibrary => '下载全部音乐库';

  @override
  String downloadLibraryConfirm(int count) {
    return '这将下载 $count 首歌曲到您的设备。这可能需要一段时间并占用大量存储空间。\n\n是否继续？';
  }

  @override
  String get keepScreenOnDuringDownload => '下载时保持屏幕常亮';

  @override
  String get keepScreenOnDuringDownloadSubtitle => '防止设备锁屏导致下载失败';

  @override
  String get parallelDownloads => '并行下载';

  @override
  String get parallelDownloadsSubtitle => '同时下载多首歌曲';

  @override
  String get downloadSingular => '个下载';

  @override
  String get downloadPlural => '个下载';

  @override
  String get slowerButStable => '较慢但更稳定';

  @override
  String get fasterButMoreData => '较快但更耗流量';

  @override
  String get libraryDownloadStarted => '音乐库下载已开始';

  @override
  String get deleteDownloads => '删除所有下载';

  @override
  String get downloadsDeleted => '所有下载已删除';

  @override
  String get noSongsAvailable => '暂无可用歌曲';

  @override
  String get sectionBpmAnalysis => 'BPM 分析';

  @override
  String get cachedBpms => '已缓存的 BPM';

  @override
  String get cacheAllBpms => '缓存所有 BPM';

  @override
  String get clearBpmCache => '清除 BPM 缓存';

  @override
  String get bpmCacheCleared => 'BPM 缓存已清除';

  @override
  String downloadedStats(int count, String size) {
    return '$count 首歌曲 • $size';
  }

  @override
  String get sectionInformation => '信息';

  @override
  String get sectionDeveloper => '开发者';

  @override
  String get sectionLinks => '链接';

  @override
  String get githubRepo => 'GitHub 仓库';

  @override
  String get playingFrom => '正在播放来自';

  @override
  String get live => '直播';

  @override
  String get streamingLive => '正在直播';

  @override
  String get stopRadio => '停止电台';

  @override
  String get removeFromLiked => '从喜欢的歌曲中移除';

  @override
  String get addToLiked => '添加到喜欢的歌曲';

  @override
  String get playNext => '下一首播放';

  @override
  String get addToQueue => '添加到队列';

  @override
  String get goToAlbum => '前往专辑';

  @override
  String get goToArtist => '前往艺术家';

  @override
  String get rateSong => '为歌曲评分';

  @override
  String rateSongValue(int rating, String stars) {
    return '为歌曲评分（$rating $stars）';
  }

  @override
  String get ratingRemoved => '评分已移除';

  @override
  String rated(int rating, String stars) {
    return '已评分 $rating $stars';
  }

  @override
  String get removeRating => '移除评分';

  @override
  String get downloaded => '已下载';

  @override
  String downloading(int percent) {
    return '正在下载... $percent%';
  }

  @override
  String get removeDownload => '移除下载';

  @override
  String get removeDownloadConfirm => '从离线存储中移除这首歌曲？';

  @override
  String get downloadRemoved => '下载已移除';

  @override
  String downloadedTitle(String title) {
    return '已下载「$title」';
  }

  @override
  String get downloadFailed => '下载失败';

  @override
  String downloadError(Object error) {
    return '下载错误：$error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return '已将「$title」添加到 $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return '添加到歌单出错：$error';
  }

  @override
  String get noPlaylists => '没有可用的歌单';

  @override
  String get createNewPlaylist => '创建新歌单';

  @override
  String artistNotFound(String name) {
    return '未找到艺术家「$name」';
  }

  @override
  String errorSearchingArtist(Object error) {
    return '搜索艺术家出错：$error';
  }

  @override
  String get selectArtist => '选择艺术家';

  @override
  String get removedFromFavorites => '已从收藏中移除';

  @override
  String get addedToFavorites => '已添加到收藏';

  @override
  String get star => '星';

  @override
  String get stars => '星';

  @override
  String get albumNotFound => '未找到专辑';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get topSongs => '热门歌曲';

  @override
  String get connected => '已连接';

  @override
  String get failedToLoadProfiles => '加载已保存的服务器失败';

  @override
  String get noSongPlaying => '当前无歌曲播放';

  @override
  String get internetRadioUppercase => '网络电台';

  @override
  String get playingNext => '即将播放';

  @override
  String get createPlaylistTitle => '创建歌单';

  @override
  String get playlistNameHint => '歌单名称';

  @override
  String playlistCreatedWithSong(String name) {
    return '已创建歌单「$name」并添加了这首歌曲';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return '加载歌单出错：$error';
  }

  @override
  String get playlistNotFound => '未找到歌单';

  @override
  String get noSongsInPlaylist => '此歌单中没有歌曲';

  @override
  String get noFavoriteSongsYet => '还没有喜欢的歌曲';

  @override
  String get noFavoriteAlbumsYet => '还没有喜欢的专辑';

  @override
  String get listeningHistory => '播放历史';

  @override
  String get noListeningHistory => '暂无播放历史';

  @override
  String get songsWillAppearHere => '您播放的歌曲将显示在这里';

  @override
  String get sortByArtistAZ => '艺术家 (A-Z)';

  @override
  String get sortByArtistZA => '艺术家 (Z-A)';

  @override
  String get sortByAlbumAZ => '专辑 (A-Z)';

  @override
  String get sortByAlbumZA => '专辑 (Z-A)';

  @override
  String get recentlyAdded => '最近添加';

  @override
  String get noSongsFound => '未找到歌曲';

  @override
  String get noAlbumsFound => '未找到专辑';

  @override
  String get noHomepageUrl => '没有可用的首页链接';

  @override
  String get playStation => '播放电台';

  @override
  String get openHomepage => '打开首页';

  @override
  String get copyStreamUrl => '复制流地址';

  @override
  String get failedToLoadRadioStations => '加载电台失败';

  @override
  String get noRadioStations => '暂无电台';

  @override
  String get noRadioStationsHint => '请在 Navidrome 服务器设置中添加电台，即可在这里看到。';

  @override
  String get connectToServerSubtitle => '连接到您的 Subsonic 服务器';

  @override
  String get pleaseEnterServerUrl => '请输入服务器地址';

  @override
  String get invalidUrlFormat => 'URL 必须以 http:// 或 https:// 开头';

  @override
  String get pleaseEnterUsername => '请输入用户名';

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String get legacyAuthentication => '旧版认证';

  @override
  String get legacyAuthSubtitle => '用于较旧的 Subsonic 服务器';

  @override
  String get allowSelfSignedCerts => '允许自签名证书';

  @override
  String get allowSelfSignedSubtitle => '用于具有自定义 TLS/SSL 证书的服务器';

  @override
  String get advancedOptions => '高级选项';

  @override
  String get customTlsCertificate => '自定义 TLS/SSL 证书';

  @override
  String get customCertificateSubtitle => '为使用非标准 CA 的服务器上传自定义证书';

  @override
  String get selectCertificateFile => '选择证书文件';

  @override
  String get clientCertificate => '客户端证书 (mTLS)';

  @override
  String get clientCertificateSubtitle => '使用证书对此客户端进行身份验证（需要支持 mTLS 的服务器）';

  @override
  String get selectClientCertificate => '选择客户端证书';

  @override
  String get clientCertPassword => '证书密码（可选）';

  @override
  String failedToSelectClientCert(String error) {
    return '选择客户端证书失败：$error';
  }

  @override
  String get connect => '连接';

  @override
  String get lanUrl => '局域网地址（可选）';

  @override
  String get lanUrlHint => 'http://192.168.x.x:4533';

  @override
  String get serverUrlHint => 'https://your-server.com';

  @override
  String get usernameHint => '例如：admin';

  @override
  String get passwordHint => '请输入密码';

  @override
  String get profileNameLabel => '配置名称（可选）';

  @override
  String get profileNameHint => '例如：家庭、办公室、VPN';

  @override
  String get or => '或者';

  @override
  String get privacyFirst => '隐私优先';

  @override
  String get privacySubtitle => '您的数据始终由您掌控。';

  @override
  String get noDataSelling => '不出售数据';

  @override
  String get noDataSellingDesc => '我们绝不会向第三方出售、分享或转让您的个人数据。';

  @override
  String get localFirstStorage => '本地优先存储';

  @override
  String get localFirstStorageDesc => '您的音乐库和登录凭证保存在本地设备上。';

  @override
  String get anonymousAnalytics => '匿名分析';

  @override
  String get anonymousAnalyticsDesc => '经您同意后，我们仅收集匿名的崩溃报告和使用统计，不包含任何个人标识信息。';

  @override
  String get readFullPrivacyPolicy => '阅读完整隐私政策';

  @override
  String get viewCompleteDetails => '在网站上查看完整详情';

  @override
  String get agreeAndContinue => '我已了解，继续使用';

  @override
  String get declineAndExit => '拒绝并退出';

  @override
  String get useLocalFiles => '使用本地文件';

  @override
  String get startingScan => '开始扫描...';

  @override
  String get storagePermissionRequired => '需要存储权限才能扫描本地文件';

  @override
  String get noMusicFilesFound => '在您的设备上未找到音乐文件';

  @override
  String get remove => '移除';

  @override
  String failedToSetRating(Object error) {
    return '设置评分失败：$error';
  }

  @override
  String get home => '首页';

  @override
  String get playlistsSection => '歌单';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展开';

  @override
  String get createPlaylist => '创建歌单';

  @override
  String get likedSongsSidebar => '喜欢的歌曲';

  @override
  String playlistSongsCount(int count) {
    return '歌单 • $count 首歌曲';
  }

  @override
  String get failedToLoadLyrics => '加载歌词失败';

  @override
  String get lyricsNotFoundSubtitle => '无法找到这首歌曲的歌词';

  @override
  String get backToCurrent => '返回当前';

  @override
  String get exitFullscreen => '退出全屏';

  @override
  String get fullscreen => '全屏';

  @override
  String get noLyrics => '无歌词';

  @override
  String get internetRadioMiniPlayer => '网络电台';

  @override
  String get liveBadge => '直播';

  @override
  String get localFilesModeBanner => '本地文件模式';

  @override
  String get offlineModeBanner => '离线模式 - 仅播放已下载的音乐';

  @override
  String get updateAvailable => '有可用更新';

  @override
  String get updateAvailableSubtitle => '新版本的 Luobo 已可用！';

  @override
  String updateCurrentVersion(String version) {
    return '当前版本：v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return '最新版本：v$version';
  }

  @override
  String get whatsNew => '更新内容';

  @override
  String get downloadUpdate => '下载';

  @override
  String get remindLater => '稍后提醒';

  @override
  String get seeAll => '查看全部';

  @override
  String get artistDataNotFound => '未找到艺术家';

  @override
  String get addedArtistToQueue => '已将歌手添加到队列';

  @override
  String get addedArtistToQueueError => '添加歌手到队列失败';

  @override
  String get casting => '投射中';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => '投射 / DLNA（测试版）';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => '断开连接';

  @override
  String get searchingDevices => '正在搜索设备';

  @override
  String get castWifiHint => '请确保您的投射/DLNA设备\n处于同一 Wi-Fi 网络上';

  @override
  String connectedToDevice(String name) {
    return '已连接到 $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return '连接到 $name 失败';
  }

  @override
  String get removedFromLikedSongs => '已从喜欢的歌曲中移除';

  @override
  String get addedToLikedSongs => '已添加到喜欢的歌曲';

  @override
  String get enableShuffle => '启用随机播放';

  @override
  String get enableRepeat => '启用循环';

  @override
  String get closeLyrics => '关闭歌词';

  @override
  String errorStartingDownload(Object error) {
    return '开始下载出错：$error';
  }

  @override
  String get errorLoadingGenres => '加载分类出错';

  @override
  String get noGenresFound => '未找到分类';

  @override
  String get noAlbumsInGenre => '该分类中没有专辑';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount 首歌曲 • $albumCount 张专辑';
  }

  @override
  String get musicFoldersDialogTitle => '选择音乐文件夹';

  @override
  String get musicFoldersHint => '保持全部启用以使用所有文件夹（默认）。';

  @override
  String get musicFoldersSaved => '音乐文件夹选择已保存';

  @override
  String get artworkStyleSection => '封面样式';

  @override
  String get artworkCornerRadius => '圆角';

  @override
  String get artworkCornerRadiusSubtitle => '调整专辑封面的圆角程度';

  @override
  String get artworkCornerRadiusNone => '无';

  @override
  String get artworkShape => '形状';

  @override
  String get artworkShapeRounded => '圆角矩形';

  @override
  String get artworkShapeCircle => '圆形';

  @override
  String get artworkShapeSquare => '方形';

  @override
  String get artworkShadow => '阴影';

  @override
  String get artworkShadowNone => '无';

  @override
  String get artworkShadowSoft => '柔和';

  @override
  String get artworkShadowMedium => '中等';

  @override
  String get artworkShadowStrong => '强烈';

  @override
  String get artworkShadowColor => '阴影颜色';

  @override
  String get artworkShadowColorBlack => '黑色';

  @override
  String get artworkShadowColorAccent => '强调色';

  @override
  String get artworkPreview => '预览';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '$value像素';
  }

  @override
  String get noArtwork => '无封面';

  @override
  String get serverUnreachableTitle => '无法连接服务器';

  @override
  String get serverUnreachableSubtitle => '请检查网络连接或服务器设置。';

  @override
  String get openOfflineMode => '以离线模式打开';

  @override
  String get appearanceSection => '外观';

  @override
  String get themeLabel => '主题';

  @override
  String get accentColorLabel => '强调色';

  @override
  String get circularDesignLabel => '圆润设计';

  @override
  String get circularDesignSubtitle => '浮动、圆角 UI，播放器和导航栏带有半透明面板和玻璃模糊效果。';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeTitle => '主题模式';

  @override
  String get clearAppCache => '清除 App 缓存';

  @override
  String get appearanceGlassHint => '玻璃与卡片样式由设计体系统一定义，不提供调节。';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get liveLabel => '直播';

  @override
  String get discordStatusText => 'Discord 状态文字';

  @override
  String get discordStatusTextSubtitle => 'Discord 动态中显示的第二行';

  @override
  String get discordRpcStyleArtist => '歌手名';

  @override
  String get discordRpcStyleSong => '歌曲名';

  @override
  String get discordRpcStyleApp => '应用名 (Luobo)';

  @override
  String get sectionVolumeNormalization => '音量标准化 (REPLAYGAIN)';

  @override
  String get sectionFadeInOut => '淡入/淡出';

  @override
  String get fadeInOutEnable => '启用淡入/淡出';

  @override
  String get fadeInOutSubtitle => '播放或暂停时平滑过渡音频';

  @override
  String fadeDuration(int duration) {
    return '淡入淡出时长：${duration}ms';
  }

  @override
  String get replayGainModeOff => '关闭';

  @override
  String get replayGainModeTrack => '单曲';

  @override
  String get replayGainModeAlbum => '专辑';

  @override
  String replayGainPreamp(String value) {
    return '前置增益：$value dB';
  }

  @override
  String get replayGainPreventClipping => '防止削波';

  @override
  String replayGainFallbackGain(String value) {
    return '回退增益：$value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return '添加歌曲数：$count';
  }

  @override
  String get transcodingEnable => '启用转码';

  @override
  String get transcodingEnableSubtitle => '降低音质以减少流量消耗';

  @override
  String get smartTranscoding => '智能转码';

  @override
  String get smartTranscodingSubtitle => '根据网络连接自动调整音质（WiFi vs 移动数据）';

  @override
  String get smartTranscodingDetectedNetwork => '当前：';

  @override
  String get smartTranscodingHelpTitle => '智能转码说明';

  @override
  String get smartTranscodingHelpBody =>
      '开启后，码率会根据当前网络自动切换：\n• WiFi → 使用「WiFi 音质」设置的码率\n• 蜂窝网络 → 使用「移动网络音质」设置的码率\n网络切换时自动调整，无需手动操作。';

  @override
  String get transcodingManualBitrate => '转码码率';

  @override
  String get transcodingManualBitrateSubtitle => '智能转码关闭时固定使用的码率';

  @override
  String get transcodingWifiQuality => 'WiFi 音质';

  @override
  String get transcodingWifiQualitySubtitleSmart => '连接 WiFi 时自动使用';

  @override
  String get transcodingMobileQuality => '移动网络音质';

  @override
  String get transcodingMobileQualitySubtitleSmart => '在移动数据上自动使用';

  @override
  String get transcodingFormat => '格式';

  @override
  String get transcodingFormatSubtitle => '流媒体使用的音频编码';

  @override
  String get transcodingBitrateOriginal => '原始（不转码）';

  @override
  String get transcodingFormatOriginal => '原始';

  @override
  String get transcodingLanForceOriginal => '局域网连接中 · 强制原始音质（不转码）';

  @override
  String get imageCacheTitle => '图片缓存';

  @override
  String get imageCacheSubtitle => '本地保存专辑封面';

  @override
  String get musicCacheTitle => '音乐缓存';

  @override
  String get musicCacheSubtitle => '本地保存歌曲元数据';

  @override
  String get bpmCacheTitle => 'BPM 缓存';

  @override
  String get bpmCacheSubtitle => '本地保存 BPM 分析';

  @override
  String get sectionAboutInformation => '信息';

  @override
  String get sectionAboutDeveloper => '开发者';

  @override
  String get sectionAboutLinks => '链接';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutPlatform => '平台';

  @override
  String get aboutMadeBy => '由 chengsitom 制作';

  @override
  String get aboutGitHub => 'github.com/chengsitom';

  @override
  String get aboutLinkGitHub => 'GitHub 仓库';

  @override
  String get aboutLinkChangelog => '更新日志';

  @override
  String get aboutLinkReportIssue => '报告问题';

  @override
  String get sectionAnalyticsPrivacy => '分析与隐私';

  @override
  String get deviceId => '设备 ID';

  @override
  String deviceIdAnonymous(String id) {
    return '匿名 ID：$id';
  }

  @override
  String get deviceIdDisabled => '启用分析以查看匿名设备 ID';

  @override
  String get aboutDeviceId => '关于设备 ID';

  @override
  String get aboutDeviceIdSubtitle => '这是应用生成的匿名标识符。它无法关联到你的个人身份，仅用于分析。';

  @override
  String get playbackSpeed => '播放速度';

  @override
  String get normalSpeed => '正常 (1×)';

  @override
  String get preservePitch => '保持音调';

  @override
  String get preservePitchSubtitle => '变速时保持原始音调';

  @override
  String get pitch => '音调';

  @override
  String get pitchPreserved => '音调已保持';

  @override
  String speedTooltipWithPitch(String speed, String pitch) {
    return '速度 $speed · 音调 $pitch×';
  }

  @override
  String speedTooltipPitchPreserved(String speed) {
    return '速度 $speed · 音调已保持';
  }

  @override
  String get sleepTimer => '睡眠定时器';

  @override
  String get sleepTimerActive => '睡眠定时器已激活';

  @override
  String get fadeOut => '淡出';

  @override
  String fadeOutSubtitle(int seconds) {
    return '在最后 $seconds 秒内逐渐降低音量';
  }

  @override
  String get finishCurrentSong => '播完当前歌曲';

  @override
  String get finishCurrentSongSubtitle => '当前曲目结束后停止';

  @override
  String sleepTimerMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String sleepTimerHours(int count) {
    return '$count 小时';
  }

  @override
  String sleepTimerSetFor(String duration) {
    return '睡眠定时器已设置为 $duration';
  }

  @override
  String get customDuration => '自定义时长…';

  @override
  String get cancelTimer => '取消定时器';

  @override
  String get customSleepTimer => '自定义睡眠定时器';

  @override
  String get set => '设置';

  @override
  String get addToPlaylistTitle => '添加到歌单';

  @override
  String get yourPlaylistsLabel => '你的歌单';

  @override
  String get enableLrcLibFallback => '从 LRCLIB 获取歌词';

  @override
  String get lrcLibFallbackSubtitle => '当服务器无歌词时自动从 LRCLIB 搜索';

  @override
  String get themeSaved => '主题已保存';

  @override
  String get themeUnsavedChanges => '未保存的更改';

  @override
  String get themeUnsavedChangesTitle => '未保存的更改';

  @override
  String get themeUnsavedChangesBody => '你有未保存的更改。离开前要保存吗？';

  @override
  String get discard => '丢弃';

  @override
  String get done => '完成';

  @override
  String pickColor(String label) {
    return '选择$label';
  }

  @override
  String get titleStyle => '标题样式';

  @override
  String get artistStyle => '歌手样式';

  @override
  String get themeActive => '使用中';

  @override
  String get themeSafeMode => '安全';

  @override
  String get themeCodeMode => '代码';

  @override
  String get themeAnimBadge => '动画';

  @override
  String themeAuthor(String author) {
    return '作者 $author';
  }

  @override
  String get gaplessPlayback => '无缝播放';

  @override
  String get gaplessPlaybackSubtitle => '消除歌曲之间的间隔';

  @override
  String get lyricsSection => '歌词';

  @override
  String get neteaseLyrics => '网易云歌词';

  @override
  String get neteaseLyricsSubtitle => '当 LRCLIB 无结果时从网易云音乐获取歌词（中文歌推荐开启）';

  @override
  String get aiSmartPlaylist => 'AI 智能歌单';

  @override
  String get apiKey => 'API Key';

  @override
  String get notConfigured => '未配置';

  @override
  String get apiUrl => 'API 地址';

  @override
  String get aiModel => '模型';

  @override
  String get songKnowledgeBase => '歌曲知识库';

  @override
  String knowledgeIndexed(int cached, int total) {
    return '已索引 $cached / $total 首';
  }

  @override
  String lastUpdated(String date) {
    return '上次更新：$date';
  }

  @override
  String get generate => '生成';

  @override
  String get incrementalUpdate => '增量更新';

  @override
  String knowledgeGenerated(int count) {
    return '已完成 $count 首歌的知识库生成';
  }

  @override
  String knowledgeGenerationFailed(String reason) {
    return '知识库生成失败：$reason';
  }

  @override
  String get apiUrlHint => 'https://api.deepseek.com';

  @override
  String get apiUrlDescription =>
      '兼容 OpenAI 格式的 API 地址均可使用\n如 DeepSeek、OpenAI、Kimi、通义千问等';

  @override
  String get modelName => '模型名称';

  @override
  String get aiConnectionSettings => 'AI 连接配置';

  @override
  String get exportKnowledgeBase => '导出知识库';

  @override
  String get exportKnowledgeBaseSubtitle => '导出为文件，分享给共用同一 NAS 曲库的其他人';

  @override
  String get export => '导出';

  @override
  String exportedTo(String path) {
    return '已导出到 $path';
  }

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get importKnowledgeBase => '导入知识库';

  @override
  String get importKnowledgeBaseSubtitle => '导入他人分享的知识库文件';

  @override
  String get import => '导入';

  @override
  String knowledgeImported(int count) {
    return '已导入 $count 首歌到知识库';
  }

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get howItWorks => '工作原理';

  @override
  String get knowledgeBaseExplanation => '歌曲知识库生成原理';

  @override
  String get playlistGenerationExplanation => 'AI 歌单生成原理';

  @override
  String get networkWifi => 'WiFi';

  @override
  String get networkMobile => '蜂窝网络';

  @override
  String get analyticsAndPrivacy => '分析与隐私';

  @override
  String get anonymousAnalyticsToggle => '匿名分析';

  @override
  String get anonymousAnalyticsToggleSubtitle => '通过匿名的崩溃报告和使用统计帮助改进 Luobo';

  @override
  String anonymousIdLabel(String id) {
    return '匿名 ID：$id';
  }

  @override
  String get enableAnalyticsToSeeId => '启用分析后可查看匿名设备 ID';

  @override
  String get copyDeviceId => '复制设备 ID';

  @override
  String get deviceIdCopied => '设备 ID 已复制到剪贴板';

  @override
  String get aboutDeviceIdDescription => '这是应用生成的匿名标识符，无法与您的个人身份关联，仅用于分析统计。';

  @override
  String get support => '支持';

  @override
  String get thanksForRating => '感谢评分！';

  @override
  String get alreadyRated => '您已经评过分了';

  @override
  String get rateMusly => '为 Luobo 评分';

  @override
  String get shareFeedback => '分享您的使用反馈';

  @override
  String get howWouldYouRate => '您如何评价使用体验？';

  @override
  String get optionalFeedback => '反馈意见（可选）...';

  @override
  String get submit => '提交';

  @override
  String get thankYouFeedback => '感谢您的反馈！';

  @override
  String addedFolder(String path) {
    return '已添加文件夹：$path';
  }

  @override
  String get removeFolder => '移除文件夹';

  @override
  String removeFolderConfirm(String path) {
    return '从扫描路径中移除「$path」？';
  }

  @override
  String get folderRemoved => '文件夹已移除';

  @override
  String get loadingLibrary => '正在加载曲库...';

  @override
  String get libraryEmptyOrFailed => '曲库为空或加载失败，请确认您的服务器支持全曲库扫描。';

  @override
  String get addToLikedSongs => '添加到喜欢的歌曲';

  @override
  String get removeFromLikedSongs => '从喜欢的歌曲中移除';

  @override
  String rateSongWithRating(int rating) {
    return '为歌曲评分（$rating 星）';
  }

  @override
  String songRated(int rating) {
    return '已评分 $rating 星';
  }

  @override
  String get songRemovedFromPlaylist => '歌曲已从歌单中移除';

  @override
  String errorRemovingSong(Object error) {
    return '移除歌曲出错：$error';
  }

  @override
  String errorRemovingSongs(Object error) {
    return '批量移除歌曲出错：$error';
  }

  @override
  String errorReorderingSong(Object error) {
    return '重新排序歌曲出错：$error';
  }

  @override
  String get removeSongs => '移除歌曲';

  @override
  String removeSongsConfirm(int count) {
    return '从该歌单中移除 $count 首歌曲？';
  }

  @override
  String songsRemovedFromPlaylist(int count) {
    return '已从歌单中移除 $count 首歌曲';
  }

  @override
  String get reorderSongs => '重新排序歌曲';

  @override
  String get doneReordering => '完成排序';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String get removeSelected => '移除所选';

  @override
  String get selectSongs => '选择歌曲';

  @override
  String get downloadPlaylist => '下载歌单';

  @override
  String removeSongFromPlaylistConfirm(String title) {
    return '从该歌单中移除「$title」？';
  }

  @override
  String downloadedSongsFrom(int count, String name) {
    return '已从 $name 下载 $count 首歌曲';
  }

  @override
  String downloadingSongsInBackground(int count) {
    return '正在后台下载 $count 首歌曲…';
  }

  @override
  String songsCountWithDuration(int count, String duration) {
    return '$count 首歌曲 • $duration';
  }

  @override
  String artistsCount(int count) {
    return '$count 位歌手';
  }

  @override
  String get createPlaylistToStart => '创建一个歌单开始吧';

  @override
  String get enableSelfSignedCertsHint => '请尝试在下方开启“允许自签名证书”。';

  @override
  String get checkCredentialsHint => '请检查用户名和密码后重试。';

  @override
  String get verifyServerUrlHint => '请检查服务器 URL 路径（例如 /navidrome、/airsonic）。';

  @override
  String get serverTimeoutHint => '服务器响应超时，请检查网络连接。';

  @override
  String get copyError => '复制错误';

  @override
  String get errorCopiedToClipboard => '错误已复制到剪贴板';

  @override
  String get tapToEnableSelfSignedCerts => '点击开启自签名证书';

  @override
  String get clickToEnableSelfSignedCerts => '点击开启自签名证书';

  @override
  String get failedToConnectToServer => '连接服务器失败';

  @override
  String get selectMusicFiles => '选择您的音乐文件...';

  @override
  String get noFilesSelected => '未选择文件。请点击“使用本地文件”并选择您的音乐文件。';

  @override
  String get youtubeMusicDescription =>
      'YouTube Music 直接从 YouTube 播放音乐，无需账号——点击“连接”即可开始。';

  @override
  String get savedProfiles => '已保存的账号';

  @override
  String get tapProfileToConnect => '点击账号连接 • 点击 × 删除';

  @override
  String get myServers => '我的服务器';

  @override
  String get addServer => '添加服务器';

  @override
  String get editServer => '编辑服务器';

  @override
  String get selectServerType => '选择服务器类型';

  @override
  String get serverTypeAuto => '自动检测（推荐）';

  @override
  String get serverTypeAutoSubtitle => 'Subsonic / Jellyfin / 道理鱼';

  @override
  String get serverTypeSubsonic => 'Subsonic';

  @override
  String get serverTypeJellyfin => 'Emby / Jellyfin';

  @override
  String get serverTypeDaoliyu => '道理鱼';

  @override
  String get deleteProfileTitle => '删除配置';

  @override
  String deleteProfileConfirm(String name) {
    return '确定删除「$name」吗？';
  }

  @override
  String get formSectionConnection => '连接';

  @override
  String get formSectionAccount => '账号';

  @override
  String get connecting => '连接中…';

  @override
  String get newThemeDefaultName => '新主题';

  @override
  String get newThemeDefaultAuthor => '我';

  @override
  String get themeDeactivated => '主题已停用（使用默认主题）';

  @override
  String get defaultThemeActivated => '已激活默认主题';

  @override
  String themeActivated(String name) {
    return '已激活「$name」';
  }

  @override
  String themeCopyName(String name) {
    return '$name 副本';
  }

  @override
  String themeDuplicated(String name) {
    return '已复制为「$name」';
  }

  @override
  String get exportThemeTitle => '导出主题';

  @override
  String themeExported(String path) {
    return '已导出到 $path';
  }

  @override
  String get themeImported => '主题已导入';

  @override
  String get themeImportedSafeMode => '主题已导入（安全模式）';

  @override
  String get themeImportedSuccess => '主题导入成功';

  @override
  String get importFailedTitle => '导入失败';

  @override
  String get themeFileErrors => '主题文件包含错误：';

  @override
  String get securityWarning => '安全警告';

  @override
  String get customCodeSecurityRisk => '该主题包含自定义 Flutter 代码，可能存在安全风险。';

  @override
  String get themeDetailsLabel => '主题详情：';

  @override
  String get nameLabel => '名称';

  @override
  String get authorLabel => '作者';

  @override
  String get customWidgetsLabel => '自定义组件：';

  @override
  String get dependenciesLabel => '依赖项：';

  @override
  String get safeModeButton => '安全模式';

  @override
  String get enableCodeButton => '启用代码';

  @override
  String get deleteTheme => '删除主题';

  @override
  String deleteThemeConfirm(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String themeDeleted(String name) {
    return '已删除「$name」';
  }

  @override
  String get safeModeDisabled => '安全模式已停用';

  @override
  String get safeModeEnabled => '安全模式已启用';

  @override
  String get duplicateTheme => '复制主题';

  @override
  String get newThemeNameHint => '新主题名称';

  @override
  String get duplicateButton => '复制';

  @override
  String get themeTabInfo => '信息';

  @override
  String get themeTabBackground => '背景';

  @override
  String get themeTabText => '文字';

  @override
  String get themeTabArtwork => '封面';

  @override
  String get themeTabProgress => '进度条';

  @override
  String get themeTabControls => '控件';

  @override
  String get themeTabAnimations => '动画';

  @override
  String get themeNameLabel => '主题名称';

  @override
  String get backgroundTypeLabel => '背景类型';

  @override
  String get color1Label => '颜色 1';

  @override
  String get color2Label => '颜色 2';

  @override
  String get opacityLabel => '不透明度';

  @override
  String get blurSigmaLabel => '模糊半径';

  @override
  String get colorLabel => '颜色';

  @override
  String get fontSizeLabel => '字体大小';

  @override
  String get fontWeightLabel => '字重';

  @override
  String get shapeLabel => '形状';

  @override
  String get sizeFactorLabel => '大小比例';

  @override
  String get cornerRadiusLabel => '圆角半径';

  @override
  String get shadowLabel => '阴影';

  @override
  String get rotationAnimationLabel => '旋转动画';

  @override
  String get activeColorLabel => '激活颜色';

  @override
  String get inactiveColorLabel => '未激活颜色';

  @override
  String get heightLabel => '高度';

  @override
  String get thumbVisibleLabel => '显示滑块';

  @override
  String get buttonColorLabel => '按钮颜色';

  @override
  String get playButtonColorLabel => '播放按钮颜色';

  @override
  String get playButtonSizeLabel => '播放按钮大小';

  @override
  String get playButtonShapeLabel => '播放按钮形状';

  @override
  String get coverRotationLabel => '封面旋转';

  @override
  String get rotationSpeedLabel => '旋转速度（秒/圈）';

  @override
  String get pulseEffectLabel => '脉冲效果';

  @override
  String get fadeInLabel => '淡入';

  @override
  String get noFavoriteSongs => '还没有收藏的歌曲';

  @override
  String get listeningHistoryHint => '您播放的歌曲会显示在这里';

  @override
  String get searchInLibrary => '在曲库中搜索...';

  @override
  String get searchYourLibrary => '搜索您的曲库';

  @override
  String get noPlaylistsFound => '未找到歌单';

  @override
  String get tableHeaderTitle => '标题';

  @override
  String get tableHeaderAlbum => '专辑';

  @override
  String get tableHeaderTime => '时长';

  @override
  String streamUrl(String url) {
    return '流媒体地址：$url';
  }

  @override
  String get newReleases => '新发行';

  @override
  String get noNewReleases => '暂无新发行';

  @override
  String get downloadAlbum => '下载专辑';

  @override
  String durationMinutesOnly(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get noSongsInQueue => '队列中没有歌曲';

  @override
  String get internetRadioLive => '网络电台 • 直播';

  @override
  String get stop => '停止';

  @override
  String customWidgetLabel(String name) {
    return '自定义组件：$name';
  }

  @override
  String customWidgetError(String error) {
    return '自定义组件错误：$error';
  }

  @override
  String get unknownError => '未知错误';

  @override
  String safeModeDisabledLabel(String name) {
    return '安全模式：$name 已停用';
  }

  @override
  String get compiling => '正在编译...';

  @override
  String get exitApp => '退出应用';

  @override
  String get noTranscoding => '原始格式（未转码）';

  @override
  String get transcodeShortIdle => '不转码';

  @override
  String get transcodeShortActive => '转码中';

  @override
  String get transcodeShortDone => '已转码';

  @override
  String get streamWillTranscode => '当前网络将转码';

  @override
  String streamWillTranscodeTo(String format, int bitrate, String network) {
    return '当前网络将转码为 $format ${bitrate}kbps（$network）';
  }

  @override
  String transcodedTo(String format, int bitrate, String network) {
    return '转码为 $format ${bitrate}kbps（$network）';
  }

  @override
  String transcodedToNoNetwork(String format, int bitrate) {
    return '转码为 $format ${bitrate}kbps';
  }

  @override
  String transcodingInProgress(String format, int bitrate) {
    return '转码中：$format ${bitrate}kbps';
  }

  @override
  String get edit => '编辑';

  @override
  String get serverStatus => '服务器状态';

  @override
  String get rescanLibrary => '重新扫描曲库';

  @override
  String get removeConnection => '移除连接';

  @override
  String get connectedServers => '已连接的服务器';

  @override
  String get serversHint => '点击切换当前服务器；右上角可扫码或新增。';

  @override
  String get libraryRefreshed => '曲库已刷新';

  @override
  String get serverDetail => '服务器详情';

  @override
  String get formLocalOnlyNote => '以上信息仅保存在本设备';

  @override
  String get serverTypeGridHint => '选定类型后进入表单填写地址与账号 —— 表单样式与「修改连接」完全一致。';

  @override
  String get otherWays => '其他方式';

  @override
  String get operationFailed => '操作失败';

  @override
  String get useLocalFilesConfirmTitle => '切到本地音乐模式？';

  @override
  String get useLocalFilesConfirmBody => '会断开当前服务器连接，改用本机上的音乐文件。';

  @override
  String get sortFieldTitle => '标题';
}

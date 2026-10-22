import 'package:flutter/material.dart';
import '../widgets/luobo/luobo_toast.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../services/ai_playlist_service.dart';
import '../services/recommendation_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class AiPlaylistScreen extends StatefulWidget {
  const AiPlaylistScreen({super.key});

  @override
  State<AiPlaylistScreen> createState() => _AiPlaylistScreenState();
}

class _AiPlaylistScreenState extends State<AiPlaylistScreen>
    with SingleTickerProviderStateMixin {
  final AiPlaylistService _aiService = AiPlaylistService();
  final TextEditingController _freeTextController = TextEditingController();
  final TextEditingController _playlistNameController = TextEditingController();

  AiPlaylistMode _selectedMode = AiPlaylistMode.recentListening;
  int _songCount = 25;
  String? _selectedScene;
  bool _isGenerating = false;
  List<Song>? _generatedSongs;
  String? _error;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const List<Map<String, dynamic>> _scenes = [
    {'label': '开车兜风', 'icon': Icons.directions_car_rounded},
    {'label': '通勤路上', 'icon': Icons.train_rounded},
    {'label': '跑步运动', 'icon': Icons.directions_run_rounded},
    {'label': '深夜独处', 'icon': Icons.nightlight_round},
    {'label': '学习工作', 'icon': Icons.menu_book_rounded},
    {'label': '聚会派对', 'icon': Icons.celebration_rounded},
    {'label': '做饭下厨', 'icon': Icons.restaurant_rounded},
    {'label': '午后休息', 'icon': Icons.coffee_rounded},
    {'label': '雨天发呆', 'icon': Icons.water_drop_rounded},
    {'label': '早起提神', 'icon': Icons.wb_sunny_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _aiService.initialize();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _freeTextController.dispose();
    _playlistNameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : const Color(0xFFF8F8FA),
      body: _generatedSongs != null
          ? _buildResultView(isDark)
          : _buildInputView(isDark),
    );
  }

  Widget _buildInputView(bool isDark) {
    return CustomScrollView(
      slivers: [
        // Hero header
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 16,
              24,
              24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFFF0E6FF), const Color(0xFFE8F4FD)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.appleMusicRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 14, color: AppTheme.appleMusicRed),
                          const SizedBox(width: 4),
                          Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.appleMusicRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '让 AI 为你\n挑选音乐',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '基于你的曲库和听歌习惯，智能生成专属歌单',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),

        // API Key warning
        SliverToBoxAdapter(
          child: FutureBuilder<String?>(
            future: StorageService().getDeepSeekApiKey(),
            builder: (context, snapshot) {
              if (snapshot.data == null || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.key_rounded,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '请先在设置 → AI 智能歌单中配置 API Key',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),

        // Mode selection
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              '生成方式',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildModeChip(
                  AiPlaylistMode.recentListening,
                  Icons.graphic_eq_rounded,
                  '最近常听',
                  isDark,
                ),
                _buildModeChip(
                  AiPlaylistMode.scene,
                  Icons.landscape_rounded,
                  '场景',
                  isDark,
                ),
                _buildModeChip(
                  AiPlaylistMode.freeText,
                  Icons.chat_bubble_outline_rounded,
                  '自由描述',
                  isDark,
                ),
              ],
            ),
          ),
        ),

        // Scene grid (only if scene mode)
        if (_selectedMode == AiPlaylistMode.scene) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text(
                '选择场景',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final scene = _scenes[index];
                  final label = scene['label'] as String;
                  final icon = scene['icon'] as IconData;
                  final selected = _selectedScene == label;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedScene = label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.appleMusicRed
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey.shade200,
                              ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppTheme.appleMusicRed
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: selected
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black45),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _scenes.length,
              ),
            ),
          ),
        ],

        // Free text input
        if (_selectedMode == AiPlaylistMode.freeText)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: TextField(
                  controller: _freeTextController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '描述你想听的感觉...\n例如：适合下雨天在咖啡店看书的歌，带点爵士感',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),

        // Song count selector
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                Text(
                  '歌曲数量',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(width: 16),
                ...[15, 25, 40].map((count) {
                  final selected = _songCount == count;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _songCount = count),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.appleMusicRed
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: selected
                              ? null
                              : Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Generate button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: _isGenerating
                ? _buildGeneratingState(isDark)
                : _buildGenerateButton(isDark),
          ),
        ),

        // Error
        if (_error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade300, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGeneratingState(bool isDark) {
    _pulseController.repeat(reverse: true);
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.appleMusicRed,
                  AppTheme.appleMusicRed.withValues(alpha: 0.6),
                ],
              ),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'AI 正在为你挑选歌曲...',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.appleMusicRed),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(bool isDark) {
    _pulseController.stop();
    return GestureDetector(
      onTap: _generate,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFC3C44), Color(0xFFE52D27)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.appleMusicRed.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '生成歌单',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(
    AiPlaylistMode mode,
    IconData icon,
    String label,
    bool isDark,
  ) {
    final selected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.appleMusicRed.withValues(alpha: 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.appleMusicRed.withValues(alpha: 0.5)
                : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: selected
                  ? AppTheme.appleMusicRed
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black38),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppTheme.appleMusicRed
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(bool isDark) {
    final songs = _generatedSongs!;
    return Column(
      children: [
        // Header with gradient
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 12,
            20,
            16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF1A1A2E), AppTheme.darkBackground]
                  : [const Color(0xFFF0E6FF), const Color(0xFFF8F8FA)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _generatedSongs = null;
                      _error = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _generatedSongs = null;
                      _error = null;
                    }),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('重新生成', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.appleMusicRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${songs.length}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.appleMusicRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '首歌已为你挑选完毕',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '左滑可移除不想要的歌',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ),
            ],
          ),
        ),

        // Song list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return Dismissible(
                key: ValueKey(songs[index].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: Colors.red.shade400,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white),
                ),
                onDismissed: (_) {
                  setState(() => _generatedSongs!.removeAt(index));
                },
                child: SongTile(
                  song: songs[index],
                  playlist: songs,
                  index: index,
                  showAlbum: true,
                ),
              );
            },
          ),
        ),

        // Save bar
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _playlistNameController,
                    decoration: InputDecoration(
                      hintText: '歌单名称',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _savePlaylist,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFC3C44), Color(0xFFE52D27)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '保存歌单',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generate() async {
    if (_selectedMode == AiPlaylistMode.scene && _selectedScene == null) {
      setState(() => _error = '请选择一个场景');
      return;
    }
    if (_selectedMode == AiPlaylistMode.freeText &&
        _freeTextController.text.trim().isEmpty) {
      setState(() => _error = '请输入描述');
      return;
    }

    final apiKey = await StorageService().getDeepSeekApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _error = '请先在设置中配置 API Key');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    final recommendationService =
        Provider.of<RecommendationService>(context, listen: false);
    final allSongs = libraryProvider.cachedAllSongs;

    final result = await _aiService.generatePlaylist(
      allSongs: allSongs,
      mode: _selectedMode,
      count: _songCount,
      sceneDescription: _selectedScene,
      freeText: _freeTextController.text.trim(),
      recentlyPlayed: recommendationService.recentlyPlayed,
      recommendationService: recommendationService,
    );

    if (!mounted) return;

    if (result == null || result.isEmpty) {
      setState(() {
        _isGenerating = false;
        _error = '生成失败，请检查网络连接和 API Key';
      });
      return;
    }

    final songMap = {for (final s in allSongs) s.id: s};
    final songs = result.map((id) => songMap[id]).whereType<Song>().toList();

    String defaultName;
    switch (_selectedMode) {
      case AiPlaylistMode.recentListening:
        defaultName = 'AI · 最近风格';
      case AiPlaylistMode.scene:
        defaultName = 'AI · $_selectedScene';
      case AiPlaylistMode.freeText:
        final text = _freeTextController.text.trim();
        defaultName = 'AI · ${text.length > 10 ? text.substring(0, 10) : text}';
    }
    _playlistNameController.text = defaultName;

    setState(() {
      _isGenerating = false;
      _generatedSongs = songs;
    });
  }

  Future<void> _savePlaylist() async {
    final songs = _generatedSongs;
    if (songs == null || songs.isEmpty) return;

    final name = _playlistNameController.text.trim();
    if (name.isEmpty) {
      showLuoboToast(
      context,
      message: '请输入歌单名称',
      tone: LuoboToastTone.info,
    );
      return;
    }

    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    await libraryProvider.createPlaylist(
      name,
      songIds: songs.map((s) => s.id).toList(),
    );

    if (!mounted) return;
    showLuoboToast(
      context,
      message: '歌单「$name」已创建',
      tone: LuoboToastTone.info,
    );
    Navigator.pop(context);
  }
}

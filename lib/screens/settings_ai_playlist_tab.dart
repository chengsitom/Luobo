import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/ai_knowledge_service.dart';
import '../services/storage_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';

class SettingsAiPlaylistTab extends StatefulWidget {
  const SettingsAiPlaylistTab({super.key});

  @override
  State<SettingsAiPlaylistTab> createState() => _SettingsAiPlaylistTabState();
}

class _SettingsAiPlaylistTabState extends State<SettingsAiPlaylistTab> {
  String _aiApiKey = '';
  String _aiBaseUrl = 'https://api.deepseek.com';
  String _aiModel = 'deepseek-v4-flash';
  bool _isExporting = false;
  bool _isImporting = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storageService = StorageService();
    final aiApiKey = await storageService.getDeepSeekApiKey() ?? '';
    final aiBaseUrl = await storageService.getAiBaseUrl();
    final aiModel = await storageService.getAiModel();

    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    await AiKnowledgeService.instance
        .initialize(totalSongs: libraryProvider.cachedAllSongs.length);

    if (!mounted) return;
    setState(() {
      _aiApiKey = aiApiKey;
      _aiBaseUrl = aiBaseUrl;
      _aiModel = aiModel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildConnectionSection(),
        _buildKnowledgeSection(),
        _buildExplanationSection(),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LuoboSectionHeader(title),
        LuoboCard(children: children),
      ],
    );
  }

  // ── Connection settings (API Key / URL / Model) ─────────────────────

  Widget _buildConnectionSection() {
    return _buildSection(
      title: AppLocalizations.of(context)!.aiConnectionSettings,
      children: [
        // 三行都是「标题 + 右侧状态值 + ›」的单行形态（§9.20）：
        // 值放右边缘而不是塞进副标题 —— 副标题形态会让行高从 50 涨到 62，
        // 且和飞牛「清除 App 缓存 1.0 GB ›」的读法不一致。
        LuoboRow(
          icon: CupertinoIcons.lock,
          title: AppLocalizations.of(context)!.apiKey,
          value: _maskedApiKey(),
          showChevron: true,
          onTap: _showApiKeyDialog,
        ),
        _buildDivider(),
        LuoboRow(
          icon: CupertinoIcons.globe,
          title: AppLocalizations.of(context)!.apiUrl,
          value: _aiBaseUrl,
          showChevron: true,
          onTap: _showBaseUrlDialog,
        ),
        _buildDivider(),
        LuoboRow(
          icon: Icons.memory_rounded,
          title: AppLocalizations.of(context)!.aiModel,
          value: _aiModel,
          showChevron: true,
          onTap: _showModelSelector,
        ),
      ],
    );
  }

  Widget _buildDivider() => const LuoboDivider(indent: LuoboDivider.withIcon);

  /// API Key 的打码显示。
  ///
  /// ⚠️ **必须按长度兜底**：早先只判了 `isEmpty`，长度 1–7 的短 key 会在
  /// `substring(0, 8)` 抛 `RangeError`，而异常发生在 `build` 里 —— 整页每帧
  /// 崩溃，用户连改回都做不到。阈值 8 与 `config/analytics_config.dart` 的
  /// 既有守卫一致。
  String _maskedApiKey() {
    if (_aiApiKey.isEmpty) {
      return AppLocalizations.of(context)!.notConfigured;
    }
    if (_aiApiKey.length < 8) return '••••••';
    return '${_aiApiKey.substring(0, 8)}…'
        '${_aiApiKey.substring(_aiApiKey.length - 4)}';
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _aiApiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'sk-...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final key = controller.text.trim();
              await StorageService().saveDeepSeekApiKey(key);
              setState(() => _aiApiKey = key);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _showBaseUrlDialog() {
    final controller = TextEditingController(text: _aiBaseUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.apiUrl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.apiUrlHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.apiUrlDescription,
              style: TextStyle(
                fontSize: 12,
                color: _isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final url = controller.text.trim();
              await StorageService().saveAiBaseUrl(url);
              setState(() => _aiBaseUrl = url);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _showModelSelector() {
    final controller = TextEditingController(text: _aiModel);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.modelName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'deepseek-v4-flash',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                'deepseek-v4-flash',
                'deepseek-chat',
                'deepseek-reasoner',
                'gpt-4o-mini',
                'gpt-4o',
                'moonshot-v1-8k',
                'qwen-turbo',
              ]
                  .map((m) => GestureDetector(
                        onTap: () => controller.text = m,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _isDark ? Colors.white10 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(m, style: const TextStyle(fontSize: 12)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final model = controller.text.trim();
              if (model.isNotEmpty) {
                await StorageService().saveAiModel(model);
                setState(() => _aiModel = model);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  // ── Knowledge base ───────────────────────────────────────────────────

  Widget _buildKnowledgeSection() {
    final accent = LuoboAccent.accent;
    final isDark = _isDark;
    return ListenableBuilder(
      listenable: AiKnowledgeService.instance,
      builder: (context, _) {
        final svc = AiKnowledgeService.instance;
        return _buildSection(
          title: AppLocalizations.of(context)!.songKnowledgeBase,
          children: [
            LuoboRow(
              icon: CupertinoIcons.book,
              title: AppLocalizations.of(context)!.songKnowledgeBase,
              subtitle: AppLocalizations.of(context)!
                  .knowledgeIndexed(svc.cachedCount, svc.totalSongs),
              subtitleExtra: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (svc.lastUpdate != null)
                    Text(
                      AppLocalizations.of(context)!.lastUpdated(
                          '${svc.lastUpdate!.month}/${svc.lastUpdate!.day} '
                          '${svc.lastUpdate!.hour}:${svc.lastUpdate!.minute.toString().padLeft(2, '0')}'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  if (svc.isGenerating)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: LinearProgressIndicator(
                        value: svc.progress,
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                ],
              ),
              showChevron: false,
              trailing: svc.isGenerating
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle, size: 22),
                      onPressed: _cancelKnowledgeGeneration,
                    )
                  : LuoboTextAction(
                      label: svc.cachedCount == 0
                          ? AppLocalizations.of(context)!.generate
                          : AppLocalizations.of(context)!.incrementalUpdate,
                      onPressed: _aiApiKey.isEmpty ? null : _generateKnowledge,
                    ),
            ),
            _buildDivider(),
            // Export
            LuoboRow(
              icon: CupertinoIcons.square_arrow_up,
              title: AppLocalizations.of(context)!.exportKnowledgeBase,
              subtitle:
                  AppLocalizations.of(context)!.exportKnowledgeBaseSubtitle,
              showChevron: false,
              trailing: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : LuoboTextAction(
                      label: AppLocalizations.of(context)!.export,
                      onPressed: svc.cachedCount == 0 ? null : _exportKnowledge,
                    ),
            ),
            _buildDivider(),
            // Import
            LuoboRow(
              icon: CupertinoIcons.square_arrow_down,
              title: AppLocalizations.of(context)!.importKnowledgeBase,
              subtitle:
                  AppLocalizations.of(context)!.importKnowledgeBaseSubtitle,
              showChevron: false,
              trailing: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : LuoboTextAction(
                      label: AppLocalizations.of(context)!.import,
                      onPressed: _importKnowledge,
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateKnowledge() async {
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    final allSongs = libraryProvider.cachedAllSongs;
    if (allSongs.isEmpty) return;

    await AiKnowledgeService.instance.start(allSongs);
    if (!mounted) return;
    final processed = AiKnowledgeService.instance.processed;
    final failureReason = AiKnowledgeService.instance.lastFailureReason;
    if (processed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.knowledgeGenerated(processed)),
        ),
      );
    } else if (failureReason != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .knowledgeGenerationFailed(failureReason),
          ),
        ),
      );
    }
  }

  void _cancelKnowledgeGeneration() {
    AiKnowledgeService.instance.cancel();
  }

  Future<void> _exportKnowledge() async {
    setState(() => _isExporting = true);
    try {
      final cache = AiKnowledgeService.instance.cache;
      final jsonStr = cache.exportAsJson();
      final fileName =
          'luobo_knowledge_${DateTime.now().millisecondsSinceEpoch}.json';

      if (Platform.isAndroid || Platform.isIOS) {
        final bytes = Uint8List.fromList(utf8.encode(jsonStr));
        final result = await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context)!.exportKnowledgeBase,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );
        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.exportedTo(result))),
          );
        }
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context)!.exportKnowledgeBase,
          fileName: fileName,
        );
        if (result != null) {
          final file = File(result);
          await file.writeAsString(jsonStr);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.exportedTo(result))),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.exportFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importKnowledge() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final path = result.files.first.path;
      String jsonStr;
      if (path != null) {
        jsonStr = await File(path).readAsString();
      } else {
        // Web/some platforms provide bytes instead of a path
        final bytes = result.files.first.bytes;
        if (bytes == null) throw const FormatException('无法读取文件内容');
        jsonStr = utf8.decode(bytes);
      }

      final cache = AiKnowledgeService.instance.cache;
      final count = await cache.importFromJson(jsonStr);

      if (!mounted) return;
      final libraryProvider =
          Provider.of<LibraryProvider>(context, listen: false);
      // Re-read from disk so the singleton's cachedCount reflects the import.
      await AiKnowledgeService.instance
          .initialize(totalSongs: libraryProvider.cachedAllSongs.length);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.knowledgeImported(count))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.importFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ── Explanation ──────────────────────────────────────────────────────

  Widget _buildExplanationSection() {
    return _buildSection(
      title: AppLocalizations.of(context)!.howItWorks,
      children: [
        LuoboRow(
          icon: CupertinoIcons.info_circle,
          title: AppLocalizations.of(context)!.knowledgeBaseExplanation,
          onTap: () => _showExplanationSheet(
            title: AppLocalizations.of(context)!.knowledgeBaseExplanation,
            paragraphs: _knowledgeExplanationParagraphs(),
          ),
        ),
        _buildDivider(),
        LuoboRow(
          icon: CupertinoIcons.info_circle,
          title: AppLocalizations.of(context)!.playlistGenerationExplanation,
          onTap: () => _showExplanationSheet(
            title: AppLocalizations.of(context)!.playlistGenerationExplanation,
            paragraphs: _playlistExplanationParagraphs(),
          ),
        ),
      ],
    );
  }

  List<(String, String)> _knowledgeExplanationParagraphs() {
    return const [
      (
        '标签生成',
        '对曲库中每首歌，AI 会根据歌名、歌手、专辑、风格、年份生成 8-12 个标签，'
            '涵盖情绪氛围、节奏能量、适合场景、歌词主题、演唱风格、乐器编曲特征、'
            '风格子类和相似歌手八个维度。',
      ),
      (
        '为什么不抓取歌词/评价',
        'AI 大模型本身的训练数据中已经包含了大量歌曲的歌词内容和公众评价信息，'
            '所以只需要提供歌名和歌手，AI 就能推断出这首歌的情绪、主题和适用场景，'
            '不需要额外爬取歌词或评论数据。',
      ),
      (
        '批量处理与断点续传',
        '生成时每批处理 50 首歌，每批完成后立即保存到本地。'
            '如果中途中断（退出 App、网络问题等），下次点击生成会自动跳过已处理的歌曲，'
            '只处理剩余部分。',
      ),
      (
        '增量更新',
        '当曲库新增或删除歌曲后，点击「更新」只会处理新增的歌曲，'
            '并清理已删除歌曲的缓存，不会重复处理已有歌曲。',
      ),
      (
        '存储位置',
        '知识库以 JSON 文件形式保存在 App 私有目录下，不会上传到任何服务器，'
            '完全本地化存储。',
      ),
      (
        '共享曲库场景',
        '如果多人共用同一个 NAS 音乐库，生成一次知识库后可以导出分享给其他人，'
            '避免每个人各自重复调用 AI 生成，节省 API 调用成本。',
      ),
    ];
  }

  List<(String, String)> _playlistExplanationParagraphs() {
    return const [
      (
        '候选歌曲预筛',
        '生成歌单前，会先用知识库标签在本地做预筛选，从曲库中挑出与需求最相关的'
            '约 300 首歌作为候选，而不是把整个曲库都发给 AI，从而降低 token 消耗、'
            '提升响应速度和推荐精准度。',
      ),
      (
        '三种生成模式',
        '「最近常听」：从最近播放歌曲的知识标签中提取高频关键词，在全曲库中找相似的歌；\n'
            '「场景」：将场景（如"开车兜风"）映射为一组标签关键词进行匹配；\n'
            '「自由描述」：从用户输入文本中提取关键词进行匹配。',
      ),
      (
        '用户画像注入',
        '生成时会把常听歌手/风格、反复完整播放的歌曲、经常跳过的歌曲（负向信号）、'
            '高评分歌曲、当前时段等信息一并提供给 AI，让推荐更贴合个人习惯，'
            '而不只是通用推荐。',
      ),
      (
        '只从曲库内选歌',
        'AI 只会从你曲库中已有的歌曲里选择，确保生成的歌单可以直接保存并播放，'
            '不会出现曲库里没有的歌。',
      ),
      (
        '结果可编辑',
        '生成的歌单可以在保存前左滑删除不想要的歌曲，满意后再保存为正式歌单。',
      ),
    ];
  }

  void _showExplanationSheet({
    required String title,
    required List<(String, String)> paragraphs,
  }) {
    final isDark = _isDark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.75],
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            for (final p in paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.$1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.$2,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

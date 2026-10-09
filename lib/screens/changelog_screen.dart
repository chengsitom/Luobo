import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 更新日志页：从 README.md 的「版本历史」章节提取内容，
/// 去除 Markdown 语法符号后以纯文本 + 简单样式展示。
/// 无需新增依赖。
class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  List<_VersionSection> _sections = [];
  bool _loading = true;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    try {
      final raw = await rootBundle.loadString('README.md');
      final sections = _parseVersionHistory(raw);
      if (mounted)
        setState(() {
          _sections = sections;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 提取 README 中「## 版本历史」（或「## 🛠️ 版本历史」）章节下的内容，
  /// 按 **v\d+** 开头的段落（h2/h3/加粗行）分割为版本块，
  /// 每个版本块内再按条目行解析（- ✅ / - ⬜ / - 普通）。
  List<_VersionSection> _parseVersionHistory(String raw) {
    // 找到「版本历史」章节起始
    final historyRegex = RegExp(r'^##[^#].*版本历史', multiLine: true);
    final historyMatch = historyRegex.firstMatch(raw);
    if (historyMatch == null) return [];

    // 找下一个 ## 章节（结束边界）
    final afterHistory = raw.substring(historyMatch.end);
    final nextH2 = RegExp(r'^## ', multiLine: true).firstMatch(afterHistory);
    final body =
        nextH2 == null ? afterHistory : afterHistory.substring(0, nextH2.start);

    // 按版本标题行分割（支持 **vX.X.X...** 或直接 vX.X.X 开头的行）
    final lines = body.split('\n');
    final sections = <_VersionSection>[];
    _VersionSection? current;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 检测版本标题行：**vX.Y.Z...** 或 vX.Y.Z（行首）
      final versionTitle = _extractVersionTitle(trimmed);
      if (versionTitle != null) {
        if (current != null) sections.add(current);
        current = _VersionSection(title: versionTitle, items: []);
        continue;
      }

      if (current == null) continue;

      // 解析条目行
      final item = _parseItem(trimmed);
      if (item != null) current.items.add(item);
    }
    if (current != null) sections.add(current);
    return sections;
  }

  /// 识别版本标题行，返回清洁后的标题文本，不是版本行则返回 null。
  String? _extractVersionTitle(String line) {
    // **vX.Y.Z（...）**
    final bold = RegExp(r'^\*\*(v\d+\.\d+.*?)\*\*').firstMatch(line);
    if (bold != null) return bold.group(1)!;
    // ## vX.Y.Z 或 ### vX.Y.Z
    final header = RegExp(r'^#{2,3}\s+(v\d+\.\d+.*)').firstMatch(line);
    if (header != null) return _stripMarkdown(header.group(1)!);
    // 直接 vX.Y.Z 开头（不含 - ）
    if (RegExp(r'^v\d+\.\d+').hasMatch(line) && !line.startsWith('-')) {
      return _stripMarkdown(line);
    }
    return null;
  }

  _ChangelogItem? _parseItem(String line) {
    if (!line.startsWith('-')) return null;
    final content = line.replaceFirst(RegExp(r'^-\s*'), '');
    final done = content.startsWith('✅');
    final pending = content.startsWith('⬜');
    final text = _stripMarkdown(content.replaceFirst(RegExp(r'^[✅⬜]\s*'), ''));
    if (text.isEmpty) return null;
    return _ChangelogItem(text: text, done: done, pending: pending);
  }

  String _stripMarkdown(String s) {
    return s
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'\[(.+?)\]\(.+?\)'), (m) => m.group(1)!)
        .replaceAll(RegExp(r'#+\s*'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = _isDark;
    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(l10n.aboutLinkChangelog),
        centerTitle: false,
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sections.isEmpty
              ? Center(
                  child: Text(
                    '暂无更新日志',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: _sections.length,
                  itemBuilder: (context, index) =>
                      _buildSection(context, _sections[index]),
                ),
    );
  }

  Widget _buildSection(BuildContext context, _VersionSection section) {
    final isDark = _isDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 版本标题
          Text(
            section.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // 条目卡片
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: section.items
                  .map((item) => _buildItem(context, item,
                      isLast: item == section.items.last))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, _ChangelogItem item,
      {required bool isLast}) {
    final isDark = _isDark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.done ? '✅' : (item.pending ? '⬜' : '·'),
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Container(
              height: 0.5,
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ),
          ),
      ],
    );
  }
}

class _VersionSection {
  final String title;
  final List<_ChangelogItem> items;
  _VersionSection({required this.title, required this.items});
}

class _ChangelogItem {
  final String text;
  final bool done;
  final bool pending;
  _ChangelogItem(
      {required this.text, required this.done, required this.pending});
}

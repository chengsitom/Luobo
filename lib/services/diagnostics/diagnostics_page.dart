import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'diagnostic_event.dart';
import 'diagnostics_service.dart';
import 'event_types.dart';

/// 诊断页（设置 → 诊断）。
///
/// 展示实时指标卡片、事件时间线（级别过滤 + 搜索），支持导出/复制/清空。
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  LogLevel? _levelFilter;
  String _query = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    DiagnosticsService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    DiagnosticsService.instance.removeListener(_onChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<DiagnosticEvent> get _filtered {
    final all = DiagnosticsService.instance.ring.reversed.toList();
    return all.where((e) {
      if (_levelFilter != null && e.level.index < _levelFilter!.index) {
        return false;
      }
      if (_query.isNotEmpty) {
        final text = '${e.type} ${e.payload}'.toLowerCase();
        if (!text.contains(_query.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      // 移动端：弹系统保存对话框手选路径（release 下 adb 访问不了 app
      // 私有目录，必须走 SAF 才能把日志取出来）。
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        final content = await DiagnosticsService.instance.exportReadableText();
        final bytes = Uint8List.fromList(utf8.encode(content));
        final fileName =
            'luobo_diagnostics_${DateTime.now().millisecondsSinceEpoch}.txt';
        final path = await FilePicker.platform.saveFile(
          dialogTitle: l10n.diagnosticsTitle,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['txt'],
          bytes: bytes,
        );
        if (!mounted) return;
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.diagnosticsExported(path))),
          );
        }
        return;
      }
      // 桌面端：导出完整目录（events/metrics/export.txt/meta.json）
      final path = await DiagnosticsService.instance.export();
      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.diagnosticsExported(path))),
        );
      } else {
        _copyToClipboard();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.diagnosticsExportFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyToClipboard() async {
    final l10n = AppLocalizations.of(context)!;
    final text = await DiagnosticsService.instance.readableText(maxLines: 2000);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.diagnosticsCopied)),
    );
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.diagnosticsClearTitle),
        content: Text(l10n.diagnosticsClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.diagnosticsClearAction),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DiagnosticsService.instance.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diag = DiagnosticsService.instance;
    final events = _filtered;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.diagnosticsTitle), centerTitle: false),
      body: Column(
        children: [
          _buildMetricCards(diag, l10n),
          _buildControls(l10n),
          Expanded(
            child: events.isEmpty
                ? Center(child: Text(l10n.diagnosticsNoLogs))
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, i) => _EventTile(event: events[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(DiagnosticsService diag, AppLocalizations l10n) {
    final p90 = diag.netP90Ms;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _MetricCard(
              label: l10n.diagnosticsMetricFps,
              value: diag.fps.toStringAsFixed(1)),
          _MetricCard(
            label: l10n.diagnosticsMetricJankRate,
            value: '${(diag.jankRate * 100).toStringAsFixed(1)}%',
          ),
          _MetricCard(
              label: l10n.diagnosticsMetricRequests, value: '${diag.netCount}'),
          _MetricCard(
            label: l10n.diagnosticsMetricNetP90,
            value: p90 == null ? '-' : '${p90}ms',
          ),
          _MetricCard(
            label: l10n.diagnosticsMetricErrorRate,
            value: '${(diag.netErrorRate * 100).toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.diagnosticsSearchHint,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.diagnosticsTooltipCopy,
                onPressed: _busy ? null : _copyToClipboard,
                icon: const Icon(Icons.copy),
              ),
              IconButton(
                tooltip: l10n.diagnosticsTooltipExport,
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.save_alt),
              ),
              IconButton(
                tooltip: l10n.diagnosticsTooltipClear,
                onPressed: _busy ? null : _clear,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _levelChip(l10n.diagnosticsAll, null),
                ...LogLevel.values.map(
                  (l) => _levelChip(_levelLabel(l10n, l), l),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _levelLabel(AppLocalizations l10n, LogLevel level) {
    return switch (level) {
      LogLevel.debug => l10n.diagnosticsLevelDebug,
      LogLevel.info => l10n.diagnosticsLevelInfo,
      LogLevel.warn => l10n.diagnosticsLevelWarn,
      LogLevel.error => l10n.diagnosticsLevelError,
    };
  }

  Widget _levelChip(String label, LogLevel? level) {
    final selected = _levelFilter == level;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _levelFilter = level),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final DiagnosticEvent event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = switch (event.level) {
      LogLevel.debug => Colors.grey,
      LogLevel.info => Colors.blueGrey,
      LogLevel.warn => Colors.orange,
      LogLevel.error => Colors.red,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              event.toReadable(),
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

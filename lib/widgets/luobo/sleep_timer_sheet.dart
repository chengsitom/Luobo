import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/player_provider.dart';
import '../../theme/design_tokens.dart';
import 'luobo_toast.dart';
import 'sheet_shell.dart';

/// 睡眠定时弹层（播放页与有声书章节页共用）。
///
/// 2026-10-27：从 `now_playing_screen.dart` 抽出，并改为**飞牛风格**
/// （`showLuoboSheet`：页面底色 + 顶部圆角 20 + 把手 + 居中标题 +
/// 每项独立白卡；开关行带 Switch，取消为玫红危险行）。
/// 旧实现是深色 `AppTheme.darkSurface` 面板，与全站浅色/深色 sheet 不一致。
Future<void> showSleepTimerSheet(
  BuildContext context,
  PlayerProvider player,
) async {
  await showLuoboSheet(
    context: context,
    title: AppLocalizations.of(context)!.sleepTimer,
    // 内容约 8 行，超过默认 9/16 屏高时避免溢出。
    isScrollControlled: true,
    builder: (ctx) => _SleepTimerSheet(player: player),
  );
}

class _SleepTimerSheet extends StatefulWidget {
  final PlayerProvider player;

  const _SleepTimerSheet({required this.player});

  @override
  State<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<_SleepTimerSheet> {
  late bool _fadeOut;
  late bool _endCurrentSong;
  late int _fadeSeconds;

  @override
  void initState() {
    super.initState();
    _fadeOut = widget.player.sleepTimerFadeOut;
    _endCurrentSong = widget.player.sleepTimerEndCurrentSong;
    _fadeSeconds = widget.player.sleepTimerFadeDurationSeconds;
  }

  void _apply(Duration duration, String label) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    widget.player.setSleepTimer(
      duration,
      endCurrentSong: _endCurrentSong,
      fadeOut: _fadeOut,
      fadeDurationSeconds: _fadeSeconds,
    );
    showLuoboToast(
      context,
      message: l10n.sleepTimerSetFor(label),
      tone: LuoboToastTone.info,
    );
  }

  Future<void> _pickCustom() async {
    final l10n = AppLocalizations.of(context)!;
    var minutes = 30;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(l10n.customSleepTimer),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.sleepTimerMinutes(minutes),
                style: LuoboType.navTitle.copyWith(
                  fontSize: 24,
                  color: LuoboColors.of(ctx).fg,
                ),
              ),
              Slider(
                value: minutes.toDouble(),
                min: 1,
                max: 180,
                divisions: 179,
                activeColor: LuoboAccent.accent,
                onChanged: (v) => setSt(() => minutes = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(minutes),
              child: Text(
                l10n.set,
                style: const TextStyle(color: LuoboAccent.accent),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      _apply(
        Duration(minutes: picked),
        l10n.sleepTimerMinutes(picked),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);
    final options = <(String, Duration)>[
      (l10n.sleepTimerMinutes(15), const Duration(minutes: 15)),
      (l10n.sleepTimerMinutes(30), const Duration(minutes: 30)),
      (l10n.sleepTimerMinutes(45), const Duration(minutes: 45)),
      (l10n.sleepTimerHours(1), const Duration(hours: 1)),
      (l10n.sleepTimerHours(2), const Duration(hours: 2)),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final opt in options)
          LuoboSheetRow(
            title: opt.$1,
            showChevron: false,
            onTap: () => _apply(opt.$2, opt.$1),
          ),
        LuoboSheetRow(
          title: l10n.customDuration,
          onTap: _pickCustom,
        ),
        LuoboSheetRow(
          title: l10n.fadeOut,
          subtitle: l10n.fadeOutSubtitle(_fadeSeconds),
          showChevron: false,
          trailing: Switch(
            value: _fadeOut,
            activeThumbColor: LuoboAccent.accent,
            onChanged: (v) => setState(() => _fadeOut = v),
          ),
        ),
        if (_fadeOut)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius:
                    BorderRadius.circular(LuoboRadius.sheetRow),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: c.fg2,
                  ),
                  Expanded(
                    child: Slider(
                      value: _fadeSeconds.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      activeColor: LuoboAccent.accent,
                      label: '${_fadeSeconds}s',
                      onChanged: (v) =>
                          setState(() => _fadeSeconds = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${_fadeSeconds}s',
                      textAlign: TextAlign.end,
                      style: LuoboType.caption.copyWith(color: c.fg2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        LuoboSheetRow(
          title: l10n.finishCurrentSong,
          subtitle: l10n.finishCurrentSongSubtitle,
          showChevron: false,
          trailing: Switch(
            value: _endCurrentSong,
            activeThumbColor: LuoboAccent.accent,
            onChanged: (v) => setState(() => _endCurrentSong = v),
          ),
        ),
        if (widget.player.hasSleepTimer)
          LuoboSheetRow(
            title: l10n.cancelTimer,
            danger: true,
            showChevron: false,
            onTap: () {
              Navigator.of(context).pop();
              widget.player.setSleepTimer(Duration.zero);
            },
          ),
      ],
    );
  }
}

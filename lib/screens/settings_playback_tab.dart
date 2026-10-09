import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/player_provider.dart';
import '../services/replay_gain_service.dart';
import '../services/storage_service.dart';
import '../services/fade_settings_service.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../widgets/luobo/sheet_shell.dart';

class SettingsPlaybackTab extends StatefulWidget {
  const SettingsPlaybackTab({super.key});

  @override
  State<SettingsPlaybackTab> createState() => _SettingsPlaybackTabState();
}

class _SettingsPlaybackTabState extends State<SettingsPlaybackTab> {
  final _replayGainService = ReplayGainService();
  final _fadeSettingsService = FadeSettingsService();

  ReplayGainMode _replayGainMode = ReplayGainMode.off;
  double _replayGainPreamp = 0.0;
  bool _replayGainPreventClipping = true;
  double _replayGainFallback = -6.0;
  bool _lrcLibFallback = false;
  bool _neteaseFallback = true;
  bool _fadeEnabled = false;
  int _fadeDurationMs = 300;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _replayGainService.initialize();
    await _fadeSettingsService.initialize();

    final storageService = StorageService();
    final lrcLibFallback = await storageService.getLrcLibFallback();
    final neteaseFallback = await storageService.getNeteaseFallback();

    setState(() {
      _replayGainMode = _replayGainService.getMode();
      _replayGainPreamp = _replayGainService.getPreampGain();
      _replayGainPreventClipping = _replayGainService.getPreventClipping();
      _replayGainFallback = _replayGainService.getFallbackGain();
      _lrcLibFallback = lrcLibFallback;
      _neteaseFallback = neteaseFallback;
      _fadeEnabled = _fadeSettingsService.getFadeEnabled();
      _fadeDurationMs = _fadeSettingsService.getFadeDurationMs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // 2026-10-08：「自动播放 / AutoDJ」小节已移除 —— 续播模式与「每次追加
        // 数量」搬到了首页「漫游」卡的长按面板（方案 §5.3「路 3」）。
        _buildGaplessSection(),
        _buildFadeSection(),
        _buildLrcLibSection(),
        _buildSection(
          title: AppLocalizations.of(context)!.sectionVolumeNormalization,
          children: [
            _buildReplayGainModeSelector(),
            if (_replayGainMode != ReplayGainMode.off) ...[
              _buildDivider(),
              _buildReplayGainPreampSlider(),
              _buildDivider(),
              _buildReplayGainClippingToggle(),
              _buildDivider(),
              _buildReplayGainFallbackSlider(),
            ],
          ],
        ),
        const SizedBox(height: 40),
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

  Widget _buildDivider() => const LuoboDivider(indent: LuoboDivider.withIcon);

  Widget _buildReplayGainModeSelector() {
    final l10n = AppLocalizations.of(context)!;
    return LuoboRow(
      icon: CupertinoIcons.speaker_2,
      title: l10n.replayGainMode,
      value: _getReplayGainModeLabel(_replayGainMode),
      showChevron: true,
      onTap: _pickReplayGainMode,
    );
  }

  Future<void> _pickReplayGainMode() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showLuoboPickerSheet<ReplayGainMode>(
      context: context,
      title: l10n.replayGainMode,
      options: [
        for (final mode in ReplayGainMode.values)
          (value: mode, label: _getReplayGainModeLabel(mode)),
      ],
      selected: _replayGainMode,
    );
    if (picked == null || !mounted) return;
    _setReplayGainMode(picked);
  }

  String _getReplayGainModeLabel(ReplayGainMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ReplayGainMode.off:
        return l10n.replayGainModeOff;
      case ReplayGainMode.track:
        return l10n.replayGainModeTrack;
      case ReplayGainMode.album:
        return l10n.replayGainModeAlbum;
    }
  }

  void _setReplayGainMode(ReplayGainMode mode) async {
    await _replayGainService.setMode(mode);
    setState(() => _replayGainMode = mode);
  }

  Widget _buildReplayGainPreampSlider() {
    return LuoboSliderRow(
      title: AppLocalizations.of(context)!
          .replayGainPreamp(_replayGainPreamp.toStringAsFixed(1)),
      value: _replayGainPreamp,
      min: -12,
      max: 12,
      divisions: 24,
      onChanged: (value) async {
        await _replayGainService.setPreampGain(value);
        setState(() => _replayGainPreamp = value);
      },
    );
  }

  Widget _buildReplayGainClippingToggle() {
    return LuoboRow(
      title: AppLocalizations.of(context)!.replayGainPreventClipping,
      showChevron: false,
      trailing: LuoboSwitch(
        value: _replayGainPreventClipping,
        onChanged: (value) async {
          await _replayGainService.setPreventClipping(value);
          setState(() => _replayGainPreventClipping = value);
        },
      ),
    );
  }

  Widget _buildReplayGainFallbackSlider() {
    return LuoboSliderRow(
      title: AppLocalizations.of(context)!
          .replayGainFallbackGain(_replayGainFallback.toStringAsFixed(1)),
      value: _replayGainFallback,
      min: -12,
      max: 0,
      divisions: 12,
      onChanged: (value) async {
        await _replayGainService.setFallbackGain(value);
        setState(() => _replayGainFallback = value);
      },
    );
  }

  Widget _buildLrcLibSection() {
    return _buildSection(
      title: AppLocalizations.of(context)!.lyricsSection,
      children: [
        LuoboRow(
          icon: CupertinoIcons.text_quote,
          title: AppLocalizations.of(context)!.enableLrcLibFallback,
          subtitle: AppLocalizations.of(context)!.lrcLibFallbackSubtitle,
          showChevron: false,
          trailing: LuoboSwitch(
            value: _lrcLibFallback,
            onChanged: (v) async {
              final storage = StorageService();
              await storage.saveLrcLibFallback(v);
              setState(() => _lrcLibFallback = v);
            },
          ),
        ),
        _buildDivider(),
        LuoboRow(
          icon: CupertinoIcons.music_note_2,
          title: AppLocalizations.of(context)!.neteaseLyrics,
          subtitle: AppLocalizations.of(context)!.neteaseLyricsSubtitle,
          showChevron: false,
          trailing: LuoboSwitch(
            value: _neteaseFallback,
            onChanged: (v) async {
              final storage = StorageService();
              await storage.saveNeteaseFallback(v);
              setState(() => _neteaseFallback = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGaplessSection() {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        return _buildSection(
          title: AppLocalizations.of(context)!.gaplessPlayback,
          children: [
            LuoboRow(
              icon: CupertinoIcons.link,
              title: AppLocalizations.of(context)!.gaplessPlayback,
              subtitle: AppLocalizations.of(context)!.gaplessPlaybackSubtitle,
              showChevron: false,
              trailing: LuoboSwitch(
                value: player.gaplessEnabled,
                onChanged: (_) => player.toggleGaplessPlayback(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFadeSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSection(
      title: l10n.sectionFadeInOut,
      children: [
        LuoboRow(
          icon: CupertinoIcons.waveform,
          title: l10n.fadeInOutEnable,
          subtitle: l10n.fadeInOutSubtitle,
          showChevron: false,
          trailing: LuoboSwitch(
            value: _fadeEnabled,
            onChanged: (v) async {
              await _fadeSettingsService.setFadeEnabled(v);
              setState(() => _fadeEnabled = v);
            },
          ),
        ),
        if (_fadeEnabled) ...[
          _buildDivider(),
          LuoboSliderRow(
            title: l10n.fadeDuration(_fadeDurationMs),
            value: _fadeDurationMs.toDouble(),
            min: 100,
            max: 1000,
            divisions: 18,
            onChanged: (value) async {
              final duration = value.round();
              await _fadeSettingsService.setFadeDurationMs(duration);
              setState(() => _fadeDurationMs = duration);
            },
          ),
        ],
      ],
    );
  }
}

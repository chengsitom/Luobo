import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/recommendation_service.dart';
import '../services/player_ui_settings_service.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../widgets/luobo/sheet_shell.dart';
import '../l10n/app_localizations.dart';

class SettingsDisplayTab extends StatefulWidget {
  const SettingsDisplayTab({super.key});

  @override
  State<SettingsDisplayTab> createState() => _SettingsDisplayTabState();
}

class _SettingsDisplayTabState extends State<SettingsDisplayTab> {
  final _playerUiSettings = PlayerUiSettingsService();
  bool _showVolumeSlider = true;
  bool _showStarRatings = false;
  bool _showMiniPlayerHeart = false;
  bool _showMiniPlayerRepeat = false;
  bool _showMiniPlayerShuffle = false;
  double _albumArtCornerRadius = 8.0;
  String _artworkShape = 'rounded';
  String _artworkShadow = 'soft';
  String _artworkShadowColor = 'black';
  bool _liveSearch = true;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _playerUiSettings.initialize();

    if (!mounted) return;

    setState(() {
      _showVolumeSlider = _playerUiSettings.getShowVolumeSlider();
      _showStarRatings = _playerUiSettings.getShowStarRatings();
      _showMiniPlayerHeart = _playerUiSettings.getShowMiniPlayerHeart();
      _showMiniPlayerRepeat = _playerUiSettings.getShowMiniPlayerRepeat();
      _showMiniPlayerShuffle = _playerUiSettings.getShowMiniPlayerShuffle();
      _albumArtCornerRadius = _playerUiSettings.getAlbumArtCornerRadius();
      _artworkShape = _playerUiSettings.getArtworkShape();
      _artworkShadow = _playerUiSettings.getArtworkShadow();
      _artworkShadowColor = _playerUiSettings.getArtworkShadowColor();
      _liveSearch = _playerUiSettings.getLiveSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildSection(
          title: AppLocalizations.of(context)!.playerInterface.toUpperCase(),
          children: [
            _buildVolumeSliderToggle(),
            _buildDivider(),
            _buildStarRatingsToggle(),
            _buildDivider(),
            _buildMiniPlayerHeartToggle(),
            _buildDivider(),
            _buildMiniPlayerRepeatToggle(),
            _buildDivider(),
            _buildMiniPlayerShuffleToggle(),
            if (_isDesktop) ...[
              _buildDivider(),
              _buildDiscordRpcToggle(),
              _buildDivider(),
              _buildDiscordRpcStateStyleSelector(),
            ],
          ],
        ),
        _buildSection(
          title: AppLocalizations.of(context)!.liveSearchSection.toUpperCase(),
          children: [
            _buildLiveSearchToggle(),
          ],
        ),
        _buildSection(
          title: AppLocalizations.of(
            context,
          )!
              .artworkStyleSection
              .toUpperCase(),
          children: [_buildArtworkStyleEditor()],
        ),
        _buildSection(
          title: AppLocalizations.of(
            context,
          )!
              .smartRecommendations
              .toUpperCase(),
          children: [
            _buildRecommendationsToggle(),
            _buildDivider(),
            _buildRecommendationsStats(),
            _buildDivider(),
            _buildClearRecommendationsButton(),
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

  Widget _buildVolumeSliderToggle() {
    return LuoboRow(
      icon: CupertinoIcons.speaker_2,
      title: AppLocalizations.of(context)!.showVolumeSlider,
      subtitle: AppLocalizations.of(context)!.showVolumeSliderSubtitle,
      showChevron: false,
      trailing: LuoboSwitch(
        value: _showVolumeSlider,
        onChanged: (value) async {
          setState(() => _showVolumeSlider = value);
          await _playerUiSettings.setShowVolumeSlider(value);
        },
      ),
    );
  }

  Widget _buildStarRatingsToggle() {
    return LuoboRow(
      icon: CupertinoIcons.star_fill,
      title: AppLocalizations.of(context)!.showStarRatings,
      subtitle: AppLocalizations.of(context)!.showStarRatingsSubtitle,
      showChevron: false,
      trailing: LuoboSwitch(
        value: _showStarRatings,
        onChanged: (value) async {
          setState(() => _showStarRatings = value);
          await _playerUiSettings.setShowStarRatings(value);
        },
      ),
    );
  }

  Widget _buildMiniPlayerHeartToggle() {
    return LuoboRow(
      icon: CupertinoIcons.heart_fill,
      title: AppLocalizations.of(context)!.showMiniPlayerHeart,
      subtitle: AppLocalizations.of(context)!.showMiniPlayerHeartSubtitle,
      showChevron: false,
      trailing: LuoboSwitch(
        value: _showMiniPlayerHeart,
        onChanged: (value) async {
          setState(() => _showMiniPlayerHeart = value);
          await _playerUiSettings.setShowMiniPlayerHeart(value);
        },
      ),
    );
  }

  Widget _buildMiniPlayerRepeatToggle() {
    return LuoboRow(
      icon: CupertinoIcons.repeat,
      title: AppLocalizations.of(context)!.showMiniPlayerRepeat,
      subtitle: AppLocalizations.of(context)!.showMiniPlayerRepeatSubtitle,
      showChevron: false,
      trailing: LuoboSwitch(
        value: _showMiniPlayerRepeat,
        onChanged: (value) async {
          setState(() => _showMiniPlayerRepeat = value);
          await _playerUiSettings.setShowMiniPlayerRepeat(value);
        },
      ),
    );
  }

  Widget _buildMiniPlayerShuffleToggle() {
    return LuoboRow(
      icon: CupertinoIcons.shuffle,
      title: AppLocalizations.of(context)!.showMiniPlayerShuffle,
      subtitle: AppLocalizations.of(context)!.showMiniPlayerShuffleSubtitle,
      showChevron: false,
      trailing: LuoboSwitch(
        value: _showMiniPlayerShuffle,
        onChanged: (value) async {
          setState(() => _showMiniPlayerShuffle = value);
          await _playerUiSettings.setShowMiniPlayerShuffle(value);
        },
      ),
    );
  }

  Widget _buildLiveSearchToggle() {
    return LuoboRow(
      icon: CupertinoIcons.search,
      title: AppLocalizations.of(context)!.liveSearch,
      subtitle: AppLocalizations.of(context)!.liveSearchSubtitle,
      showChevron: false,
      trailing: LuoboSwitch(
        value: _liveSearch,
        onChanged: (value) async {
          setState(() => _liveSearch = value);
          await _playerUiSettings.setLiveSearch(value);
        },
      ),
    );
  }

  double _artworkPreviewRadius() {
    const previewSize = 108.0;
    // The corner radius setting is applied in raw pixels to every artwork size.
    // The most visible use-case is the song-tile thumbnail (50 × 50 logical px).
    // Scale the radius proportionally so the preview matches the visual roundness
    // the user will actually see in the song list.
    const referenceSize = 50.0;
    if (_artworkShape == 'circle') return 9999.0;
    if (_artworkShape == 'square') return 0.0;
    return (_albumArtCornerRadius * previewSize / referenceSize)
        .clamp(0.0, previewSize / 2);
  }

  List<BoxShadow>? _artworkPreviewShadow() {
    if (_artworkShadow == 'none') return null;
    const previewSize = 108.0;
    final Color color = _artworkShadowColor == 'accent'
        ? Theme.of(context).colorScheme.primary
        : Colors.black;
    double opacity;
    double blur;
    Offset offset;
    switch (_artworkShadow) {
      case 'medium':
        opacity = _isDark ? 0.35 : 0.25;
        blur = previewSize / 6;
        offset = Offset(0, previewSize / 20);
        break;
      case 'strong':
        opacity = _isDark ? 0.55 : 0.40;
        blur = previewSize / 4;
        offset = Offset(0, previewSize / 12);
        break;
      default:
        opacity = _isDark ? 0.22 : 0.14;
        blur = previewSize / 10;
        offset = Offset(0, previewSize / 30);
    }
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }

  Widget _buildArtworkStyleEditor() {
    final l10n = AppLocalizations.of(context)!;
    const previewSize = 108.0;
    final radius = _artworkPreviewRadius();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  l10n.artworkPreview,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: previewSize,
                  height: previewSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withAlpha(180),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      radius.clamp(0.0, previewSize / 2),
                    ),
                    boxShadow: _artworkPreviewShadow(),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildEditorRow(
            icon: Icons.crop_square_rounded,
            iconColor: const Color(0xFF5856D6),
            label: l10n.artworkShape,
            child: _buildChips(
              options: [
                (value: 'rounded', label: l10n.artworkShapeRounded),
                (value: 'circle', label: l10n.artworkShapeCircle),
                (value: 'square', label: l10n.artworkShapeSquare),
              ],
              selected: _artworkShape,
              onSelected: (v) {
                setState(() => _artworkShape = v);
                _playerUiSettings.setArtworkShape(v);
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _artworkShape == 'rounded'
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildEditorRow(
                        icon: Icons.rounded_corner,
                        iconColor: const Color(0xFFFF9500),
                        label: l10n.artworkCornerRadius,
                        trailing: Text(
                          _albumArtCornerRadius.round() == 0
                              ? l10n.artworkCornerRadiusNone
                              : '${_albumArtCornerRadius.round()}px',
                          style: LuoboType.value.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor:
                                Theme.of(context).colorScheme.primary,
                            inactiveTrackColor: _isDark
                                ? AppTheme.darkDivider
                                : AppTheme.lightDivider,
                            thumbColor: Theme.of(context).colorScheme.primary,
                            overlayColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(
                                  alpha: 0.12,
                                ),
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                          ),
                          child: Slider(
                            value: _albumArtCornerRadius,
                            min: 0,
                            max: 24,
                            divisions: 24,
                            onChanged: (v) {
                              setState(() => _albumArtCornerRadius = v);
                              _playerUiSettings.setAlbumArtCornerRadius(v);
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          _buildEditorRow(
            icon: Icons.blur_on_rounded,
            iconColor: const Color(0xFF34AADC),
            label: l10n.artworkShadow,
            child: _buildChips(
              options: [
                (value: 'none', label: l10n.artworkShadowNone),
                (value: 'soft', label: l10n.artworkShadowSoft),
                (value: 'medium', label: l10n.artworkShadowMedium),
                (value: 'strong', label: l10n.artworkShadowStrong),
              ],
              selected: _artworkShadow,
              onSelected: (v) {
                setState(() => _artworkShadow = v);
                _playerUiSettings.setArtworkShadow(v);
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _artworkShadow != 'none'
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildEditorRow(
                        icon: Icons.palette_outlined,
                        iconColor: const Color(0xFFFF2D55),
                        label: l10n.artworkShadowColor,
                        child: _buildChips(
                          options: [
                            (
                              value: 'black',
                              label: l10n.artworkShadowColorBlack,
                            ),
                            (
                              value: 'accent',
                              label: l10n.artworkShadowColorAccent,
                            ),
                          ],
                          selected: _artworkShadowColor,
                          onSelected: (v) {
                            setState(() => _artworkShadowColor = v);
                            _playerUiSettings.setArtworkShadowColor(v);
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildChips({
    required List<({String value, String label})> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt.value == selected;
        return GestureDetector(
          onTap: () => onSelected(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (_isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            child: Text(
              opt.label,
              style: LuoboType.body.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (_isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationsToggle() {
    return Consumer<RecommendationService>(
      builder: (context, service, _) {
        return LuoboRow(
          icon: CupertinoIcons.sparkles,
          title: AppLocalizations.of(context)!.enableRecommendations,
          subtitle: AppLocalizations.of(context)!.enableRecommendationsSubtitle,
          showChevron: false,
          trailing: LuoboSwitch(
            value: service.enabled,
            onChanged: (value) => service.setEnabled(value),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationsStats() {
    return Consumer<RecommendationService>(
      builder: (context, service, _) {
        final stats = service.getListeningStats();
        final uniqueSongs = stats['uniqueSongs'] ?? 0;
        final totalPlays = stats['totalPlays'] ?? 0;
        return LuoboRow(
          title: AppLocalizations.of(context)!.listeningData,
          subtitle: AppLocalizations.of(context)!.totalPlays(totalPlays),
          value: AppLocalizations.of(context)!.songsCount(uniqueSongs),
          showChevron: false,
        );
      },
    );
  }

  Widget _buildClearRecommendationsButton() {
    return LuoboRow(
      title: AppLocalizations.of(context)!.clearListeningHistory,
      danger: true,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.clearListeningHistory),
            content: Text(AppLocalizations.of(context)!.confirmClearHistory),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Provider.of<RecommendationService>(
                    context,
                    listen: false,
                  ).clearData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.historyCleared,
                      ),
                    ),
                  );
                },
                child: Text(
                  AppLocalizations.of(context)!.delete,
                  style: const TextStyle(color: Color(0xFFFF3B30)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscordRpcToggle() {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        return LuoboRow(
          icon: CupertinoIcons.game_controller,
          title: AppLocalizations.of(context)!.discordStatus,
          subtitle: AppLocalizations.of(context)!.discordStatusSubtitle,
          showChevron: false,
          trailing: LuoboSwitch(
            value: player.discordRpcEnabled,
            onChanged: (value) async {
              await player.setDiscordRpcEnabled(value);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildDiscordRpcStateStyleSelector() {
    final l10n = AppLocalizations.of(context)!;
    final styles = [
      ('artist', l10n.discordRpcStyleArtist),
      ('song_title', l10n.discordRpcStyleSong),
      ('app_name', l10n.discordRpcStyleApp),
    ];
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final current = styles.firstWhere(
          (s) => s.$1 == player.discordRpcStateStyle,
          orElse: () => styles.first,
        );
        return LuoboRow(
          icon: CupertinoIcons.text_bubble,
          title: l10n.discordStatusText,
          subtitle: l10n.discordStatusTextSubtitle,
          value: current.$2,
          showChevron: true,
          onTap: () async {
            final picked = await showLuoboPickerSheet<String>(
              context: context,
              title: l10n.discordStatusText,
              options: [
                for (final s in styles) (value: s.$1, label: s.$2),
              ],
              selected: player.discordRpcStateStyle,
            );
            if (picked == null || !context.mounted) return;
            player.setDiscordRpcStateStyle(picked);
          },
        );
      },
    );
  }
}

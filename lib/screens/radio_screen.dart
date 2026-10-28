import 'package:flutter/material.dart';
import '../widgets/luobo/luobo_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_surface.dart';
import '../widgets/load_error_view.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  List<RadioStation> _stations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subsonicService = Provider.of<SubsonicService>(
        context,
        listen: false,
      );
      final stations = await subsonicService.getInternetRadioStations();
      if (mounted) {
        setState(() {
          _stations = stations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _playStation(RadioStation station) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.playRadioStation(station);
  }

  Future<void> _openHomePage(RadioStation station) async {
    if (station.homePageUrl == null || station.homePageUrl!.isEmpty) {
      showLuoboToast(
      context,
      message: AppLocalizations.of(context)!.noHomepageUrl,
      tone: LuoboToastTone.info,
    );
      return;
    }

    final uri = Uri.tryParse(station.homePageUrl!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showStationOptions(RadioStation station) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGlassBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : LuoboColors.light.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.black26,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  station.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  CupertinoIcons.play_fill,
                  color: AppTheme.appleMusicRed,
                ),
                title: Text(
                  AppLocalizations.of(context)!.playStation,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _playStation(station);
                },
              ),
              if (station.homePageUrl != null &&
                  station.homePageUrl!.isNotEmpty)
                ListTile(
                  leading: Icon(
                    CupertinoIcons.globe,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.openHomepage,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    station.homePageUrl!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openHomePage(station);
                  },
                ),
              ListTile(
                leading: Icon(
                  CupertinoIcons.doc_on_doc,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  AppLocalizations.of(context)!.copyStreamUrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);

                  showLuoboToast(
      context,
      message: AppLocalizations.of(
                          context,
                        )!
                            .streamUrl(station.streamUrl),
      tone: LuoboToastTone.info,
    );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.radioStations),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _loadStations,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      // 复用共享 LoadErrorView（R003）。
      return LoadErrorView(
        title: AppLocalizations.of(context)!.failedToLoadRadioStations,
        message: _error,
        retryLabel: AppLocalizations.of(context)!.retry,
        onRetry: _loadStations,
      );
    }

    if (_stations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.radiowaves_right,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noRadioStations,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.noRadioStationsHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStations,
      child: ListView.builder(
        padding: EdgeInsets.only(
          bottom: LuoboSpacing.pageBottomWithStrip(context),
        ),
        itemCount: _stations.length,
        itemBuilder: (context, index) {
          final station = _stations[index];
          return _RadioStationTile(
            station: station,
            onTap: () => _playStation(station),
            onLongPress: () => _showStationOptions(station),
          );
        },
      ),
    );
  }
}

class _RadioStationTile extends StatelessWidget {
  final RadioStation station;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _RadioStationTile({
    required this.station,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final isPlaying = playerProvider.isPlayingRadio &&
            playerProvider.currentRadioStation?.id == station.id;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPlaying
                    ? [
                        AppTheme.appleMusicRed,
                        AppTheme.appleMusicRed.withValues(alpha: 0.7),
                      ]
                    : [const Color(0xFF5856D6), const Color(0xFF007AFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPlaying
                  ? CupertinoIcons.waveform
                  : CupertinoIcons.radiowaves_right,
              color: Colors.white,
              size: 28,
            ),
          ),
          title: Text(
            station.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isPlaying
                  ? AppTheme.appleMusicRed
                  : (isDark ? Colors.white : Colors.black),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            station.streamUrl,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isPlaying
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.appleMusicRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.waveform,
                        color: AppTheme.appleMusicRed,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppTheme.appleMusicRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : Icon(
                  CupertinoIcons.play_circle_fill,
                  color: isDark ? Colors.white38 : Colors.black26,
                  size: 32,
                ),
          onTap: onTap,
          onLongPress: onLongPress,
        );
      },
    );
  }
}

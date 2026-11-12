import 'package:flutter/material.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/song_divider.dart';
import '../widgets/song_tile.dart';

/// 探索发现详情页 —— **与收藏 / 歌单详情同款**（2026-10-24 用户拍板，§8.5）：
/// hero 头（inset 流体卡 + 中央图标 + 标题 + 副题 + 共 N 首 + ▶播放 / ⤨随机）
/// + 64dp 歌曲行 + 分隔线 + 底部 100（覆盖式播放条净空）。
///
/// 推荐顺序即语义，**不做排序**；歌曲由首页 feed 直接传入（不依赖首页重建）。
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({
    super.key,
    required this.songs,
    this.subtitle,
  });

  final List<Song> songs;
  final String? subtitle;

  void _playAll(BuildContext context, {bool shuffle = false}) {
    if (songs.isEmpty) return;
    final list = List<Song>.from(songs);
    if (shuffle) list.shuffle();
    Provider.of<PlayerProvider>(context, listen: false)
        .playSong(list.first, playlist: list, startIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: LuoboHeroCardHeader(
                  title: l10n.discover,
                  subtitle: subtitle ?? l10n.discoverSlogan1,
                  countLabel: l10n.songsCount(songs.length),
                  // 无单一封面 → 冷色盘 + 中央星形（与收藏「暖色 + 心形」/
                  // 最近播放「冷色 + 时钟」同一套无封面范式）。
                  card: Stack(
                    fit: StackFit.expand,
                    children: [
                      const FluidBackground(
                        colors: [
                          Color(0xFF3D6BFF),
                          Color(0xFF9B6BFF),
                          Color(0xFF2FBBDD),
                        ],
                        borderRadius: 16,
                        seed: 3.6,
                      ),
                      Center(
                        child: Icon(
                          AppIcons.ai,
                          size: 72,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  onPlay: () => _playAll(context),
                  onShuffle: () => _playAll(context, shuffle: true),
                ),
              ),
              if (songs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: LuoboEmptyState(message: l10n.noContentAvailable),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      return Column(
                        children: [
                          SongTile(
                            song: song,
                            playlist: songs,
                            index: index,
                          ),
                          if (index < songs.length - 1)
                            const LuoboSongDivider(),
                        ],
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: LuoboSpacing.pageBottomWithStrip(context))),
            ],
          ),
          // 悬浮顶栏（圆返回；滚动常驻、无实色栏）—— 与收藏 / 歌单详情一致。
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    LuoboTopCircleButton(
                      icon: AppIcons.back,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/navigation_helper.dart';
import 'albums_screen.dart';
import 'all_songs_screen.dart';
import 'artists_list_screen.dart';
import 'audiobook_list_screen.dart';
import 'favorites_screen.dart';
import 'playlists_screen.dart';
import 'radio_screen.dart';
import 'search_screen.dart';

/// 音乐库入口页（2026-10-23，设计见 `docs/音乐库入口页技术方案.md`）。
///
/// 结构对齐 fnos「音乐库 = 入口页」：大标题 → 搜索入口（只读，点击才进搜索页）
/// → 2 列入口卡（全部歌曲 / 全部歌手 / 全部专辑 / 歌单 / 收藏 / 有声书|电台）。
/// 旧的 TabBar 版 `LibraryScreen` 保留作回退，不再挂在移动端底栏。
class LibraryHubScreen extends StatelessWidget {
  const LibraryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);
    final isDaoliyu =
        Provider.of<AuthProvider>(context, listen: false)
            .config
            ?.serverFamily ==
        'daoliyu';

    final entries = <_HubEntry>[
      _HubEntry(
        title: l10n.allSongs,
        icon: Icons.music_note_rounded,
        colors: const [Color(0xFF7B61FF), Color(0xFFE855A8)],
        onTap: () => _push(context, const AllSongsScreen()),
      ),
      _HubEntry(
        title: l10n.artists,
        icon: Icons.person_rounded,
        colors: const [Color(0xFFFC7B3C), Color(0xFFF0453F)],
        onTap: () => _push(context, const ArtistsListScreen()),
      ),
      _HubEntry(
        title: l10n.albums,
        icon: Icons.album_rounded,
        colors: const [Color(0xFFFFB03A), Color(0xFFF2701B)],
        onTap: () => _push(context, const AlbumsScreen()),
      ),
      _HubEntry(
        title: l10n.playlists,
        icon: Icons.queue_music_rounded,
        colors: const [Color(0xFF3CC98A), Color(0xFF0E9F8E)],
        onTap: () => _push(context, const PlaylistsScreen()),
      ),
      _HubEntry(
        title: l10n.favorites,
        icon: Icons.favorite_rounded,
        colors: const [Color(0xFFF93D4E), Color(0xFFE855A8)],
        onTap: () => _push(context, const FavoritesScreen()),
      ),
      _HubEntry(
        title: isDaoliyu ? l10n.audiobooks : l10n.categoryRadio,
        icon: isDaoliyu ? Icons.menu_book_rounded : Icons.radio_rounded,
        colors: const [Color(0xFF4A7DFF), Color(0xFF5B45D6)],
        onTap: () {
          // 有声书页面全屏覆盖（根导航）：不展示音乐迷你播放条/底栏。
          if (isDaoliyu) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const AudiobookListScreen()),
            );
          } else {
            _push(context, const RadioScreen());
          }
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 2026-10-23：整块内容**垂直居中**（用户：贴底也难受）——
            // Column(center) 把剩余高度平分到上下两侧；小屏自动退化为可滚动。
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 28).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.library,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: c.fg,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SearchEntry(
                          hint: l10n.searchPlaceholder,
                          onTap: () => NavigationHelper.push(
                            context,
                            const SearchScreen(),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      // 与上方至少留 24，避免小屏贴在一起。
                      padding: const EdgeInsets.only(top: 24),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: entries.length,
                        itemBuilder: (context, index) =>
                            _HubCard(entry: entries[index]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    NavigationHelper.push(context, page);
  }
}

/// 只读搜索入口（白卡 r14 h48 + 放大镜 + 提示词）。
///
/// ⚠️ 这里**不做真输入**：点击 push 搜索页并自动聚焦，搜索历史因此只出现在
/// 搜索页（对齐 fnos：搜索框被点击后才进入单独一页）。
class _SearchEntry extends StatelessWidget {
  final String hint;
  final VoidCallback onTap;

  const _SearchEntry({required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(AppIcons.search, size: 20, color: c.fg3),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuoboType.body.copyWith(color: c.fg3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubEntry {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _HubEntry({
    required this.title,
    required this.icon,
    required this.colors,
    required this.onTap,
  });
}

/// 入口卡（沿用搜索页「浏览分类」的观感：渐变 r12 + 白 icon + 白标题）。
class _HubCard extends StatelessWidget {
  final _HubEntry entry;

  const _HubCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: entry.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: entry.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(entry.icon, color: Colors.white, size: 24),
                const Spacer(),
                Text(
                  entry.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

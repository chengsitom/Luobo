import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/library_provider.dart';
import '../../theme/app_icons.dart';
import '../../theme/design_tokens.dart';
import '../../utils/navigation_helper.dart';
import 'luobo_toast.dart';

/// 歌单模态表单（fnos v1_0088 新建 / v6_0042 编辑，规格见
/// `docs/歌曲列表弹窗对标飞牛技术方案.md` §4.4 + 表单范式）：
/// **无把手** + 顶部行（圆 `×` 左 / 居中标题 / **玫红实心圆 ✓** 右）
/// + 标签卡外 + 输入白卡 + 灰字说明。
///
/// ⚠️ fnos 的「封面预览 + ↻/✎」不画：歌单封面由服务端生成/回写不支持
/// （方案 §5），只做名称。
///
/// - [playlist] 为 null：新建；否则重命名（预填当前名称）。
Future<void> showPlaylistFormSheet(
  BuildContext context, {
  Playlist? playlist,
}) {
  final libraryProvider = Provider.of<LibraryProvider>(
    context,
    listen: false,
  );
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: LuoboMotion.scrim,
    builder: (_) => _PlaylistFormSheet(
      libraryProvider: libraryProvider,
      playlist: playlist,
    ),
  );
}

class _PlaylistFormSheet extends StatefulWidget {
  final LibraryProvider libraryProvider;
  final Playlist? playlist;

  const _PlaylistFormSheet({
    required this.libraryProvider,
    this.playlist,
  });

  @override
  State<_PlaylistFormSheet> createState() => _PlaylistFormSheetState();
}

class _PlaylistFormSheetState extends State<_PlaylistFormSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.playlist?.name ?? '',
  );
  bool _saving = false;

  bool get _isRename => widget.playlist != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    if (_isRename && name == widget.playlist!.name) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    final navCtx = NavigationHelper.navigatorKey.currentContext;
    try {
      if (_isRename) {
        await widget.libraryProvider.renamePlaylist(widget.playlist!.id, name);
      } else {
        await widget.libraryProvider.createPlaylist(name);
      }
      if (mounted) Navigator.pop(context);
      if (navCtx != null) {
        showLuoboToast(navCtx, message: l10n.saved, tone: LuoboToastTone.success);
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      if (navCtx != null) {
        showLuoboToast(
          navCtx,
          message: '${l10n.error}: $e',
          tone: LuoboToastTone.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      // 键盘弹起时整体上移。
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部行：圆 ×（左）+ 居中标题 + 玫红实心圆 ✓（右）。
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(AppIcons.close, size: 20, color: c.fg),
                      ),
                    ),
                    Text(
                      _isRename ? l10n.renamePlaylist : l10n.newPlaylist,
                      style: LuoboType.navTitle.copyWith(fontSize: 15),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _submit,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: LuoboAccent.accent,
                            shape: BoxShape.circle,
                          ),
                          child: _saving
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  AppIcons.check,
                                  size: 15,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 标签卡外 + 输入白卡（fnos 表单范式）。
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  l10n.playlistName,
                  style: LuoboType.caption.copyWith(color: c.fg2),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 灰字说明（fnos 同构；从旧对话框文案迁移）。
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.playlistNameRule,
                  style: LuoboType.caption.copyWith(color: c.fg3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
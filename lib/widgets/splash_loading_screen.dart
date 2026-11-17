import 'package:flutter/material.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/screen_helper.dart';

/// 冷启品牌启动页 —— 替代原来光秃秃的 CircularProgressIndicator。
///
/// 监听 [AuthProvider.startupPhase]，把"正在做什么"明确告诉用户，消除
/// 黑盒转角的无助感。视觉与登录页同源：流体渐变 + 白圆角 logo 卡 + 品牌名。
///
/// 不改动连接逻辑，只做状态展示；阶段由 AuthProvider 在网络流程各节点推送。
class SplashLoadingScreen extends StatefulWidget {
  /// 冷启早期 AuthProvider 可能还没注入（provider 在 MultiProvider 里创建），
  /// 此时传 null，页面退化为只显示 logo + 默认"连接中"文案。
  final ValueNotifier<StartupPhase>? phase;

  const SplashLoadingScreen({super.key, this.phase});

  @override
  State<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends State<SplashLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 与登录页/收藏页同源的流体暖色盘，品牌玫红打头。
          // painter 固定访问 colors[3] 作底色，必须给满 4 色否则测试/首帧越界。
          const FluidBackground(
            colors: [
              Color(0xFFF0305C),
              Color(0xFFFF7A3C),
              Color(0xFFFFB03A),
              Color(0xFFC9305C),
            ],
            seed: 0.7,
          ),
          // 顶部渐变压暗，给白色 logo 卡留出对比度。
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x1A000000), Colors.transparent],
                stops: [0, 0.4],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(context),
                const SizedBox(height: 28),
                Text(
                  l10n?.appName ?? 'Luobo',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: ScreenHelper.isSmallScreen(context) ? 30 : 36,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // 底部阶段文案 + 进度条：用户据此知道"在建树、还要等什么"。
          Positioned(
            left: 40,
            right: 40,
            bottom: 72,
            child: widget.phase == null
                ? _buildStage(StartupPhase.connecting, l10n)
                : ValueListenableBuilder<StartupPhase>(
                    valueListenable: widget.phase!,
                    builder: (context, phase, _) => _buildStage(phase, l10n),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final size = ScreenHelper.loginLogoSize(context);
    // 轻微呼吸（scale 0.96→1.04），让静态等待有生命力但不过分抢眼。
    return ScaleTransition(
      scale: Tween(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _breath, curve: Curves.easeInOut),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: Image.asset('assets/logobig.png', fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildStage(StartupPhase phase, AppLocalizations? l10n) {
    final (text, accent) = switch (phase) {
      StartupPhase.connecting => (
        l10n?.startupConnecting ?? 'Connecting…',
        false,
      ),
      StartupPhase.verifying => (
        l10n?.startupVerifying ?? 'Verifying…',
        false,
      ),
      StartupPhase.preparing => (
        l10n?.startupPreparing ?? 'Preparing…',
        false,
      ),
      StartupPhase.failed => (
        l10n?.startupRetrying ?? 'Retrying…',
        true,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Text(
            text,
            key: ValueKey(phase),
            textAlign: TextAlign.center,
            style: LuoboType.body.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            // 不确定进度：不知道网络连接要多久，用循环动画而不是假百分比。
            minHeight: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              accent ? const Color(0xFFffe08a) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

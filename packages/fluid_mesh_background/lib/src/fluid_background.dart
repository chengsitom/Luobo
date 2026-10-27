import 'dart:math' as math;
import 'dart:ui' show FragmentProgram, FragmentShader;

import 'package:flutter/material.dart';

import 'fluid_clock.dart';
import 'fluid_events.dart';
import 'fluid_palette.dart';

/// An Apple-Music-style animated background: **colours extracted from an image,
/// laid out as a continuously flowing "fluid mesh" field**.
///
/// Two render paths are chosen automatically — callers don't need to care:
///
/// - **Fluid mesh (default)**: `shaders/fluid_mesh.frag`. A continuous velocity
///   field + value noise + sine warping + grain. The whole picture is one
///   *continuous field*, so there are no discrete shapes for the eye to track —
///   which is what makes it read as "flowing" rather than "some circles moving".
/// - **Palette fallback**: a soft gradient built from the extracted colours.
///   Used when the shader is unavailable (e.g. an unsupported render backend).
///
/// Minimal usage:
///
/// ```dart
/// FluidBackground(imageUrl: coverUrl, borderRadius: 12)
/// ```
///
/// Multiple instances on one screen should share a clock via
/// [FluidBackgroundScope]:
///
/// ```dart
/// FluidBackgroundScope(
///   child: GridView.builder(
///     itemCount: covers.length,
///     itemBuilder: (_, i) => FluidBackground(
///       imageUrl: covers[i],
///       // Give each item a different seed, otherwise they all show the same
///       // pattern structure.
///       seed: FluidBackground.seedForIndex(i),
///     ),
///   ),
/// )
/// ```
class FluidBackground extends StatefulWidget {
  /// Creates a fluid background.
  const FluidBackground({
    super.key,
    this.imageUrl,
    this.imageProvider,
    this.colors,
    this.clock,
    this.style = FluidBackgroundStyle.standard,
    this.borderRadius = 0,
    this.showScrim = false,
    this.seed = 0,
    this.useShader = true,
  });

  /// Convenience source: a URL loaded with [NetworkImage].
  ///
  /// Ignored when [imageProvider] or [colors] is given. If your app has its own
  /// image cache, prefer [imageProvider] so the background reuses it instead of
  /// downloading the image twice.
  final String? imageUrl;

  /// Explicit image source. Takes precedence over [imageUrl].
  final ImageProvider? imageProvider;

  /// Fixed 4 colours, skipping extraction. Takes precedence over the sources.
  final List<Color>? colors;

  /// Explicit clock. When null, the nearest [FluidBackgroundScope] is used, and
  /// failing that a private one is created.
  final FluidClock? clock;

  /// Look-and-feel parameters (speed / warping / grain).
  final FluidBackgroundStyle style;

  /// Corner radius. Zero means no clipping.
  final double borderRadius;

  /// Overlays a top-to-bottom dark gradient. Use it when white text sits on
  /// top of the background.
  final bool showScrim;

  /// Per-instance offset that determines the **flow pattern** (direction, noise
  /// region, warp phase).
  ///
  /// Give each instance on screen a different value, otherwise they share the
  /// same pattern structure and read as one animation. Grids should use
  /// [seedForIndex].
  final double seed;

  /// Whether to try the fluid mesh shader. When it cannot be loaded the
  /// fallback painter is used silently.
  final bool useShader;

  /// A well-spread seed for the item at [index] in a grid or list: **45° steps**.
  ///
  /// The seed acts in three places inside the shader — the starting rotation
  /// (added directly), the noise sampling region (× 37) and the warp phase
  /// (× 3). Staggering only the time phase is **not** enough: the pattern
  /// structure stays identical (same direction, same grain) and the eye still
  /// reads it as one pattern. 45° steps make neighbouring items clearly
  /// different.
  static double seedForIndex(int index) => index * math.pi / 4;

  /// The asset key of the bundled fragment shader.
  static const String shaderAsset =
      'packages/fluid_mesh_background/shaders/fluid_mesh.frag';

  /// Fallback path: seconds for one full drift cycle.
  static const double driftPeriodSeconds = 16;

  /// Fallback path: the three blob anchor positions (top-left / top-right /
  /// bottom-centre).
  static const List<Alignment> blobAnchors = [
    Alignment(-0.8, -0.8),
    Alignment(0.8, -0.6),
    Alignment(0.0, 0.9),
  ];

  /// Fallback path: radius factor per blob.
  static const List<double> blobRadii = [0.9, 0.8, 0.85];

  /// Fallback path: drift amplitude in alignment units (1.0 ≈ half the widget).
  static const double driftAmplitudeX = 0.22;

  /// Fallback path: drift amplitude in alignment units, vertical.
  static const double driftAmplitudeY = 0.18;

  /// Fallback path: radius breathing amplitude, as a ratio.
  static const double driftRadiusBreath = 0.12;

  /// Fallback path: blob [index]'s centre at phase [t] (radians).
  ///
  /// ⚠️ Only **integer multiples** of [t] may be used, so the function is
  /// exactly 2π-periodic. Non-integer harmonics make the blob jump every time
  /// the phase wraps, which reads as "the animation has a definite end point".
  static Alignment blobAlignmentFor(int index, double t) {
    final base = blobAnchors[index];
    final p = t + index * (2 * math.pi / 3);
    return Alignment(
      (base.x + driftAmplitudeX * math.sin(p)).clamp(-1.0, 1.0),
      (base.y + driftAmplitudeY * math.cos(p)).clamp(-1.0, 1.0),
    );
  }

  /// Fallback path: blob [index]'s radius breathing factor at phase [t].
  /// Also 2π-periodic, for the same reason as [blobAlignmentFor].
  static double blobRadiusFactorFor(int index, double t) {
    final p = t + index * (2 * math.pi / 3);
    return 1 + driftRadiusBreath * math.sin(2 * p);
  }

  @override
  State<FluidBackground> createState() => _FluidBackgroundState();
}

/// Look-and-feel parameters for the fluid field.
@immutable
class FluidBackgroundStyle {
  /// Creates a style. Every parameter has a sensible default.
  const FluidBackgroundStyle({
    this.speed = 0.34,
    this.warp = 3.2,
    this.grain = 0.05,
  });

  /// The defaults.
  static const FluidBackgroundStyle standard = FluidBackgroundStyle();

  /// **Flow speed multiplier**: `shader time = real seconds × speed`.
  ///
  /// `1.0` is the raw rate baked into the shader; smaller is slower. `0.34`
  /// takes roughly 24 s for a colour band to cross the widget — slow enough to
  /// feel like a background, fast enough not to look frozen.
  ///
  /// 2026-10-24 用户反馈「流动太慢」：0.27 → **0.34**（约 +26%）。
  final double speed;

  /// Warping strength. Larger makes the bands gentler; too small turns them
  /// into a dense sawtooth.
  final double warp;

  /// Grain strength — the "sand" texture. Larger is grainier.
  final double grain;

  /// Maps real seconds to shader time.
  double meshTimeFor(double seconds) => seconds * speed;

  /// Writes every uniform the shader expects.
  ///
  /// Kept in one place so the painter and the tests cannot drift apart — the
  /// **indices** are determined by the declaration order in the GLSL source.
  void applyUniforms(
    FragmentShader shader, {
    required double width,
    required double height,
    required double shaderTime,
    required double seed,
    required List<Color> colors,
  }) {
    // Indices must match shaders/fluid_mesh.frag:
    // 0-1 uSize / 2 uTime / 3 uSeed / 4 uWarp / 5 uGrain / 6..17 four colours
    shader.setFloat(0, width);
    shader.setFloat(1, height);
    shader.setFloat(2, shaderTime);
    shader.setFloat(3, seed);
    shader.setFloat(4, warp);
    shader.setFloat(5, grain);
    var i = 6;
    for (final color in colors) {
      shader.setFloat(i++, color.r);
      shader.setFloat(i++, color.g);
      shader.setFloat(i++, color.b);
    }
  }
}

/// Shares one [FluidClock] with every [FluidBackground] in [child].
///
/// Why this exists: giving each instance its own ticker is wasteful, and more
/// importantly a subtree needs a single place that can **pause** the animation.
/// This widget owns its [TickerProvider] and starts/stops the clock according to
/// [TickerMode], so callers don't have to be stateful themselves.
///
/// That pause matters: `IndexedStack` wraps unselected children in
/// `Visibility(maintainAnimation: true)`, which does **not** disable
/// [TickerMode] — without an explicit stop, a hidden page keeps producing frames
/// every vsync.
class FluidBackgroundScope extends StatefulWidget {
  /// Creates a scope around [child].
  const FluidBackgroundScope({super.key, required this.child});

  /// The subtree sharing the clock.
  final Widget child;

  /// The clock shared by this subtree, or null when there is no scope above.
  static FluidClock? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FluidClockScope>()?.clock;

  @override
  State<FluidBackgroundScope> createState() => _FluidBackgroundScopeState();
}

class _FluidBackgroundScopeState extends State<FluidBackgroundScope>
    with SingleTickerProviderStateMixin {
  late final FluidClock _clock = FluidClock(this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) {
      _clock.start();
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _FluidClockScope(clock: _clock, child: widget.child);
}

class _FluidClockScope extends InheritedWidget {
  const _FluidClockScope({required this.clock, required super.child});

  final FluidClock clock;

  @override
  bool updateShouldNotify(_FluidClockScope oldWidget) =>
      oldWidget.clock != clock;
}

class _FluidBackgroundState extends State<FluidBackground>
    with SingleTickerProviderStateMixin {
  FluidClock? _scopeClock;
  FluidClock? _ownClock;
  late List<Color> _colors;

  FragmentShader? _shader;

  FluidClock get _clock => widget.clock ?? _scopeClock ?? _ownClock!;

  /// The image source actually used, honouring the documented precedence.
  ImageProvider? get _provider {
    if (widget.colors != null) return null;
    final explicit = widget.imageProvider;
    if (explicit != null) return explicit;
    final url = widget.imageUrl;
    return url == null || url.isEmpty ? null : NetworkImage(url);
  }

  @override
  void initState() {
    super.initState();
    _colors = widget.colors ?? FluidPalette.defaultColors;
    if (widget.colors == null) _resolvePalette();
    if (widget.useShader) _resolveShader();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveClock();
  }

  @override
  void didUpdateWidget(FluidBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.clock != oldWidget.clock) _resolveClock();

    if (widget.colors != null) {
      if (widget.colors != oldWidget.colors) {
        setState(() => _colors = widget.colors!);
      }
    } else if (widget.imageUrl != oldWidget.imageUrl ||
        widget.imageProvider != oldWidget.imageProvider) {
      _resolvePalette();
    }
  }

  /// Clock precedence: explicit > enclosing [FluidBackgroundScope] > private.
  ///
  /// The private clock follows [TickerMode] (the scope's clock is handled by the
  /// scope). Note that a `SingleTickerProviderStateMixin` allows exactly one
  /// ticker, so a private clock is created once and only released in [dispose].
  void _resolveClock() {
    _scopeClock = widget.clock == null
        ? FluidBackgroundScope.maybeOf(context)
        : null;

    if (widget.clock != null || _scopeClock != null) {
      _ownClock?.stop();
      return;
    }

    final own = _ownClock ??= FluidClock(this);
    if (TickerMode.valuesOf(context).enabled) {
      own.start();
    } else {
      own.stop();
    }
  }

  Future<void> _resolvePalette() async {
    final provider = _provider;
    final key = FluidPalette.keyFor(provider);

    final cached = FluidPalette.instance.cached(key);
    if (cached != null) {
      if (mounted) setState(() => _colors = cached);
      return;
    }

    final colors = await FluidPalette.instance.colorsFor(provider);
    if (!mounted) return;
    // Guard against a newer source having been set while we were extracting.
    if (_provider == provider) setState(() => _colors = colors);
  }

  Future<void> _resolveShader() async {
    FragmentProgram? program;
    Object? error;
    try {
      program = await FragmentProgram.fromAsset(FluidBackground.shaderAsset);
    } catch (e) {
      error = e;
    }
    FluidBackgroundEvents.emit(
      program == null ? 'shaderUnavailable' : 'shaderReady',
      {'available': program != null, if (error != null) 'error': '$error'},
    );
    if (!mounted) return;
    setState(() => _shader = program?.fragmentShader());
  }

  @override
  void dispose() {
    _shader?.dispose();
    _ownClock?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Until the shader finishes loading (a few ms of asset read) the fallback
    // paints, so the area is never blank.
    final useShader = widget.useShader && _shader != null;

    Widget content = RepaintBoundary(
      child: CustomPaint(
        painter: useShader
            ? _FluidMeshPainter(
                shader: _shader!,
                colors: _colors,
                clock: _clock,
                seed: widget.seed,
                style: widget.style,
              )
            : _FluidGradientPainter(
                colors: _colors,
                clock: _clock,
                seed: widget.seed,
              ),
        size: Size.infinite,
      ),
    );

    if (widget.showScrim) {
      content = Stack(
        fit: StackFit.expand,
        children: [content, const _ScrimOverlay()],
      );
    }

    if (widget.borderRadius > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: content,
      );
    }
    return content;
  }
}

/// The fluid mesh field: every pixel's colour comes from noise coordinates, so
/// there are no discrete shapes.
class _FluidMeshPainter extends CustomPainter {
  _FluidMeshPainter({
    required this.shader,
    required this.colors,
    required this.clock,
    required this.seed,
    required this.style,
  }) : super(repaint: clock);

  final FragmentShader shader;
  final List<Color> colors;
  final FluidClock clock;
  final double seed;
  final FluidBackgroundStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    style.applyUniforms(
      shader,
      width: size.width,
      height: size.height,
      // Monotonic seconds × speed: noise never wraps, so it truly keeps flowing.
      shaderTime: style.meshTimeFor(clock.value),
      seed: seed,
      colors: colors,
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _FluidMeshPainter oldDelegate) =>
      oldDelegate.shader != shader ||
      oldDelegate.colors != colors ||
      oldDelegate.clock != clock ||
      oldDelegate.seed != seed ||
      oldDelegate.style != style;
}

/// Fallback path: a base colour plus three softly drifting radial blobs.
///
/// Only used when the shader cannot be loaded. The geometry is 2π-periodic so
/// the monotonic clock never produces a visible jump.
class _FluidGradientPainter extends CustomPainter {
  _FluidGradientPainter({
    required this.colors,
    required this.clock,
    required this.seed,
  }) : super(repaint: clock);

  final List<Color> colors;
  final FluidClock clock;
  final double seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = colors[3]);

    final t =
        clock.value / FluidBackground.driftPeriodSeconds * 2 * math.pi + seed;
    final shortest = size.shortestSide;

    for (var i = 0; i < 3; i++) {
      final alignment = FluidBackground.blobAlignmentFor(i, t);
      final center = alignment.withinRect(rect);
      final radius = FluidBackground.blobRadii[i] *
          FluidBackground.blobRadiusFactorFor(i, t) *
          0.7 *
          shortest;
      if (radius <= 0) continue;

      final color = colors[i];
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.85),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FluidGradientPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.clock != clock ||
      oldDelegate.seed != seed;
}

/// A top-to-bottom dark gradient that keeps white text legible.
class _ScrimOverlay extends StatelessWidget {
  const _ScrimOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(0, 0, 0, 0.42),
            Color.fromRGBO(0, 0, 0, 0.70),
          ],
        ),
      ),
    );
  }
}

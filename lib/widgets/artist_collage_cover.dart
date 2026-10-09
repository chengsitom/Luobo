import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subsonic_service.dart';
import '../utils/image_cache.dart';
import 'album_artwork.dart';
import 'artist_placeholder.dart';

/// 艺术家专辑封面拼贴：按专辑数量自适应布局（docs/音乐库艺术家页改版
/// 技术方案.md §4.2 第 4 级）。纯本地缓存数据（cachedAllAlbums），零网络。
///
/// 布局规则（gap 1px，封面一律 BoxFit.cover 裁切填充，不留白）：
/// - ≥4 张：2×2 拼贴
/// - 3 张：左列竖大图 + 右列上下两小图
/// - 2 张：斜对角分割（左上/右下各一张）
/// - 1 张：单图铺满
///
/// Navidrome 对无封面专辑返回内嵌胶片占位图（全库共用同一张），客户端
/// 无法从 coverArt id 区分；用运行时 hash 学习：同一图累计出现 ≥3 次即
/// 判定为占位，全局排除并替换为 [placeholderName] 渐变占位。
class ArtistCollageCover extends StatelessWidget {
  final List<String> coverArtIds;

  /// 固定尺寸；为 null 时撑满父约束（要求父级已限定宽高）。
  final double? size;

  final double borderRadius;

  /// 占位图被剔除后该格显示的渐变首字母名（一般为艺术家名）。
  final String placeholderName;

  const ArtistCollageCover({
    super.key,
    required this.coverArtIds,
    this.size,
    this.borderRadius = 10,
    this.placeholderName = '',
  });

  static const double _gap = 1;

  @override
  Widget build(BuildContext context) {
    final ids = coverArtIds.take(4).toList();
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: _layout(ids, w, h),
        );
      },
    );
    final size = this.size;
    if (size == null) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: content,
      );
    }
    return SizedBox(width: size, height: size, child: content);
  }

  Widget _layout(List<String> ids, double w, double h) {
    if (ids.length >= 4) {
      // 2×2：四格等分
      final cell = ((w - _gap) / 2).clamp(1.0, double.infinity);
      return GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        mainAxisSpacing: _gap,
        crossAxisSpacing: _gap,
        children: [
          for (var i = 0; i < 4; i++)
            if (i < ids.length)
              _cell(ids[i], cell, cell)
            else
              const SizedBox.expand(),
        ],
      );
    }
    if (ids.length == 3) {
      // 三条平行斜带（沿左上→右下，"/ / /"），每张封面裁进一条斜带。
      return Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < 3; i++)
            ClipPath(
              clipper: _SlantStripClipper(index: i, count: 3),
              child: _cell(ids[i], w, h),
            ),
          const IgnorePointer(
            child: CustomPaint(painter: _SlantLinesPainter(count: 3)),
          ),
        ],
      );
    }
    if (ids.length == 2) {
      // 斜对角分割：底图铺满 + 顶图裁左上三角（右下由底图补），
      // 沿左上→右下斜线分隔；封面各自 BoxFit.cover 裁切，不留白。
      return Stack(
        fit: StackFit.expand,
        children: [
          _cell(ids[1], w, h),
          ClipPath(
            clipper: const _TriangleClipper(topLeft: true),
            child: _cell(ids[0], w, h),
          ),
          // 斜分隔线（半透明白，增强分割感）
          const IgnorePointer(
            child: CustomPaint(painter: _DiagonalLinePainter()),
          ),
        ],
      );
    }
    // 单图铺满
    return _cell(ids[0], w, h);
  }

  /// 单格封面（带 Navidrome 胶片占位图检测）。子图自身不设圆角/阴影，
  /// 整体圆角由外层 ClipRRect 控制。
  Widget _cell(String coverArt, double w, double h) {
    return _CoverCell(
      coverArt: coverArt,
      cellWidth: w,
      placeholderName: placeholderName,
    );
  }
}

/// 单格封面：加载后检测是否为 Navidrome 占位图（hash 学习），
/// 是则用渐变占位替换，否则渲染封面（BoxFit.cover 裁切填充）。
class _CoverCell extends StatefulWidget {
  final String coverArt;
  final double cellWidth;
  final String placeholderName;

  const _CoverCell({
    required this.coverArt,
    required this.cellWidth,
    required this.placeholderName,
  });

  @override
  State<_CoverCell> createState() => _CoverCellState();
}

class _CoverCellState extends State<_CoverCell> {
  bool _isPlaceholder = false;

  /// coverArt id → 检测结果缓存：GridView 懒加载会 dispose/重建格子，
  /// 同一 id 重建时直接读缓存，不重复 hash + 不污染计数。
  static final Map<String, bool> _resultCache = {};

  @override
  void initState() {
    super.initState();
    _detectPlaceholder();
  }

  Future<void> _detectPlaceholder() async {
    final cached = _resultCache[widget.coverArt];
    if (cached != null) {
      if (cached) _setPlaceholder();
      return;
    }
    final svc = Provider.of<SubsonicService>(context, listen: false);
    final url = svc.getCoverArtUrl(widget.coverArt, size: kCoverArtRequestSize);
    if (url.isEmpty) {
      _resultCache[widget.coverArt] = true;
      _setPlaceholder();
      return;
    }
    try {
      // 只检测已缓存文件，不发起独立下载：getSingleFile 在 URL 未缓存时会
      // 下载，与正常封面加载（CachedNetworkImage）双重下载同一文件，几十格
      // 并发会明显拖慢首屏。未缓存 → 信任正常渲染，下次缓存命中再检测。
      final cachedFile = await coverCacheManager
          .getFileFromCache(coverArtCacheKeyFromUrl(url));
      if (cachedFile == null || !mounted) return;
      final hash =
          sha256.convert(await cachedFile.file.readAsBytes()).toString();
      final detected = PlaceholderArtworkDetector.isPlaceholder(
        hash,
        widget.coverArt,
      );
      _resultCache[widget.coverArt] = detected;
      if (detected) _setPlaceholder();
    } catch (_) {
      // 读取失败不判定，交给 AlbumArtwork 的 error 兜底。
    }
  }

  void _setPlaceholder() {
    if (mounted) setState(() => _isPlaceholder = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isPlaceholder) {
      return ArtistPlaceholder(name: widget.placeholderName, borderRadius: 0);
    }
    return AlbumArtwork(
      coverArt: widget.coverArt,
      // tight 约束下多余尺寸会被 clamp 到格子，这里传格宽供占位/阴影计算。
      size: widget.cellWidth,
      borderRadius: 0,
      shadow: const BoxShadow(color: Colors.transparent),
    );
  }
}

/// Navidrome 胶片占位图检测（运行时自学习）：
/// 无封面专辑共用同一张内嵌占位图 → 同一 sha256 会出现在**多个不同专辑
/// id** 上；真实封面各自的 hash 只出现在自己的专辑 id 上。因此按
/// 「hash → 不同专辑 id 集合」，集合 ≥ [threshold] 才判定为占位——
/// 同专辑反复渲染（GridView 重建）不累加，不会误伤真封面。
class PlaceholderArtworkDetector {
  static const int threshold = 3;
  static final Map<String, Set<String>> _seenIds = {};
  static final Set<String> _known = {};

  static bool isPlaceholder(String hash, String coverArtId) {
    if (_known.contains(hash)) return true;
    final ids = _seenIds.putIfAbsent(hash, () => <String>{});
    ids.add(coverArtId);
    if (ids.length >= threshold) {
      _known.add(hash);
      return true;
    }
    return false;
  }

  /// 测试用：重置学习状态。
  static void reset() {
    _seenIds.clear();
    _known.clear();
  }
}

/// 沿左上→右下对角线的三角裁切（topLeft=true 保留左上三角）。
class _TriangleClipper extends CustomClipper<Path> {
  final bool topLeft;

  const _TriangleClipper({required this.topLeft});

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(topLeft ? size.width : 0, 0)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_TriangleClipper oldClipper) =>
      oldClipper.topLeft != topLeft;
}

/// 左上→右下 1px 斜分隔线。
class _DiagonalLinePainter extends CustomPainter {
  const _DiagonalLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_DiagonalLinePainter oldDelegate) => false;
}

/// 平行斜带裁切（沿左上→右下方向，"/" 斜带）：把方形沿 x+y 投影均分
/// 成 [count] 条斜带，第 [index] 条作为剪裁区域。三张封面即 3 条 "/ / /"。
class _SlantStripClipper extends CustomClipper<Path> {
  final int index;
  final int count;

  const _SlantStripClipper({required this.index, required this.count});

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final total = w + h;
    final lo = index * total / count;
    final hi = (index + 1) * total / count;
    final pts = <Offset>[];
    // 沿方形边界收集 x+y ∈ [lo,hi] 的线段端点（含角点）：
    // 只取两条边界线交点会漏掉「含角点」的中间条带，导致角留空。
    _addEdge(pts, 0, h, lo, hi, (t) => Offset(0, t)); // 左：x+y=y
    _addEdge(pts, h, total, lo, hi, (t) => Offset(t - h, h)); // 下：x+y=H+x
    _addEdge(pts, w, total, lo, hi, (t) => Offset(w, t - w)); // 右：x+y=W+y
    _addEdge(pts, 0, w, lo, hi, (t) => Offset(t, 0)); // 上：x+y=x
    if (pts.isEmpty) return Path();
    // 按边界周长排序围成多边形，去重后连线。
    pts.sort(
      (a, b) => _perimeterT(a, size).compareTo(_perimeterT(b, size)),
    );
    final seen = <String>{};
    final uniq = pts.where((p) => seen.add('${p.dx},${p.dy}')).toList();
    if (uniq.length < 3) return Path(); // 退化（条带切到角）
    final path = Path()..moveTo(uniq.first.dx, uniq.first.dy);
    for (final p in uniq.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  /// 边上 x+y ∈ [a,b] 的线段与条带 [lo,hi] 求交，把端点加入 [pts]。
  void _addEdge(
    List<Offset> pts,
    double a,
    double b,
    double lo,
    double hi,
    Offset Function(double t) at,
  ) {
    final from = a > lo ? a : lo;
    final to = b < hi ? b : hi;
    if (to < from) return;
    pts.add(at(from));
    pts.add(at(to));
  }

  /// 边界周长参数（逆时针：左→下→右→上），用于交点排序。
  double _perimeterT(Offset p, Size size) {
    final w = size.width, h = size.height;
    if (p.dx == 0) return p.dy; // 左边（上→下）
    if (p.dy == h) return h + p.dx; // 下边（左→右）
    if (p.dx == w) return h + w + (h - p.dy); // 右边（下→上）
    return 2 * h + w + (w - p.dx); // 上边（右→左）
  }

  @override
  bool shouldReclip(_SlantStripClipper old) =>
      old.index != index || old.count != count;
}

/// 平行斜带之间的 1px 分隔线（x+y = k*(W+H)/count，k=1..count-1）。
class _SlantLinesPainter extends CustomPainter {
  final int count;

  const _SlantLinesPainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final total = size.width + size.height;
    for (var k = 1; k < count; k++) {
      final line = _lineRect(k * total / count, size);
      if (line.length == 2) {
        canvas.drawLine(line[0], line[1], paint);
      }
    }
  }

  /// 直线 x+y=k 与方形边界交点（与 clipper 同逻辑，取两端点）。
  List<Offset> _lineRect(double k, Size size) {
    final w = size.width, h = size.height;
    final pts = <Offset>[];
    if (k >= 0 && k <= h) pts.add(Offset(0, k));
    if (k >= h && k <= w + h) pts.add(Offset(k - h, h));
    if (k >= w && k <= w + h) pts.add(Offset(w, k - w));
    if (k >= 0 && k <= w) pts.add(Offset(k, 0));
    final seen = <String>{};
    return pts.where((p) => seen.add('${p.dx},${p.dy}')).toList();
  }

  @override
  bool shouldRepaint(_SlantLinesPainter oldDelegate) =>
      oldDelegate.count != count;
}

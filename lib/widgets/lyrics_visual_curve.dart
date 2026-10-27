// ─────────────────────────────────────────────────────────────────────────────
// Lyric line visual curves — Apple Music aligned values.
//
// These top-level functions define how a lyric line's appearance (blur,
// scale, opacity) changes with its distance from the active line. Values
// match Apple Music's native lyrics page: no blur (distant lines fade via
// pure alpha), symmetric dimming for past/future lines, and a clear size
// ladder. Kept as pure functions so the exact numbers are pinned by unit
// tests (test/widgets/lyrics_visual_curve_test.dart) against regressions.
// ─────────────────────────────────────────────────────────────────────────────

/// Blur radius for a lyric line at [itemIndex] relative to [activeIndex].
///
/// Apple Music does not blur distant lines — they fade out via opacity only,
/// so this is always 0.0. The blur pipeline is kept for future configurability.
double lyricBlur(int itemIndex, int activeIndex) => 0.0;

/// Scale factor for a lyric line at [itemIndex] relative to [activeIndex]:
/// active line 1.0, then a clear ladder **0.85 / 0.74 / 0.64**
/// （2026-10-23：用户觉得非当前行仍偏大，在原 0.88/0.80/0.74 基础上再收一档）。
double lyricScale(int itemIndex, int activeIndex) {
  if (activeIndex < 0) return 0.90;
  if (itemIndex == activeIndex) return 1.0;
  final distance = (itemIndex - activeIndex).abs();
  if (distance == 1) return 0.85;
  if (distance == 2) return 0.74;
  return 0.64;
}

/// Opacity for a lyric line at [itemIndex] relative to [activeIndex].
///
/// Symmetric: past and future lines at the same distance share the same
/// opacity (Apple Music dims both directions equally):
/// 1.0 / 0.5 / 0.28 / 0.16 / 0.08.
double lyricOpacity(int itemIndex, int activeIndex) {
  if (activeIndex < 0) return 0.55;
  if (itemIndex == activeIndex) return 1.0;
  final distance = (itemIndex - activeIndex).abs();
  if (distance == 1) return 0.5;
  if (distance == 2) return 0.28;
  if (distance == 3) return 0.16;
  return 0.08;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An ultra-efficient static Silhouette Landscape with rich multi-layered depth
/// (atmospheric perspective) that emerges from behind the curved white card,
/// framing the clock in a lush, peaceful Islamic spiritual sanctuary.
///
/// Designed as a monumental spiritual journey:
/// Full 100% bloom represents 5x Khatam Al-Qur'an + 990x Dzikir (30 putaran tasbih).
///
/// Battery Optimization:
/// - Idle state: 100% static, 0 tickers running, 0% CPU/GPU consumption.
/// - Tap interaction: A gentle breeze rustles the pine trees, cattails, and reeds
///   for ~1.2s then settles completely to sleep (0% idle battery drain).
class GrowthTreeWidget extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final int khatmCount;
  final VoidCallback? onTap;
  final double? externalBreeze; // Tranquil external breeze sway value (-1.0 to 1.0)
  final double? animatedProgress; // Live interpolated progress (0.0 to 1.0)

  const GrowthTreeWidget({
    super.key,
    required this.progress,
    required this.khatmCount,
    this.onTap,
    this.externalBreeze,
    this.animatedProgress,
  });

  @override
  State<GrowthTreeWidget> createState() => _GrowthTreeWidgetState();
}

class _GrowthTreeWidgetState extends State<GrowthTreeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _windController;

  @override
  void initState() {
    super.initState();
    _windController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _windController.dispose();
    super.dispose();
  }

  void _triggerWindBreeze() {
    widget.onTap?.call();
    // Play gentle breeze rustle on individual foliage objects
    _windController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerWindBreeze,
        child: AnimatedBuilder(
          animation: _windController,
          builder: (context, _) {
            final t = _windController.value;
            // Damped harmonic wind breeze for tap: peaks gently, swings back, settles calmly to 0.0
            final double tapWind;
            if (t == 0.0 || t >= 1.0) {
              tapWind = 0.0;
            } else {
              tapWind = math.sin(t * math.pi * 3.5) * math.exp(-3.2 * t);
            }

            final double effectiveWind = (widget.externalBreeze != null)
                ? (widget.externalBreeze! + tapWind * 0.5)
                : tapWind;

            final double effectiveProgress = (widget.animatedProgress ?? widget.progress).clamp(0.0, 1.0);

            return CustomPaint(
              painter: _SilhouetteGardenPainter(
                progress: effectiveProgress,
                khatmCount: widget.khatmCount,
                wind: effectiveWind,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

/// Painter for Lembah Danau & Pegunungan Berkabut (Alpine Lake & Mountain Sanctuary):
/// Highly aesthetic multi-layer vector silhouette:
/// - Layer 0: Dramatic alpine peaks with ridge facets, valley mist, divine light rays & golden Hilal (solid)
/// - Distant Waterfall: Slender cascading mountain waterfall flowing into the lake
/// - Layer 1: Serene glassy lake with reflections, ripples, gliding swans & traditional sampan
/// - Layer 2: Stratified rocky cliffs & majestic tiered pines (pines sway gently in breeze)
/// - Fauna:
///     * Left: Graceful Doe / Deer standing naturally at the water\'s edge
///     * Right: Noble Majestic Stag with sweeping branched antlers on the cliff
///     * Sky: Soaring eagles
///     * Lake: Pair of peaceful gliding swans (Sakinah)
/// - Layer 3: Foreground cattail reeds, blooming water lotuses, fern fronds & shore grasses (sway in breeze)
/// - Atmosphere: Golden lake glows & floating fireflies
class _SilhouetteGardenPainter extends CustomPainter {
  final double progress;
  final int khatmCount;
  final double wind; // -1.0 to 1.0 (0.0 when idle)

  _SilhouetteGardenPainter({
    required this.progress,
    required this.khatmCount,
    this.wind = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final p = progress.clamp(0.0, 1.0);

    // ── LAYER 0: Dramatic Alpine Peaks & Crescent Hilal (Solid / Stays Still) ──
    _drawLayer0AlpinePeaks(canvas, w, h, p);

    // ── DIVINE LIGHT RAYS: Streaming softly through the mountain pass ──
    if (p > 0.35) {
      _drawDivineRays(canvas, w, h, ((p - 0.35) / 0.65).clamp(0.0, 1.0));
    }

    // ── SKY FAUNA: Soaring Mountain Eagles ──
    _drawMountainEagles(canvas, w, h, p);

    // ── CASCADING WATERFALL: Flowing into the lake ──
    if (p > 0.20) {
      _drawAlpineWaterfall(canvas, w, h, ((p - 0.20) / 0.80).clamp(0.0, 1.0));
    }

    // ── LAYER 1: Serene Glassy Lake, Reflections, Ripples & Sampan ──
    _drawLayer1SereneLake(canvas, w, h, p);

    // ── WATER BIRDS: Pair of peaceful gliding swans (Sakinah) ──
    if (p > 0.50) {
      _drawLakeSwans(canvas, w, h, ((p - 0.50) / 0.50).clamp(0.0, 1.0));
    }

    // ── LAYER 2: Rocky Cliffs & Pines (Pines sway naturally with wind) ──
    _drawLayer2FramingPines(canvas, w, h, p);

    // ── WILDLIFE: Graceful Deer at Lakeside & Majestic Stag on Cliff ──
    _drawWildlife(canvas, w, h, p);

    // ── LAYER 3: Reeds, Cattails, Lotuses & Shoreline (Flora sways with wind) ──
    _drawLayer3ShorelineMeadow(canvas, w, h, p);

    // ── ATMOSPHERIC: Floating Golden Mountain Fireflies ──
    if (p > 0.15) {
      _drawAlpineMistParticles(canvas, w, h, ((p - 0.15) / 0.85).clamp(0.0, 1.0));
    }
  }

  /// Layer 0: Dramatic alpine peaks with ridge facets and atmospheric perspective
  /// (Mountains are completely solid and do not sway)
  void _drawLayer0AlpinePeaks(Canvas canvas, double w, double h, double p) {
    final deepPaint = Paint()
      ..color = const Color(0xFF044E3B).withValues(alpha: (0.08 + (p * 0.08)).clamp(0.08, 0.16))
      ..style = PaintingStyle.fill;

    final mountain1 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.38)
      ..lineTo(w * 0.10, h * 0.22)
      ..lineTo(w * 0.22, h * 0.35)
      ..lineTo(w * 0.34, h * 0.16)
      ..lineTo(w * 0.46, h * 0.32)
      ..lineTo(w * 0.60, h * 0.14)
      ..lineTo(w * 0.72, h * 0.28)
      ..lineTo(w * 0.84, h * 0.18)
      ..lineTo(w * 0.94, h * 0.27)
      ..lineTo(w, h * 0.23)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mountain1, deepPaint);

    // Ridge relief lines for 3D alpine depth
    final ridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.05 + (p * 0.06)).clamp(0.05, 0.11))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(w * 0.10, h * 0.22), Offset(w * 0.15, h * 0.36), ridgePaint);
    canvas.drawLine(Offset(w * 0.34, h * 0.16), Offset(w * 0.38, h * 0.33), ridgePaint);
    canvas.drawLine(Offset(w * 0.60, h * 0.14), Offset(w * 0.56, h * 0.31), ridgePaint);
    canvas.drawLine(Offset(w * 0.84, h * 0.18), Offset(w * 0.80, h * 0.29), ridgePaint);

    final mountain2 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.46)
      ..lineTo(w * 0.16, h * 0.33)
      ..lineTo(w * 0.36, h * 0.42)
      ..lineTo(w * 0.52, h * 0.36)
      ..lineTo(w * 0.70, h * 0.43)
      ..lineTo(w * 0.86, h * 0.34)
      ..lineTo(w, h * 0.40)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      mountain2,
      Paint()
        ..color = const Color(0xFF023829).withValues(alpha: (0.11 + (p * 0.08)).clamp(0.11, 0.20))
        ..style = PaintingStyle.fill,
    );

    final moonScale = (0.35 + (p * 0.65)).clamp(0.35, 1.0);
    _drawCrescentHilal(canvas, w * 0.50, h * 0.085, 13.0 * moonScale);
  }

  /// Soft Divine Sunbeams (Nur Ilahi)
  void _drawDivineRays(Canvas canvas, double w, double h, double intensity) {
    if (intensity <= 0.05) return;

    final rayPaint = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: (0.04 + (intensity * 0.06)).clamp(0.03, 0.10))
      ..style = PaintingStyle.fill;

    final origin = Offset(w * 0.48, h * 0.14);

    final ray1 = Path()
      ..moveTo(origin.dx - 4, origin.dy)
      ..lineTo(origin.dx + 4, origin.dy)
      ..lineTo(w * 0.35, h * 0.56)
      ..lineTo(w * 0.26, h * 0.56)
      ..close();
    canvas.drawPath(ray1, rayPaint);

    final ray2 = Path()
      ..moveTo(origin.dx - 2, origin.dy)
      ..lineTo(origin.dx + 5, origin.dy)
      ..lineTo(w * 0.58, h * 0.58)
      ..lineTo(w * 0.48, h * 0.58)
      ..close();
    canvas.drawPath(ray2, rayPaint);

    final ray3 = Path()
      ..moveTo(origin.dx + 2, origin.dy)
      ..lineTo(origin.dx + 7, origin.dy)
      ..lineTo(w * 0.74, h * 0.54)
      ..lineTo(w * 0.65, h * 0.54)
      ..close();
    canvas.drawPath(ray3, rayPaint);
  }

  /// Slender cascading mountain waterfall flowing down into the lake
  void _drawAlpineWaterfall(Canvas canvas, double w, double h, double scale) {
    if (scale <= 0.05) return;

    final fallX = w * 0.358;
    final topY = h * 0.32;
    final botY = h * 0.475;

    final waterPaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.30 + (scale * 0.45)).clamp(0.25, 0.75))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * scale
      ..strokeCap = StrokeCap.round;

    final fallPath = Path()
      ..moveTo(fallX, topY)
      ..quadraticBezierTo(fallX - 1.5, topY + 12, fallX, topY + 22)
      ..quadraticBezierTo(fallX + 1.8, topY + 34, fallX - 0.5, botY);
    canvas.drawPath(fallPath, waterPaint);

    final waterPaint2 = Paint()
      ..color = const Color(0xFFE0F2FE).withValues(alpha: (0.25 + (scale * 0.35)).clamp(0.20, 0.60))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    final fallPath2 = Path()
      ..moveTo(fallX + 2.0, topY + 6)
      ..quadraticBezierTo(fallX + 3.0, topY + 18, fallX + 1.2, botY);
    canvas.drawPath(fallPath2, waterPaint2);

    final mistPaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.15 + (scale * 0.20)).clamp(0.12, 0.35))
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(fallX, botY + 1), width: 14 * scale, height: 4 * scale),
      mistPaint,
    );
  }

  /// Soaring Mountain Eagles
  void _drawMountainEagles(Canvas canvas, double w, double h, double p) {
    final eagleScale = (0.35 + (p * 0.65)).clamp(0.35, 1.0);

    final eaglePaint = Paint()
      ..color = const Color(0xFF023624).withValues(
        alpha: (0.30 + (eagleScale * 0.38)).clamp(0.30, 0.68),
      )
      ..style = PaintingStyle.fill;

    final eagles = [
      (x: w * 0.27, y: h * 0.11, span: 22.0, angle: -0.14 + (wind * 0.05)),
      (x: w * 0.73, y: h * 0.10, span: 18.0, angle: 0.12 + (wind * 0.04)),
      (x: w * 0.18, y: h * 0.16, span: 14.0, angle: -0.08 + (wind * 0.04)),
      (x: w * 0.83, y: h * 0.15, span: 15.0, angle: 0.18 + (wind * 0.05)),
    ];

    final visibleCount = (eagles.length * (0.45 + (p * 0.55))).round();
    for (int i = 0; i < visibleCount; i++) {
      final e = eagles[i];
      _drawSoaringEagle(canvas, e.x, e.y, e.span * (0.75 + (eagleScale * 0.25)), e.angle, eaglePaint);
    }
  }

  /// Layer 1: Serene glassy lake, soft water ripples & traditional sampan
  void _drawLayer1SereneLake(Canvas canvas, double w, double h, double p) {
    final lakeAlpha = (0.14 + (p * 0.22)).clamp(0.14, 0.36);
    final lakePaint = Paint()
      ..color = const Color(0xFF023829).withValues(alpha: lakeAlpha)
      ..style = PaintingStyle.fill;

    final lakeBaseY = h * 0.47;
    final lake = Path()
      ..moveTo(0, h)
      ..lineTo(0, lakeBaseY)
      ..quadraticBezierTo(w * 0.25, lakeBaseY - (2 + 3 * p), w * 0.50, lakeBaseY - (1 + 2 * p))
      ..quadraticBezierTo(w * 0.75, lakeBaseY + (2 + 3 * p), w, lakeBaseY - (2 + 2 * p))
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(lake, lakePaint);

    final reflectPaint = Paint()
      ..color = const Color(0xFF012217).withValues(alpha: (0.06 + (p * 0.08)).clamp(0.06, 0.14))
      ..style = PaintingStyle.fill;
    final lakeReflect = Path()
      ..moveTo(0, lakeBaseY)
      ..lineTo(w, lakeBaseY)
      ..lineTo(w, lakeBaseY + 16)
      ..quadraticBezierTo(w * 0.5, lakeBaseY + 22, 0, lakeBaseY + 15)
      ..close();
    canvas.drawPath(lakeReflect, reflectPaint);

    // Specular Water Ripple Lines (subtly affected by breeze)
    final rippleAlpha = (0.14 + (p * 0.16)).clamp(0.12, 0.30);
    final ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: rippleAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final rippleShift = wind * 3.5;
    final ripples = [
      (x: w * 0.20 + rippleShift, y: lakeBaseY + 7, wLen: 36.0 + (16.0 * p)),
      (x: w * 0.48 + rippleShift, y: lakeBaseY + 12, wLen: 48.0 + (22.0 * p)),
      (x: w * 0.76 + rippleShift, y: lakeBaseY + 8, wLen: 40.0 + (18.0 * p)),
      (x: w * 0.33 + rippleShift, y: lakeBaseY + 20, wLen: 54.0 + (22.0 * p)),
      (x: w * 0.63 + rippleShift, y: lakeBaseY + 22, wLen: 44.0 + (20.0 * p)),
      (x: w * 0.44 + rippleShift, y: lakeBaseY + 28, wLen: 62.0 + (24.0 * p)),
    ];

    final rippleCount = (ripples.length * (0.60 + (p * 0.40))).round();
    for (int i = 0; i < rippleCount; i++) {
      final r = ripples[i];
      final half = r.wLen * 0.5;
      final path = Path()
        ..moveTo(r.x - half, r.y)
        ..quadraticBezierTo(r.x, r.y + 1.2, r.x + half, r.y);
      canvas.drawPath(path, ripplePaint);
    }

    // Mid-distant pines on far bank
    final farPineAlpha = (0.18 + (p * 0.24)).clamp(0.18, 0.42);
    final farPinePaint = Paint()
      ..color = const Color(0xFF01281B).withValues(alpha: farPineAlpha)
      ..style = PaintingStyle.fill;

    final farPineScale = 0.65 + (p * 0.35);
    final farPines = [
      [w * 0.08, lakeBaseY - 2, 42.0 * farPineScale, 16.0 * farPineScale],
      [w * 0.15, lakeBaseY - 4, 48.0 * farPineScale, 18.0 * farPineScale],
      [w * 0.23, lakeBaseY - 1, 38.0 * farPineScale, 15.0 * farPineScale],
      [w * 0.78, lakeBaseY + 2, 40.0 * farPineScale, 15.0 * farPineScale],
      [w * 0.86, lakeBaseY - 2, 50.0 * farPineScale, 19.0 * farPineScale],
      [w * 0.93, lakeBaseY - 3, 44.0 * farPineScale, 17.0 * farPineScale],
    ];

    for (final fp in farPines) {
      _drawTieredPineTree(canvas, fp[0], fp[1], fp[2], fp[3], farPinePaint, wind * 0.4);
    }

    // Traditional Wooden Sampan / Canoe
    if (p > 0.10) {
      final boatScale = ((p - 0.10) / 0.90).clamp(0.0, 1.0);
      final boatX = w * 0.55 + (wind * 2.0);
      final boatY = lakeBaseY + 16;
      _drawTraditionalBoat(canvas, boatX, boatY, 0.75 + (0.35 * boatScale), wind * 0.03);
    }
  }

  /// Pair of graceful swans gliding peacefully on the lake
  void _drawLakeSwans(Canvas canvas, double w, double h, double scale) {
    if (scale <= 0.05) return;

    final swanPaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.75 + (scale * 0.22)).clamp(0.70, 0.97))
      ..style = PaintingStyle.fill;

    final lakeBaseY = h * 0.47;
    final swanBob = math.sin(wind * math.pi) * 1.2;

    _drawSingleSwan(canvas, w * 0.39 + (wind * 2.5), lakeBaseY + 10 + swanBob, 0.95 * scale, swanPaint, true);
    _drawSingleSwan(canvas, w * 0.43 + (wind * 2.0), lakeBaseY + 12 + swanBob, 0.82 * scale, swanPaint, true);
  }

  void _drawSingleSwan(Canvas canvas, double cx, double cy, double scale, Paint paint, bool faceRight) {
    canvas.save();
    canvas.translate(cx, cy);
    if (!faceRight) {
      canvas.scale(-scale, scale);
    } else {
      canvas.scale(scale, scale);
    }

    final swanPath = Path()
      ..moveTo(-7, 0)
      ..quadraticBezierTo(0, 1.5, 7, 0)
      ..lineTo(9, -2.5)
      ..lineTo(6, -1.8)
      ..quadraticBezierTo(2, -2.5, -2, -3.0)
      ..quadraticBezierTo(-3.5, -7.0, -1.5, -11.0)
      ..quadraticBezierTo(-0.5, -13.0, 1.5, -13.5)
      ..lineTo(3.2, -13.2)
      ..lineTo(1.8, -12.4)
      ..quadraticBezierTo(0.2, -11.5, -0.5, -9.0)
      ..quadraticBezierTo(-1.8, -5.5, -5.0, -2.0)
      ..quadraticBezierTo(-6.8, -1.0, -7, 0)
      ..close();

    canvas.drawPath(swanPath, paint);

    final wakePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawLine(const Offset(7, 0), const Offset(13, 0.5), wakePaint);

    canvas.restore();
  }

  /// Layer 2: Stratified Rocky Cliffs & Majestic Tiered Pines
  /// (Cliffs stay firm; Pines sway naturally with wind)
  void _drawLayer2FramingPines(Canvas canvas, double w, double h, double p) {
    final pineProgress = (0.18 + (p * 0.82)).clamp(0.18, 1.0);

    final cliffPaint = Paint()
      ..color = const Color(0xFF023624).withValues(alpha: (0.45 + (pineProgress * 0.40)).clamp(0.45, 0.85))
      ..style = PaintingStyle.fill;

    final cliffLinePaint = Paint()
      ..color = const Color(0xFF045A3E).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final pinePaint = Paint()
      ..color = const Color(0xFF01281B).withValues(alpha: (0.50 + (pineProgress * 0.40)).clamp(0.50, 0.90))
      ..style = PaintingStyle.fill;

    // ── LEFT ROCKY BLUFF & PINES ──
    final lCliff = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - (78 * pineProgress))
      ..lineTo(w * 0.08, h - (82 * pineProgress))
      ..lineTo(w * 0.16, h - (64 * pineProgress))
      ..lineTo(w * 0.24, h - (46 * pineProgress))
      ..lineTo(w * 0.30, h - (36 * pineProgress))
      ..lineTo(w * 0.32, h)
      ..close();
    canvas.drawPath(lCliff, cliffPaint);

    canvas.drawLine(Offset(0, h - (55 * pineProgress)), Offset(w * 0.18, h - (45 * pineProgress)), cliffLinePaint);
    canvas.drawLine(Offset(w * 0.06, h - (70 * pineProgress)), Offset(w * 0.24, h - (38 * pineProgress)), cliffLinePaint);

    // Pines sway with wind: trunk anchored, upper tiers deflect naturally
    _drawTieredPineTree(canvas, w * 0.12, h - (82 * pineProgress), 108 * pineProgress, 38 * pineProgress, pinePaint, wind);

    if (pineProgress > 0.25) {
      _drawTieredPineTree(canvas, w * 0.22, h - (58 * pineProgress), 84 * pineProgress, 30 * pineProgress, pinePaint, wind * 0.85);
    }

    if (pineProgress > 0.45) {
      _drawTieredPineTree(canvas, w * 0.04, h - (74 * pineProgress), 76 * pineProgress, 28 * pineProgress, pinePaint, wind * 0.9);
    }

    // ── RIGHT ROCKY BLUFF & PINES ──
    final rCliff = Path()
      ..moveTo(w, h)
      ..lineTo(w, h - (82 * pineProgress))
      ..lineTo(w * 0.92, h - (86 * pineProgress))
      ..lineTo(w * 0.84, h - (68 * pineProgress))
      ..lineTo(w * 0.76, h - (48 * pineProgress))
      ..lineTo(w * 0.70, h - (38 * pineProgress))
      ..lineTo(w * 0.68, h)
      ..close();
    canvas.drawPath(rCliff, cliffPaint);

    canvas.drawLine(Offset(w, h - (60 * pineProgress)), Offset(w * 0.82, h - (50 * pineProgress)), cliffLinePaint);
    canvas.drawLine(Offset(w * 0.94, h - (74 * pineProgress)), Offset(w * 0.76, h - (40 * pineProgress)), cliffLinePaint);

    _drawTieredPineTree(canvas, w * 0.88, h - (86 * pineProgress), 114 * pineProgress, 40 * pineProgress, pinePaint, wind);

    if (pineProgress > 0.25) {
      _drawTieredPineTree(canvas, w * 0.78, h - (62 * pineProgress), 88 * pineProgress, 32 * pineProgress, pinePaint, wind * 0.85);
    }

    if (pineProgress > 0.45) {
      _drawTieredPineTree(canvas, w * 0.96, h - (78 * pineProgress), 80 * pineProgress, 28 * pineProgress, pinePaint, wind * 0.9);
    }
  }

  /// Wildlife: Graceful Deer at Lakeside & Majestic Stag on Cliff
  void _drawWildlife(Canvas canvas, double w, double h, double p) {
    // 1. Graceful Lakeside Deer
    if (p > 0.12) {
      final deerGrowth = ((p - 0.12) / 0.88).clamp(0.0, 1.0);
      final deerPaint = Paint()
        ..color = const Color(0xFF012015).withValues(alpha: 0.96)
        ..style = PaintingStyle.fill;
      final scale = 1.15 * (0.65 + (0.35 * deerGrowth));

      _drawGracefulLakesideDeer(canvas, w * 0.25, h - 38, scale, deerPaint);
    }

    // 2. Majestic Royal Stag
    if (p > 0.30) {
      final stagGrowth = ((p - 0.30) / 0.70).clamp(0.0, 1.0);
      final stagPaint = Paint()
        ..color = const Color(0xFF011C12).withValues(alpha: 0.98)
        ..style = PaintingStyle.fill;
      final scale = 1.25 * (0.65 + (0.35 * stagGrowth));

      _drawMajesticRoyalStag(canvas, w * 0.74, h - 46, scale, stagPaint);
    }
  }

  /// Layer 3: Foreground Reeds, Cattails, Lotuses & Shoreline Meadow
  /// (Individual plant stems bend and rustle naturally in the wind!)
  void _drawLayer3ShorelineMeadow(Canvas canvas, double w, double h, double p) {
    final reedProgress = (0.20 + (p * 0.80)).clamp(0.20, 1.0);

    final reedStemPaint = Paint()
      ..color = const Color(0xFF034A36).withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cattailHeadPaint = Paint()
      ..color = const Color(0xFF01241A).withValues(alpha: 0.98)
      ..style = PaintingStyle.fill;

    final lotusFlowerPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.98)
      ..style = PaintingStyle.fill;

    final padPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final crispPaint = Paint()
      ..color = const Color(0xFF022C22).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    // Corner Ferns sway with wind
    final fernScale = (0.25 + (p * 0.75)).clamp(0.25, 1.0);
    _drawFernFrond(canvas, w * 0.04, h, -0.42 + (wind * 0.08), 64 * fernScale, crispPaint);
    _drawFernFrond(canvas, w * 0.96, h, 0.42 + (wind * 0.08), 64 * fernScale, crispPaint);

    // Cattails & Lakeside Flora Array
    final flora = [
      (x: w * 0.02, y: h - 48.0, type: 0),
      (x: w * 0.06, y: h - 68.0, type: 1),
      (x: w * 0.10, y: h - 56.0, type: 0),
      (x: w * 0.15, y: h - 74.0, type: 1),
      (x: w * 0.20, y: h - 52.0, type: 2),

      (x: w * 0.32, y: h - 42.0, type: 1),
      (x: w * 0.38, y: h - 48.0, type: 2),
      (x: w * 0.44, y: h - 44.0, type: 1),
      (x: w * 0.50, y: h - 52.0, type: 2),
      (x: w * 0.56, y: h - 44.0, type: 1),
      (x: w * 0.62, y: h - 48.0, type: 2),
      (x: w * 0.68, y: h - 42.0, type: 1),

      (x: w * 0.80, y: h - 54.0, type: 2),
      (x: w * 0.85, y: h - 72.0, type: 1),
      (x: w * 0.90, y: h - 62.0, type: 0),
      (x: w * 0.94, y: h - 76.0, type: 1),
      (x: w * 0.98, y: h - 50.0, type: 0),
    ];

    final visibleCount = (flora.length * (0.35 + (p * 0.65))).round();

    for (int i = 0; i < visibleCount; i++) {
      final f = flora[i];
      final baseX = f.x;
      final curHeight = (h - f.y) * (0.50 + (reedProgress * 0.50));
      // Each stem bends gracefully proportional to its height
      final stemBend = wind * 12.0 * (curHeight / 60.0);
      final headX = baseX + stemBend;
      final headY = h - curHeight;

      canvas.drawPath(
        Path()
          ..moveTo(baseX, h)
          ..quadraticBezierTo(baseX + (stemBend * 0.40), h - (curHeight * 0.5), headX, headY),
        reedStemPaint,
      );

      _drawCrispStemLeaf(
        canvas,
        baseX + (stemBend * 0.35),
        h - (curHeight * 0.45),
        ((i % 2 == 0) ? 0.65 : -0.65) + (wind * 0.15),
        crispPaint,
      );

      if (f.type == 1) {
        _drawCattailHead(canvas, headX, headY, cattailHeadPaint, wind * 0.15);
      } else if (f.type == 2) {
        _drawLotusBlossom(canvas, headX, headY, lotusFlowerPaint);
      } else {
        _drawStarBlossom(canvas, headX, headY, (i % 2 == 0) ? lotusFlowerPaint : padPaint);
      }
    }

    // Dense grass with gentle breeze flutter
    final grassGrowth = (0.35 + (p * 0.65)).clamp(0.35, 1.0);
    final grassFlutter = wind * 4.0;

    final backGrass = Path()..moveTo(0, h);
    for (double x = 0; x <= w; x += 6) {
      final spikeHeight = (24 + (math.sin(x * 0.08) * 12).abs()) * grassGrowth + (16 * p);
      backGrass.lineTo(x + 3 + grassFlutter, h - spikeHeight);
      backGrass.lineTo(x + 6, h);
    }
    backGrass.close();
    canvas.drawPath(backGrass, Paint()..color = const Color(0xFF046249).withValues(alpha: 0.85));

    final frontGrass = Path()..moveTo(0, h);
    for (double x = 0; x <= w; x += 7) {
      final spikeHeight = (20 + (math.cos(x * 0.09) * 10).abs()) * grassGrowth + (14 * p);
      frontGrass.lineTo(x + 3.5 + (grassFlutter * 1.2), h - spikeHeight);
      frontGrass.lineTo(x + 7, h);
    }
    frontGrass.close();
    canvas.drawPath(frontGrass, crispPaint);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ── WILDLIFE & ANIMAL VECTOR DRAWING HELPERS ─────────────────────────────
  // ═════════════════════════════════════════════════════════════════════════

  /// Exquisite Graceful Lakeside Deer
  void _drawGracefulLakesideDeer(Canvas canvas, double x, double y, double scale, Paint paint) {
    if (scale <= 0.05) return;
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale, scale);

    final deerPath = Path()
      ..moveTo(0, 0)
      ..lineTo(1.2, 0)
      ..lineTo(1.8, -8)
      ..lineTo(1.5, -14)
      ..lineTo(3.2, -18)
      ..quadraticBezierTo(6.0, -21.0, 6.8, -25.0)
      ..quadraticBezierTo(7.2, -29.0, 9.5, -34.0)
      ..quadraticBezierTo(10.5, -36.0, 13.0, -36.5)
      ..lineTo(13.2, -37.8)
      ..quadraticBezierTo(10.5, -38.5, 9.0, -39.5)
      ..quadraticBezierTo(8.5, -44.5, 9.2, -45.5)
      ..quadraticBezierTo(7.8, -42.0, 6.8, -39.0)
      ..quadraticBezierTo(6.0, -43.0, 6.5, -44.5)
      ..quadraticBezierTo(5.5, -41.5, 4.8, -37.5)
      ..quadraticBezierTo(4.0, -32.0, 2.0, -27.0)
      ..quadraticBezierTo(-2.0, -25.5, -6.0, -25.0)
      ..quadraticBezierTo(-10.0, -24.5, -12.5, -21.0)
      ..quadraticBezierTo(-14.5, -23.0, -15.5, -21.5)
      ..quadraticBezierTo(-14.0, -19.5, -12.5, -18.5)
      ..quadraticBezierTo(-11.5, -15.0, -11.0, -12.0)
      ..lineTo(-12.5, -5.0)
      ..lineTo(-13.0, 0)
      ..lineTo(-11.8, 0)
      ..lineTo(-11.0, -5.0)
      ..lineTo(-9.8, -11.5)
      ..quadraticBezierTo(-6.0, -16.0, -1.0, -16.5)
      ..lineTo(-1.5, -8.0)
      ..lineTo(-2.2, 0)
      ..lineTo(-1.2, 0)
      ..lineTo(-0.5, -8.0)
      ..lineTo(0, -14.0)
      ..close();

    canvas.drawPath(deerPath, paint);

    final hornPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final horn = Path()
      ..moveTo(8.5, -39.5)
      ..quadraticBezierTo(10.0, -44.0, 12.5, -46.0);
    canvas.drawPath(horn, hornPaint);

    final ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawOval(Rect.fromCenter(center: const Offset(-5, 0.5), width: 18, height: 3), ripplePaint);

    canvas.restore();
  }

  /// Majestic Royal Stag
  void _drawMajesticRoyalStag(Canvas canvas, double x, double y, double scale, Paint paint) {
    if (scale <= 0.05) return;
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale, scale);

    final stagBody = Path()
      ..moveTo(12.0, 0)
      ..lineTo(10.8, 0)
      ..lineTo(10.0, -10.0)
      ..lineTo(13.0, -16.5)
      ..lineTo(11.5, -22.5)
      ..quadraticBezierTo(14.5, -24.5, 15.2, -23.0)
      ..quadraticBezierTo(13.2, -21.5, 11.0, -21.5)
      ..quadraticBezierTo(3.0, -22.5, -2.0, -21.0)
      ..quadraticBezierTo(-5.0, -24.5, -7.5, -30.0)
      ..lineTo(-8.5, -34.0)
      ..lineTo(-9.5, -37.5)
      ..lineTo(-7.8, -35.0)
      ..lineTo(-13.0, -33.5)
      ..lineTo(-13.8, -31.5)
      ..lineTo(-12.0, -30.5)
      ..quadraticBezierTo(-8.0, -28.0, -5.5, -22.0)
      ..quadraticBezierTo(-4.0, -16.0, -3.5, -13.0)
      ..lineTo(-3.5, 0)
      ..lineTo(-2.2, 0)
      ..lineTo(-2.2, -12.0)
      ..quadraticBezierTo(3.5, -15.0, 8.5, -15.0)
      ..lineTo(9.5, 0)
      ..lineTo(10.8, 0)
      ..lineTo(9.8, -10.0)
      ..close();

    canvas.drawPath(stagBody, paint);

    final antlerPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final antlerLeft = Path()
      ..moveTo(-7.5, -34.5)
      ..quadraticBezierTo(-9.0, -42.0, -13.0, -47.0)
      ..quadraticBezierTo(-16.0, -51.0, -19.0, -50.0);
    canvas.drawPath(antlerLeft, antlerPaint);
    canvas.drawLine(const Offset(-9.5, -39.0), const Offset(-14.0, -41.0), antlerPaint);
    canvas.drawLine(const Offset(-13.5, -46.0), const Offset(-15.5, -51.5), antlerPaint);
    canvas.drawLine(const Offset(-17.0, -49.5), const Offset(-18.5, -54.0), antlerPaint);

    final antlerRight = Path()
      ..moveTo(-6.5, -34.0)
      ..quadraticBezierTo(-7.5, -40.5, -10.5, -45.0)
      ..quadraticBezierTo(-13.0, -48.5, -15.5, -48.0);
    canvas.drawPath(antlerRight, antlerPaint..strokeWidth = 1.1);
    canvas.drawLine(const Offset(-8.0, -38.5), const Offset(-11.5, -40.5), antlerPaint);
    canvas.drawLine(const Offset(-11.0, -44.5), const Offset(-12.5, -49.0), antlerPaint);

    canvas.restore();
  }

  /// Draws a Tiered Pine Tree with natural wind sway
  /// (Base stays anchored, higher tiers lean into the breeze)
  void _drawTieredPineTree(Canvas canvas, double cx, double cy, double height, double width, Paint paint, [double windLean = 0.0]) {
    if (height <= 8) return;

    final trunkWidth = width * 0.16;
    final trunkPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx - (trunkWidth * 0.5), cy, trunkWidth, height * 0.20), trunkPaint);

    // Tip deflection based on wind
    final tipDeflection = windLean * 9.0;
    final path = Path()..moveTo(cx + tipDeflection, cy - height);

    final tiers = 5;
    for (int i = 0; i < tiers; i++) {
      final tierFactor = 1.0 - (i / tiers);
      final tierWind = windLean * 8.0 * tierFactor;

      final tierTopY = cy - height + (i * (height * 0.18));
      final tierBotY = tierTopY + (height * 0.25);
      final tierHalfW = (i + 1) * (width * 0.10);

      path.lineTo(cx + tierWind + (tierHalfW * 0.5), tierTopY + (height * 0.08));
      path.lineTo(cx + tierWind + tierHalfW, tierBotY);
      if (i < tiers - 1) {
        path.lineTo(cx + tierWind + (tierHalfW * 0.55), tierBotY - (height * 0.05));
      }
    }

    path.lineTo(cx, cy);

    for (int i = tiers - 1; i >= 0; i--) {
      final tierFactor = 1.0 - (i / tiers);
      final tierWind = windLean * 8.0 * tierFactor;

      final tierTopY = cy - height + (i * (height * 0.18));
      final tierBotY = tierTopY + (height * 0.25);
      final tierHalfW = (i + 1) * (width * 0.10);

      path.lineTo(cx + tierWind - tierHalfW, tierBotY);
      path.lineTo(cx + tierWind - (tierHalfW * 0.5), tierTopY + (height * 0.08));
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  /// Draws a Traditional Wooden Sampan / Canoe with subtle rocking
  void _drawTraditionalBoat(Canvas canvas, double cx, double cy, double scale, [double rockAngle = 0.0]) {
    if (scale <= 0.1) return;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale, scale);
    if (rockAngle != 0.0) canvas.rotate(rockAngle);

    final boatPaint = Paint()
      ..color = const Color(0xFF01241A).withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;

    final hull = Path()
      ..moveTo(-16, 0)
      ..quadraticBezierTo(-12, 4, 0, 4.5)
      ..quadraticBezierTo(12, 4, 18, 0)
      ..lineTo(14, 0.5)
      ..quadraticBezierTo(0, 2, -13, 0.5)
      ..close();
    canvas.drawPath(hull, boatPaint);

    final man = Path()
      ..moveTo(-2, 0)
      ..lineTo(-2, -6)
      ..quadraticBezierTo(0, -9, 2, -6)
      ..lineTo(2, 0)
      ..close();
    canvas.drawPath(man, boatPaint);
    canvas.drawCircle(const Offset(0, -9), 2.2, boatPaint);
    canvas.drawLine(
      const Offset(-4, -8),
      const Offset(4, -8),
      Paint()..color = boatPaint.color..strokeWidth = 1.0,
    );

    canvas.drawLine(
      const Offset(1, -6),
      const Offset(8, 5),
      Paint()..color = boatPaint.color..strokeWidth = 1.0,
    );

    canvas.drawCircle(const Offset(16, -3), 2.0, Paint()..color = const Color(0xFFFDE047));
    canvas.drawCircle(
      const Offset(16, -3),
      5.0,
      Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.35),
    );

    canvas.drawCircle(
      const Offset(16, 2.5),
      1.5,
      Paint()..color = const Color(0xFFFDE047).withValues(alpha: 0.35),
    );

    canvas.restore();
  }

  /// Draws a soaring mountain eagle
  void _drawSoaringEagle(Canvas canvas, double cx, double cy, double span, double angle, Paint paint) {
    if (span <= 2) return;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    final eagle = Path()
      ..moveTo(0, -span * 0.18)
      ..quadraticBezierTo(span * 0.32, -span * 0.30, span * 0.50, -span * 0.12)
      ..quadraticBezierTo(span * 0.46, -span * 0.04, span * 0.40, span * 0.02)
      ..quadraticBezierTo(span * 0.24, -span * 0.02, span * 0.08, span * 0.10)
      ..lineTo(span * 0.10, span * 0.24)
      ..lineTo(0, span * 0.18)
      ..lineTo(-span * 0.10, span * 0.24)
      ..lineTo(-span * 0.08, span * 0.10)
      ..quadraticBezierTo(-span * 0.24, -span * 0.02, -span * 0.40, span * 0.02)
      ..quadraticBezierTo(-span * 0.46, -span * 0.04, -span * 0.50, -span * 0.12)
      ..quadraticBezierTo(-span * 0.32, -span * 0.30, 0, -span * 0.18)
      ..close();

    canvas.drawPath(eagle, paint);
    canvas.restore();
  }

  /// Draws a Cattail Head with wind lean
  void _drawCattailHead(Canvas canvas, double cx, double cy, Paint paint, [double lean = 0.0]) {
    canvas.save();
    canvas.translate(cx, cy);
    if (lean != 0.0) canvas.rotate(lean);

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-2.4, -8.0, 4.8, 16.0), const Radius.circular(2.4)),
      paint,
    );
    canvas.drawLine(
      const Offset(0, -8),
      const Offset(0, -14),
      Paint()..color = paint.color..strokeWidth = 1.0,
    );
    canvas.restore();
  }

  /// Gentle golden crescent Hilal
  void _drawCrescentHilal(Canvas canvas, double cx, double cy, double r) {
    if (r <= 2) return;

    final glowPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 1.8, glowPaint);

    final moon = Path()
      ..addArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -math.pi * 0.45, math.pi * 0.9)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx + (r * 0.42), cy), radius: r * 0.88),
        math.pi * 0.45,
        -math.pi * 0.9,
        false,
      )
      ..close();

    canvas.drawPath(moon, Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.80));
  }

  /// Floating Alpine Mist Particles & Golden Lake Glow
  void _drawAlpineMistParticles(Canvas canvas, double w, double h, double intensity) {
    final sporePaint = Paint()..style = PaintingStyle.fill;

    final spots = [
      [Offset(w * 0.10 + (wind * 5.0), h * 0.36), 0.70, 2.5],
      [Offset(w * 0.20 + (wind * 4.0), h * 0.46), 0.55, 2.0],
      [Offset(w * 0.30 + (wind * 6.0), h * 0.34), 0.80, 3.0],
      [Offset(w * 0.42 + (wind * 3.5), h * 0.48), 0.50, 1.8],
      [Offset(w * 0.54 + (wind * 5.5), h * 0.38), 0.65, 2.4],
      [Offset(w * 0.66 + (wind * 4.0), h * 0.46), 0.55, 2.0],
      [Offset(w * 0.74 + (wind * 6.5), h * 0.32), 0.85, 3.2],
      [Offset(w * 0.84 + (wind * 4.5), h * 0.44), 0.60, 2.2],
      [Offset(w * 0.92 + (wind * 5.0), h * 0.30), 0.75, 2.8],
    ];

    for (final spot in spots) {
      final p = spot[0] as Offset;
      final alphaFactor = spot[1] as double;
      final baseRadius = spot[2] as double;

      final alpha = alphaFactor * intensity;
      final radius = baseRadius * intensity;

      sporePaint.color = const Color(0xFFFDE047).withValues(alpha: (alpha * 0.45).clamp(0.0, 1.0));
      canvas.drawCircle(p, radius * 2.5, sporePaint);

      sporePaint.color = const Color(0xFFF59E0B).withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(p, radius, sporePaint);
    }
  }

  // ── FLORA & SHRUB DRAWING HELPERS ──
  void _drawFernFrond(Canvas canvas, double rootX, double rootY, double leanAngle, double length, Paint paint) {
    if (length <= 4) return;
    canvas.save();
    canvas.translate(rootX, rootY);
    canvas.rotate(leanAngle);

    final spinePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset.zero, Offset(0, -length), spinePaint);

    final leafletPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (double dy = 12; dy <= length - 6; dy += 7) {
      final leafLen = (1.0 - (dy / length)) * 14.0 + 3.0;
      canvas.drawLine(Offset(0, -dy), Offset(-leafLen, -dy - 4), leafletPaint);
      canvas.drawLine(Offset(0, -dy), Offset(leafLen, -dy - 4), leafletPaint);
    }

    canvas.restore();
  }

  void _drawCrispStemLeaf(Canvas canvas, double x, double y, double angle, Paint paint) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    final leafPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(9, -6, 17, 0)
      ..quadraticBezierTo(9, 6, 0, 0);
    canvas.drawPath(leafPath, paint);
    canvas.restore();
  }

  void _drawStarBlossom(Canvas canvas, double cx, double cy, Paint paint) {
    for (int p = 0; p < 5; p++) {
      final angle = (p * 72) * (math.pi / 180);
      final px = cx + (math.cos(angle) * 7.5);
      final py = cy + (math.sin(angle) * 7.5);
      canvas.drawCircle(Offset(px, py), 3.5, paint);
    }
    canvas.drawCircle(Offset(cx, cy), 3.2, Paint()..color = const Color(0xFFFDE047));
  }

  void _drawLotusBlossom(Canvas canvas, double cx, double cy, Paint paint) {
    final path = Path()
      ..moveTo(cx - 10, cy + 4)
      ..quadraticBezierTo(cx - 11, cy - 4, cx - 7, cy - 8)
      ..quadraticBezierTo(cx - 3, cy - 3, cx, cy - 10)
      ..quadraticBezierTo(cx + 3, cy - 3, cx + 7, cy - 8)
      ..quadraticBezierTo(cx + 11, cy - 4, cx + 10, cy + 4)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(cx, cy + 1), 3.6, Paint()..color = Colors.white.withValues(alpha: 0.95));
  }

  @override
  bool shouldRepaint(covariant _SilhouetteGardenPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.khatmCount != khatmCount ||
        oldDelegate.wind != wind;
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../providers/auth_provider.dart';
import '../auth/auth_foyer_screen.dart';
import '../shell/app_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mandala / Rangoli background — fully programmatic, no image assets needed
// ─────────────────────────────────────────────────────────────────────────────
class _MandalaPainter extends CustomPainter {
  final double rotation;
  const _MandalaPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Deep base gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFF1C0A00),
          AtithyaColors.obsidian,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Paint helper
    Paint ringPaint(Color c, double width, {bool fill = false}) => Paint()
      ..color = c
      ..strokeWidth = width
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke;

    // Draw concentric ornamental rings
    final rings = [
      (size.width * 0.44, AtithyaColors.imperialGold.withValues(alpha: 0.18), 0.8),
      (size.width * 0.38, AtithyaColors.shimmerGold.withValues(alpha: 0.22), 0.6),
      (size.width * 0.30, AtithyaColors.burnishedGold.withValues(alpha: 0.20), 0.8),
      (size.width * 0.20, AtithyaColors.imperialGold.withValues(alpha: 0.14), 0.5),
    ];
    for (final (r, color, width) in rings) {
      canvas.drawCircle(Offset(cx, cy), r, ringPaint(color, width));
    }

    // Petal petals — 16-fold symmetry
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);
    final petalPaint = Paint()
      ..color = AtithyaColors.imperialGold.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 16; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 8);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(size.width * 0.08, -size.width * 0.06, 0, -size.width * 0.38)
        ..quadraticBezierTo(-size.width * 0.08, -size.width * 0.06, 0, 0);
      canvas.drawPath(path, petalPaint);
      canvas.restore();
    }
    canvas.restore();

    // Dots ring (counter-rotate slightly)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-rotation * 0.6);
    final dotPaint = Paint()
      ..color = AtithyaColors.shimmerGold.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 32; i++) {
      final angle = i * math.pi / 16;
      final r = size.width * 0.32;
      canvas.drawCircle(
        Offset(r * math.cos(angle), r * math.sin(angle)),
        i % 4 == 0 ? 3.5 : 1.8,
        dotPaint..color = AtithyaColors.shimmerGold.withValues(
          alpha: i % 4 == 0 ? 0.50 : 0.22,
        ),
      );
    }
    canvas.restore();

    // Fine tick marks on outer ring
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation * 0.3);
    final tickPaint = Paint()
      ..color = AtithyaColors.imperialGold.withValues(alpha: 0.30)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 72; i++) {
      final angle = i * math.pi / 36;
      final r2 = size.width * 0.44;
      final r1 = r2 - (i % 6 == 0 ? 18.0 : 9.0);
      canvas.drawLine(
        Offset(r1 * math.cos(angle), r1 * math.sin(angle)),
        Offset(r2 * math.cos(angle), r2 * math.sin(angle)),
        tickPaint,
      );
    }
    canvas.restore();

    // Corner paisley corners (top-left & bottom-right accents)
    final accentPaint = Paint()
      ..color = AtithyaColors.burnishedGold.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final corners = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    for (final c in corners) {
      canvas.drawCircle(c, size.width * 0.18, accentPaint);
      canvas.drawCircle(c, size.width * 0.12, accentPaint..color = AtithyaColors.imperialGold.withValues(alpha: 0.07));
    }
  }

  @override
  bool shouldRepaint(_MandalaPainter old) => old.rotation != rotation;
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _sequenceWait();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _sequenceWait() async {
    // Show splash for at least 2.5 s, then wait for auth check to complete
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Wait until auth is no longer loading (token validation finished)
    while (ref.read(authProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!mounted) return;
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1800),
        pageBuilder: (_, __, ___) =>
            isAuthenticated ? const AppShell() : const AuthFoyerScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Mandala background — programmatic, no assets needed
          AnimatedBuilder(
            animation: _rotationController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _MandalaPainter(rotation: _rotationController.value * 2 * math.pi),
            ),
          ),

          // Ornamental spinning ring
          Center(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (_, __) => Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(260, 260),
                  painter: _OrnamentRingPainter(),
                ),
              ),
            ),
          ),

          // Inner glow pulse
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 90 + _pulseController.value * 20,
                height: 90 + _pulseController.value * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AtithyaColors.imperialGold.withValues(alpha: 0.35 * _pulseController.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Diamond Logo mark
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AtithyaColors.imperialGold, width: 1.5),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AtithyaColors.shimmerGold,
                          AtithyaColors.burnishedGold,
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 1200.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 800.ms),
              ],
            ),
          ),

          // Staggered typography
          Positioned(
            bottom: size.height * 0.18,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // ── Calligraphic writing animation ──────────────────────────
                // TweenAnimationBuilder sweeps a left-to-right ShaderMask from
                // 0 → 1.  An Interval delay of 28 % gives ~700 ms of pause
                // before the ink starts flowing.  A gold shimmer at the
                // leading edge mimics a calligraphy pen nib.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 2800),
                  curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
                  builder: (ctx, t, child) {
                    return ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) {
                        if (t >= 0.999) {
                          // Fully revealed — solid pearl
                          return const LinearGradient(
                            colors: [AtithyaColors.pearl, AtithyaColors.pearl],
                          ).createShader(bounds);
                        }
                        // Sweep: revealed area (pearl) → nib shimmer (gold) → hidden
                        final edge = t.clamp(0.0, 1.0);
                        final fadeIn  = math.max(0.0, edge - 0.10);
                        final fadeOut = math.min(1.0, edge + 0.02);
                        return LinearGradient(
                          colors: const [
                            AtithyaColors.pearl,        // already written
                            AtithyaColors.shimmerGold,  // pen-nib sparkle
                            Color(0x00FFFFFF),           // not yet written
                          ],
                          stops: [fadeIn, edge, fadeOut],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds);
                      },
                      child: child,
                    );
                  },
                  child: Text(
                    'आतिथ्य',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSerifDevanagari(
                      fontSize: 68,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      height: 1.15,
                      color: AtithyaColors.pearl,
                      shadows: [
                        Shadow(
                          color: AtithyaColors.imperialGold.withValues(alpha: 0.60),
                          blurRadius: 48,
                        ),
                        Shadow(
                          color: AtithyaColors.shimmerGold.withValues(alpha: 0.30),
                          blurRadius: 90,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Gold divider line
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 1,
                      decoration: const BoxDecoration(gradient: AtithyaColors.goldGradient),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '✦',
                      style: TextStyle(
                        fontSize: 12,
                        color: AtithyaColors.imperialGold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 48,
                      height: 1,
                      decoration: const BoxDecoration(gradient: AtithyaColors.goldGradient),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 1200.ms, delay: 1400.ms)
                    .scaleX(begin: 0, end: 1, duration: 1200.ms, delay: 1400.ms, curve: Curves.easeOutQuart),

                const SizedBox(height: 18),

                Text(
                  'आतिथ्य  ·  THE ART OF ROYAL HOSPITALITY',
                  textAlign: TextAlign.center,
                  style: AtithyaTypography.labelMicro.copyWith(
                    letterSpacing: 3.5,
                    color: AtithyaColors.ashWhite,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 2000.ms, delay: 2000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for spinning ornamental ring
class _OrnamentRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final ringPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          AtithyaColors.burnishedGold,
          AtithyaColors.shimmerGold,
          AtithyaColors.subtleGold,
          AtithyaColors.burnishedGold,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Main ring
    canvas.drawCircle(center, radius, ringPaint);

    // Tick marks every 30° (12 ticks)
    final tickPaint = Paint()
      ..color = AtithyaColors.imperialGold.withValues(alpha: 0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final isMain = i % 2 == 0;
      final outerR = radius;
      final innerR = radius - (isMain ? 14 : 7);
      final x1 = center.dx + outerR * math.cos(angle);
      final y1 = center.dy + outerR * math.sin(angle);
      final x2 = center.dx + innerR * math.cos(angle);
      final y2 = center.dy + innerR * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2),
          tickPaint..color = isMain
              ? AtithyaColors.imperialGold.withValues(alpha: 0.9)
              : AtithyaColors.subtleGold.withValues(alpha: 0.4));
    }

    // Inner dotted ring
    final dotPaint = Paint()
      ..color = AtithyaColors.imperialGold.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 48; i++) {
      final angle = i * math.pi / 24;
      final r = radius - 24;
      canvas.drawCircle(
        Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle)),
        1.5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

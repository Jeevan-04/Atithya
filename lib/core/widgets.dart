import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'colors.dart';

// ─── Global Shimmer Widget ───────────────────────────────────────────────────

class AtithyaShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AtithyaShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AtithyaColors.darkSurface,
      highlightColor: AtithyaColors.surfaceElevated,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AtithyaColors.darkSurface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerEstateCard extends StatelessWidget {
  const ShimmerEstateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AtithyaColors.darkSurface,
      highlightColor: const Color(0xFF2A2034),
      period: const Duration(milliseconds: 1400),
      child: Container(
        decoration: BoxDecoration(
          color: AtithyaColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AtithyaColors.surfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 10, width: 80,
                      decoration: BoxDecoration(color: AtithyaColors.surfaceElevated, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 10),
                  Container(height: 16, width: 180,
                      decoration: BoxDecoration(color: AtithyaColors.surfaceElevated, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120,
                      decoration: BoxDecoration(color: AtithyaColors.surfaceElevated, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Global Glass Container ──────────────────────────────────────────────────

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final double blur;
  final double borderRadius;
  final Color? color;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.blur = 20,
    this.borderRadius = 16,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AtithyaColors.obsidian.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: AtithyaColors.imperialGold.withValues(alpha: 0.18),
                  width: 1,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Shine Sweep Button ──────────────────────────────────────────────────────

class GoldButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final Widget? icon;

  const GoldButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.height = 58,
    this.icon,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _shineController;
  late Animation<double> _shineAnim;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: false);
    _shineAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _shineAnim,
        builder: (_, __) {
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [
                  AtithyaColors.burnishedGold,
                  AtithyaColors.imperialGold,
                  AtithyaColors.shimmerGold,
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: AtithyaColors.obsidian, strokeWidth: 1.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 10)],
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3.5,
                                color: AtithyaColors.obsidian,
                              ),
                            ),
                          ],
                        ),
                ),
                // Shine sweep
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Transform.translate(
                      offset: Offset(_shineAnim.value * 200, 0),
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

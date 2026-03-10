import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/colors.dart';
import '../../providers/locale_provider.dart';
import '../concierge/concierge_modal.dart';
import '../discover/discover_screen.dart';
import '../estates/estates_screen.dart';
import '../itineraries/itineraries_screen.dart';
import '../sanctum/sanctum_screen.dart';

// Global provider to programmatically switch tabs
class _ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void switchTo(int tab) => state = tab;
}
final shellTabProvider = NotifierProvider<_ShellTabNotifier, int>(_ShellTabNotifier.new);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _moveCtrl;
  late Animation<double> _moveAnim;
  double _fromFrac = 0.125;   // fraction: center-x of tab / total-width
  double _toFrac   = 0.125;

  static const List<_NavIconItem> _navIcons = [
    _NavIconItem(icon: Icons.explore_outlined,        activeIcon: Icons.explore,            key: 'nav.discover'),
    _NavIconItem(icon: Icons.domain_outlined,         activeIcon: Icons.domain,             key: 'nav.palaces'),
    _NavIconItem(icon: Icons.card_travel_outlined,    activeIcon: Icons.card_travel,        key: 'nav.journeys'),
    _NavIconItem(icon: Icons.account_circle_outlined, activeIcon: Icons.account_circle,     key: 'nav.sanctum'),
  ];

  final List<Widget> _screens = const [
    DiscoverScreen(),
    EstatesScreen(),
    ItinerariesScreen(),
    SanctumScreen(),
  ];

  // fraction = (index + 0.5) / 4  →  center of each fourth slot
  static double _fracFor(int i) => (i + 0.5) / 4;

  @override
  void initState() {
    super.initState();
    _moveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _moveAnim = CurvedAnimation(parent: _moveCtrl, curve: Curves.easeOutQuart);
  }

  @override
  void dispose() {
    _moveCtrl.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    _fromFrac = _fracFor(_currentIndex);
    _toFrac   = _fracFor(index);
    setState(() => _currentIndex = index);
    _moveCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(shellTabProvider, (_, next) {
      if (next != _currentIndex) _onTabTap(next);
    });

    final locale = ref.watch(localeProvider);
    final navItems = _navIcons
        .map((e) => _NavItem(icon: e.icon, activeIcon: e.activeIcon, label: locale.t(e.key)))
        .toList();

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      extendBody: true,           // screens render behind the floating nav
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _FloatingNotchNav(
        items: navItems,
        currentIndex: _currentIndex,
        fromFrac: _fromFrac,
        toFrac: _toFrac,
        moveAnim: _moveAnim,
        onTap: _onTabTap,
        onCircleLongPress: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.transparent,
          builder: (_) => const ConciergeModal(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating-Notch Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingNotchNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final double fromFrac;
  final double toFrac;
  final Animation<double> moveAnim;
  final ValueChanged<int> onTap;
  final VoidCallback onCircleLongPress;

  // ── Layout logic ────────────────────────────────────────────────────────────
  // The gold circle's centre sits exactly on the bar's top edge (circleRelY = 0).
  // Upper half (circleR px) rises above the bar into the extra SizedBox space.
  // Lower half (circleR px) sits inside the notch cut into the bar top.
  //
  // Icons are fixed in the bar at y ≈ iconTopPad from bar top — they sit inside
  // the lower half of the gold circle.  Inactive icons show at the same y; the
  // circle simply isn't there behind them.
  //
  // Z-order (back→front):  bar (notch painted) → gold circle → icon row
  static const double _navH        = 68.0;  // bar height
  static const double _circleR     = 28.0;  // gold circle radius
  // _circleAbove: circle centre floats this many px ABOVE bar top.
  // 6 px = barely lifted — feels grounded yet floating.
  static const double _circleAbove = 6.0;
  // notchGapR radius for the inward U arc (clockwise = curves INTO the bar).
  // Visible gap between circle bottom edge and the arc = notchGapR - circleR = 10 px.
  // Arc dips (notchGapR - circleAbove) = 32 px into the 68 px bar — wide smooth valley.
  // Notch width at bar-top = 2 * sqrt(38² - 6²) ≈ 75 px.
  static const double _notchGapR   = 38.0;

  const _FloatingNotchNav({
    required this.items,
    required this.currentIndex,
    required this.fromFrac,
    required this.toFrac,
    required this.moveAnim,
    required this.onTap,
    required this.onCircleLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final totalH = _navH + bottom;

    return SizedBox(
      height: totalH + _circleR + _circleAbove + 4,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final W = constraints.maxWidth;

          return AnimatedBuilder(
            animation: moveAnim,
            builder: (_, __) {
              final frac = fromFrac + (toFrac - fromFrac) * moveAnim.value;
              final cx   = frac * W;

              return Stack(
                clipBehavior: Clip.none,
                children: [

                  // ── [1] Notched bar (back) ─────────────────────────────────
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    height: totalH,
                    child: ClipPath(
                      clipper: _NotchClipper(
                          cx: cx, notchGapR: _notchGapR,
                          circleRelY: -_circleAbove, totalH: totalH),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                        child: CustomPaint(
                          painter: _NotchBarPainter(
                              cx: cx, notchGapR: _notchGapR,
                              circleRelY: -_circleAbove, totalH: totalH),
                        ),
                      ),
                    ),
                  ),

                  // ── [2] Glassmorphism circle — slides to active slot ────────
                  // Centre is _circleAbove px above bar top.
                  // extendBody:true means screen content shows through the gap
                  // and through the frosted-glass circle itself.
                  Positioned(
                    bottom: bottom + _navH + _circleAbove - _circleR,
                    left: cx - _circleR,
                    width:  _circleR * 2,
                    height: _circleR * 2,
                    child: GestureDetector(
                      onTap: () => onTap(currentIndex),
                      onLongPress: onCircleLongPress,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // dark-gold frosted glass: mostly transparent
                              gradient: RadialGradient(
                                colors: [
                                  AtithyaColors.imperialGold.withValues(alpha: 0.22),
                                  AtithyaColors.obsidian.withValues(alpha: 0.45),
                                ],
                                stops: const [0.0, 1.0],
                              ),
                              border: Border.all(
                                color: AtithyaColors.shimmerGold.withValues(alpha: 0.70),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AtithyaColors.imperialGold.withValues(alpha: 0.30),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),  // closes Positioned [2] glassmorphism circle

                  // ── [3] Active icon overlay — pinned to circle centre ──────
                  // Icon centre = circle centre = bottom + navH + circleAbove.
                  // Subtract half icon size (11) so widget is vertically centred.
                  Positioned(
                    bottom: bottom + _navH + _circleAbove - 11,
                    left: cx - 11,
                    width: 22,
                    height: 22,
                    child: IgnorePointer(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Icon(
                          items[currentIndex].activeIcon,
                          key: ValueKey(currentIndex),
                          color: AtithyaColors.shimmerGold,
                          size: 22,
                        ),
                      ),
                    ),
                  ),  // closes Positioned [3] active icon overlay

                  // ── [4] Icon + label row — ALL icons at fixed bar positions ─
                  // Active icon is INVISIBLE here (the overlay above handles it).
                  // Only labels and inactive icons render in this layer.
                  Positioned(
                    bottom: bottom, left: 0, right: 0,
                    height: _navH,
                    child: Row(
                      children: List.generate(items.length, (i) {
                        final isActive = i == currentIndex;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onTap(i),
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              height: _navH,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Spacer(),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 220),
                                    opacity: isActive ? 0.0 : 0.45,
                                    child: Icon(
                                      items[i].icon,
                                      color: AtithyaColors.ashWhite,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 220),
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      letterSpacing: 0.9,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? AtithyaColors.imperialGold
                                          : AtithyaColors.ashWhite.withValues(alpha: 0.35),
                                    ),
                                    child: Text(items[i].label.toUpperCase()),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter — draws the curved notch bar background
// ─────────────────────────────────────────────────────────────────────────────

class _NotchBarPainter extends CustomPainter {
  final double cx;           // notch centre x
  final double notchGapR;    // arc radius (circleR + gap)
  final double circleRelY;   // circle centre y relative to bar top (negative = above)
  final double totalH;

  const _NotchBarPainter({
    required this.cx,
    required this.notchGapR,
    required this.circleRelY,
    required this.totalH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    // Bar fill — semi-transparent dark for glassmorphism
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xCC090C12)   // ~80 % opaque deep navy
        ..style = PaintingStyle.fill,
    );

    // Top gold border line (drawn only outside the notch)
    final borderPaint = Paint()
      ..color = AtithyaColors.imperialGold.withValues(alpha: 0.22)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  Path _buildPath(Size size) {
    const cornerR = 18.0;
    final w = size.width;
    final h = size.height;

    // ── Semicircular notch geometry ──────────────────────────────────────────
    // The notch is a true semicircle of radius notchGapR dipping into the bar.
    // We add a smooth cubic "shoulder" on each side so the flat bar top blends
    // into the semicircle tangentially — no kink at the join point.
    //
    // Semicircle centre = (cx, 0). It intersects y=0 at x = cx ± notchGapR.
    // Shoulder span: each shoulder is `sh` px wide on the bar-top line, starting
    // `sh` px outside the semicircle opening.
    final R  = notchGapR;           // semicircle radius (38 px)
    const sh = 12.0;               // shoulder blend width in px

    // Flat bar meets shoulder at these x positions:
    final sL = (cx - R - sh).clamp(0.0, w);  // left  shoulder start
    final sR = (cx + R + sh).clamp(0.0, w);  // right shoulder end
    // Semicircle arc endpoints (on bar-top line, y=0):
    final arcL = (cx - R).clamp(0.0, w);
    final arcR = (cx + R).clamp(0.0, w);

    final path = Path();

    // ── Top-left rounded corner ─────────────────────────────────────────────
    final leftCornerEnd = math.min(cornerR, sL);
    path.moveTo(0, cornerR);
    path.quadraticBezierTo(0, 0, leftCornerEnd, 0);
    if (sL > leftCornerEnd) path.lineTo(sL, 0);

    // ── Left shoulder: flat bar → tangent into semicircle ──────────────────
    // Cubic: from (sL,0) depart horizontally, arrive at (arcL,0) horizontally.
    // CP1 nudges inward along the bar top; CP2 mirrors from the arc side.
    path.cubicTo(sL + sh * 0.6, 0, arcL - sh * 0.1, 0, arcL, 0);

    // ── True semicircle (clockwise=false → dips downward into bar) ─────────
    path.arcToPoint(
      Offset(arcR, 0),
      radius: Radius.circular(R),
      clockwise: false,
    );

    // ── Right shoulder: tangent out of semicircle → flat bar ───────────────
    path.cubicTo(arcR + sh * 0.1, 0, sR - sh * 0.6, 0, sR, 0);

    // ── Top-right rounded corner ────────────────────────────────────────────
    final rightCornerStart = math.max(w - cornerR, sR);
    if (rightCornerStart > sR) path.lineTo(rightCornerStart, 0);
    path.quadraticBezierTo(w, 0, w, cornerR);

    // ── Sides + bottom ──────────────────────────────────────────────────────
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_NotchBarPainter old) =>
      old.cx != cx || old.notchGapR != notchGapR || old.circleRelY != circleRelY;
}

// ─────────────────────────────────────────────────────────────────────────────
// Clipper — clips the backdrop blur to the notch bar shape
// ─────────────────────────────────────────────────────────────────────────────

class _NotchClipper extends CustomClipper<Path> {
  final double cx;
  final double notchGapR;
  final double circleRelY;
  final double totalH;

  const _NotchClipper({
    required this.cx,
    required this.notchGapR,
    required this.circleRelY,
    required this.totalH,
  });

  @override
  Path getClip(Size size) {
    return _NotchBarPainter(
      cx: cx, notchGapR: notchGapR, circleRelY: circleRelY, totalH: totalH,
    )._buildPath(size);
  }

  @override
  bool shouldReclip(_NotchClipper old) =>
      old.cx != cx || old.circleRelY != circleRelY;
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Holds icon data + translation key (label resolved at build time).
class _NavIconItem {
  final IconData icon;
  final IconData activeIcon;
  final String key;
  const _NavIconItem({required this.icon, required this.activeIcon, required this.key});
}

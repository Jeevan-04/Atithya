import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../dossier/dossier_screen.dart';
import '../concierge/concierge_modal.dart';
import '../profile/profile_sheet.dart';
import '../../providers/estate_provider.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final page = (_pageController.page ?? 0).round();
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fallback gradient backgrounds when no heroImage
  List<Color> _fallbackGradient(int index) {
    const gradients = [
      [Color(0xFF1A237E), Color(0xFF4A148C)],
      [Color(0xFF880E4F), Color(0xFFB71C1C)],
      [Color(0xFF0D47A1), Color(0xFF006064)],
      [Color(0xFF1B5E20), Color(0xFF006064)],
      [Color(0xFFBF360C), Color(0xFFE65100)],
    ];
    return gradients[index % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final estateState = ref.watch(estateProvider);

    if (estateState.isLoading) {
      return Scaffold(
        backgroundColor: AtithyaColors.obsidian,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  color: AtithyaColors.imperialGold,
                  strokeWidth: 0.8,
                ),
              ),
              const SizedBox(height: 32),
              Text('CURATING THE COLLECTION',
                  style: AtithyaTypography.labelMicro.copyWith(
                    color: AtithyaColors.imperialGold,
                    letterSpacing: 4,
                  )),
            ],
          ).animate().fadeIn(duration: 1200.ms),
        ),
      );
    }

    if (estateState.error != null) {
      return Scaffold(
        backgroundColor: AtithyaColors.obsidian,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_outlined, color: AtithyaColors.ashWhite, size: 40),
              const SizedBox(height: 24),
              Text('UNABLE TO REACH THE PALACE',
                  style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.errorRed)),
              const SizedBox(height: 12),
              Text('Ensure the backend service is running.',
                  style: AtithyaTypography.caption),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => ref.read(estateProvider.notifier).fetchEstates(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text('RETRY', style: AtithyaTypography.labelSmall),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final estates = estateState.estates;

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Stack(
        children: [
          // MAIN SCROLL
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            itemCount: estates.length,
            itemBuilder: (context, index) {
              return _buildEstatePage(estates[index], index);
            },
          ),

          // TOP NAV — transparent, floating
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Profile access
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ProfileSheet(),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AtithyaColors.surfaceElevated,
                        border: Border.all(
                            color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.person_outline,
                          color: AtithyaColors.imperialGold, size: 18),
                    ),
                  ),

                  // Centre: App wordmark
                  Text('आतिथ्य',
                      style: AtithyaTypography.labelGold.copyWith(
                        letterSpacing: 3,
                        fontSize: 13,
                      )),

                  // Right: Concierge (AI)
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      useSafeArea: false,
                      builder: (_) => const ConciergeModal(),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AtithyaColors.burnishedGold, AtithyaColors.imperialGold],
                        ),
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          color: AtithyaColors.obsidian, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right-side scroll indicators (vertical dots)
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  (estates.length > 8 ? 8 : estates.length),
                  (i) {
                    final isActive = i == (_currentPage % (estates.length > 8 ? 8 : estates.length));
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      width: isActive ? 2.5 : 1.5,
                      height: isActive ? 24 : 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AtithyaColors.imperialGold
                            : AtithyaColors.ashWhite.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatePage(Map<String, dynamic> estate, int index) {
    final heroImage = (estate['heroImage'] as String?) ?? '';
    final category = estate['category'] ?? '';
    final price = estate['basePrice'] ?? 0;
    final fallback = _fallbackGradient(index);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1000),
          reverseTransitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => DossierScreen(estate: estate, index: index),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
            child: child,
          ),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero image from DB, fallback gradient
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double offset = 0;
              if (_pageController.hasClients && _pageController.position.haveDimensions) {
                offset = (_pageController.page! - index).clamp(-1.0, 1.0);
              }
              if (heroImage.isNotEmpty) {
                return Hero(
                  tag: 'hero_image_$index',
                  child: CachedNetworkImage(
                    imageUrl: heroImage,
                    fit: BoxFit.cover,
                    alignment: Alignment(0, offset * 0.4),
                    placeholder: (_, __) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: fallback,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: fallback,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return Hero(
                tag: 'hero_image_$index',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: fallback,
                    ),
                  ),
                ),
              );
            },
          ),

          // Multi-layer gradient for richness
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00080A0E),
                  Color(0x44080A0E),
                  Color(0xCC080A0E),
                  Color(0xFF080A0E),
                ],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),

          // Left maroon accent
          Positioned(
            left: 0,
            bottom: 0,
            top: 0,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AtithyaColors.royalMaroon.withValues(alpha: 0.6),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Bottom content overlay
          Positioned(
            bottom: 80,
            left: 32,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AtithyaColors.royalMaroon.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: AtithyaTypography.labelMicro.copyWith(
                      color: AtithyaColors.shimmerGold,
                      fontSize: 9,
                      letterSpacing: 3,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: 0.4, end: 0, duration: 800.ms, curve: Curves.easeOutQuart),

                const SizedBox(height: 14),

                // Location
                Text(
                  (estate['location'] ?? '').toUpperCase(),
                  style: AtithyaTypography.labelMicro.copyWith(
                    color: AtithyaColors.imperialGold,
                    letterSpacing: 3.5,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 1000.ms, delay: 100.ms)
                    .slideY(begin: 0.4, end: 0, duration: 1000.ms, delay: 100.ms),

                const SizedBox(height: 12),

                // Title
                Hero(
                  tag: 'hero_title_$index',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      estate['title'] ?? 'Estate',
                      style: AtithyaTypography.displayLarge.copyWith(
                        height: 1.05,
                        shadows: [
                          Shadow(
                            color: AtithyaColors.obsidian.withValues(alpha: 0.8),
                            blurRadius: 20,
                          )
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 1200.ms, delay: 200.ms)
                    .slideX(begin: -0.08, end: 0, duration: 1200.ms, delay: 200.ms, curve: Curves.easeOutQuart),

                const SizedBox(height: 20),

                // Price + CTA row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'from ',
                      style: AtithyaTypography.caption.copyWith(color: AtithyaColors.ashWhite),
                    ),
                    Text(
                      '₹${_fmtPrice(price)}',
                      style: AtithyaTypography.price,
                    ),
                    Text(
                      ' / night',
                      style: AtithyaTypography.caption.copyWith(color: AtithyaColors.ashWhite),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'DOSSIER →',
                        style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.imperialGold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 1200.ms, delay: 600.ms),
              ],
            ),
          ),

          // Page number
          Positioned(
            bottom: 40,
            right: 32,
            child: Text(
              '${(index + 1).toString().padLeft(2, '0')} / ${estateState.estates.length.toString().padLeft(2, '0')}',
              style: AtithyaTypography.caption.copyWith(
                color: AtithyaColors.ashWhite.withValues(alpha: 0.5),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  EstateState get estateState => ref.read(estateProvider);

  String _fmtPrice(dynamic p) {
    final n = (p as num?)?.toInt() ?? 0;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}

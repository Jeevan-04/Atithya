import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// Web-only imports — app targets Flutter web exclusively
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop_unsafe';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/widgets.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/auth_foyer_screen.dart';
import '../booking/booking_flow_screen.dart';
import '../concierge/concierge_modal.dart';

// Facility icon map
const _facilityIcons = {
  'Pool': Icons.pool_outlined,
  'Spa': Icons.spa_outlined,
  'Helipad': Icons.flight_land_outlined,
  'Butler': Icons.room_service_outlined,
  'Kitchen': Icons.kitchen_outlined,
  'Garden': Icons.eco_outlined,
  'Chauffeur': Icons.directions_car_outlined,
  'Cultural': Icons.museum_outlined,
  'Heritage Tour': Icons.account_balance_outlined,
  'Yoga': Icons.self_improvement_outlined,
  'Beach Access': Icons.beach_access_outlined,
  'Surfing': Icons.surfing_outlined,
  'Diving': Icons.scuba_diving_outlined,
  'Trekking': Icons.hiking_outlined,
  'Wildlife Safari': Icons.pets_outlined,
  'Bonfire': Icons.local_fire_department_outlined,
  'Mountain View': Icons.landscape_outlined,
  'Skiing': Icons.downhill_skiing_outlined,
  'Art Gallery': Icons.art_track_outlined,
  'Library': Icons.local_library_outlined,
  'Wine Cellar': Icons.wine_bar_outlined,
};

class DossierScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> estate;
  final int index;
  const DossierScreen({super.key, required this.estate, required this.index});

  @override
  ConsumerState<DossierScreen> createState() => _DossierScreenState();
}

class _DossierScreenState extends ConsumerState<DossierScreen>
    with SingleTickerProviderStateMixin {
  late PageController _imagePageCtrl;
  int _currentImageIndex = 0;
  bool _storyExpanded = false;
  late TabController _tabCtrl;
  Timer? _slideTimer;
  LocaleState _locale = const LocaleState();

  @override
  void initState() {
    super.initState();
    _imagePageCtrl = PageController();
    _imagePageCtrl.addListener(() {
      final p = (_imagePageCtrl.page ?? 0).round();
      if (p != _currentImageIndex) setState(() => _currentImageIndex = p);
    });
    _tabCtrl = TabController(length: 5, vsync: this);
    // Auto-slide every 4 seconds
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final images = _getImages();
      if (!_imagePageCtrl.hasClients || images.length < 2) return;
      final next = (_currentImageIndex + 1) % images.length;
      _imagePageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _imagePageCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  List<String> _getImages() {
    final raw = widget.estate['images'];
    if (raw is List && raw.isNotEmpty) {
      final filtered = raw
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      if (filtered.isNotEmpty) return filtered;
    }
    // Fallback: try heroImage first, then static placeholders
    final hero = widget.estate['heroImage'] as String?;
    if (hero != null && hero.isNotEmpty) return [hero, hero, hero];
    return [
      'https://images.unsplash.com/photo-1524230572899-a752b3835840?w=800',
      'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800',
      'https://images.unsplash.com/photo-1551882547-ff40c4fe799f?w=800',
    ];
  }

  List<String> _getFacilities() {
    final raw = widget.estate['facilities'];
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    _locale = ref.watch(localeProvider);
    final estate = widget.estate;
    final images = _getImages();
    final facilities = _getFacilities();
    final price = estate['basePrice'] ?? 0;
    final rating = estate['rating'] ?? 4.8;
    final reviewCount = estate['reviewCount'] ?? 120;
    final story = estate['story'] ?? '';
    final category = estate['category'] ?? '';

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Stack(
        children: [
          // ── NestedScrollView: outer scrolls header, inner scrolls tabs ──
          NestedScrollView(
            physics: kIsWeb
                ? const ClampingScrollPhysics()
                : const BouncingScrollPhysics(),
            headerSliverBuilder: (ctx, _) => [

              // ── Full-Screen Image Carousel ──────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.48,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _imagePageCtrl,
                        itemCount: images.length,
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AtithyaColors.darkSurface),
                          errorWidget: (_, __, ___) => Container(
                            color: AtithyaColors.darkSurface,
                            child: const Icon(Icons.castle_outlined, color: AtithyaColors.ashWhite, size: 48),
                          ),
                        ),
                      ),

                      // gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x55080A0E), Color(0xBB080A0E), Color(0xFF080A0E)],
                            stops: [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),

                      // Back Button
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AtithyaColors.obsidian.withValues(alpha: 0.7),
                                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: AtithyaColors.pearl, size: 16),
                            ),
                          ),
                        ),
                      ),

                      // Photo count badge
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16, right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AtithyaColors.obsidian.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1} / ${images.length}',
                            style: AtithyaTypography.caption.copyWith(color: AtithyaColors.pearl),
                          ),
                        ),
                      ),

                      // Category badge + page dots
                      Positioned(
                        bottom: 24, left: 24, right: 24,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AtithyaColors.royalMaroon,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(category.toUpperCase(),
                                  style: AtithyaTypography.labelMicro.copyWith(
                                      color: AtithyaColors.shimmerGold, fontSize: 9)),
                            ),
                            if (images.length > 1)
                            SmoothPageIndicator(
                              controller: _imagePageCtrl,
                              count: images.length,
                              effect: WormEffect(
                                dotWidth: 6, dotHeight: 6,
                                activeDotColor: AtithyaColors.imperialGold,
                                dotColor: AtithyaColors.ashWhite.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Estate Header ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((estate['city'] ?? '').toUpperCase(),
                          style: AtithyaTypography.labelMicro.copyWith(
                              color: AtithyaColors.imperialGold, letterSpacing: 3.5)).animate().fadeIn(duration: 600.ms),
                      const SizedBox(height: 8),
                      Text(estate['title'] ?? '',
                          style: AtithyaTypography.displayLarge).animate().fadeIn(duration: 800.ms, delay: 100.ms),
                      const SizedBox(height: 16),

                      // Rating + distance + verified row
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AtithyaColors.imperialGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: AtithyaColors.imperialGold, size: 14),
                                const SizedBox(width: 4),
                                Text('$rating', style: AtithyaTypography.labelSmall.copyWith(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text('($reviewCount reviews)',
                                    style: AtithyaTypography.caption.copyWith(color: AtithyaColors.ashWhite)),
                              ],
                            ),
                          ),
                          if (estate['distanceFromCity'] != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    color: AtithyaColors.ashWhite, size: 12),
                                const SizedBox(width: 4),
                                Text('${estate['distanceFromCity']}',
                                    style: AtithyaTypography.caption),
                              ],
                            ),
                          // Verified badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_outlined,
                                  color: AtithyaColors.imperialGold, size: 14),
                              const SizedBox(width: 4),
                              Text(_locale.t('dos.verified'), style: AtithyaTypography.caption.copyWith(
                                  color: AtithyaColors.imperialGold)),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(duration: 800.ms, delay: 200.ms),

                      const SizedBox(height: 28),
                      Container(height: 1,
                          decoration: const BoxDecoration(gradient: AtithyaColors.goldGradient)),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

              // ── Tab Bar (5 tabs, pinned) ──────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabCtrl,
                    indicatorColor: AtithyaColors.imperialGold,
                    indicatorWeight: 1.5,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AtithyaColors.imperialGold,
                    unselectedLabelColor: AtithyaColors.ashWhite,
                    labelStyle: AtithyaTypography.labelMicro.copyWith(letterSpacing: 2, fontSize: 10),
                    tabs: const [
                      Tab(text: 'ABOUT'),
                      Tab(text: 'CUISINE'),
                      Tab(text: 'EXPERIENCES'),
                      Tab(text: 'FACILITIES'),
                      Tab(text: 'VIRTUAL TOUR'),
                    ],
                  ),
                ),
              ),
            ],
            // ── Tab Content (inner scroll) ─────────────────
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildAboutTab(story),
                _buildCuisineTab(estate),
                _buildExperiencesTab(estate),
                _buildFacilitiesTab(facilities),
                _buildExploreTab(estate),
              ],
            ),
          ),

          // ── Floating Reserve Bar ────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  decoration: BoxDecoration(
                    color: AtithyaColors.deepMidnight.withValues(alpha: 0.94),
                    border: Border(
                      top: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Flexible(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_locale.t('dos.tariff'),
                                style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.ashWhite)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(_formatPrice(price),
                                      overflow: TextOverflow.ellipsis,
                                      style: AtithyaTypography.price.copyWith(fontSize: 26)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3, left: 4),
                                  child: Text(_locale.t('dos.perNight'), style: AtithyaTypography.caption),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final user = ref.read(authProvider).user;
                              final isGuest = user == null ||
                                  user['phoneNumber'] == 'Guest';
                              if (isGuest) {
                                _showLoginPrompt(context);
                                return;
                              }
                              Navigator.push(context,
                                MaterialPageRoute(builder: (_) => BookingFlowScreen(estate: widget.estate)));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AtithyaColors.burnishedGold, AtithyaColors.imperialGold, AtithyaColors.shimmerGold],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(_locale.t('dos.reserve'),
                                  textAlign: TextAlign.center,
                                  style: AtithyaTypography.labelSmall.copyWith(
                                      color: AtithyaColors.obsidian, fontWeight: FontWeight.w700, letterSpacing: 2)),
                            ),
                          ),
                        ),
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
  }

  void _showLoginPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: const BoxDecoration(
          color: Color(0xFF111318),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AtithyaColors.imperialGold, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36, height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AtithyaColors.imperialGold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AtithyaColors.darkSurface,
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.lock_outline, color: AtithyaColors.imperialGold, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Login Required',
                style: AtithyaTypography.displaySmall.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Please sign in or create an account to book this estate and access exclusive privileges.',
              style: AtithyaTypography.bodyElegant.copyWith(
                  color: AtithyaColors.ashWhite, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GoldButton(
              label: 'SIGN IN / CREATE ACCOUNT',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AuthFoyerScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(String story) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
      physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 16, color: AtithyaColors.royalMaroon),
              const SizedBox(width: 12),
              Text(_locale.t('dos.legacy'), style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.imperialGold, letterSpacing: 4)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _storyExpanded ? story : (story.length > 200 ? '${story.substring(0, 200)}...' : story),
            style: AtithyaTypography.bodyLarge,
          ),
          if (story.length > 200)
            GestureDetector(
              onTap: () => setState(() => _storyExpanded = !_storyExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _storyExpanded ? _locale.t('dos.showLess') : _locale.t('dos.readMore'),
                  style: AtithyaTypography.labelSmall.copyWith(fontSize: 11),
                ),
              ),
            ),
          const SizedBox(height: 32),
          // Privileges
          Row(
            children: [
              Container(width: 3, height: 16, color: AtithyaColors.royalMaroon),
              const SizedBox(width: 12),
              Text(_locale.t('dos.privileges'), style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.imperialGold, letterSpacing: 4)),
            ],
          ),
          const SizedBox(height: 16),
          ...(widget.estate['privileges'] as List<dynamic>? ?? []).map((p) =>
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AtithyaColors.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AtithyaColors.royalMaroon.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.diamond_outlined, size: 14, color: AtithyaColors.imperialGold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((p['label']?.toString() ?? '').toUpperCase(),
                            style: AtithyaTypography.labelMicro.copyWith(
                                color: AtithyaColors.imperialGold, fontSize: 9)),
                        const SizedBox(height: 3),
                        Text(p['detail']?.toString() ?? '',
                            style: AtithyaTypography.bodyElegant.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesTab(List<String> facilities) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
      physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 16, color: AtithyaColors.royalMaroon),
              const SizedBox(width: 12),
              Text(_locale.t('dos.amenities'),
                  style: AtithyaTypography.labelMicro.copyWith(
                      color: AtithyaColors.imperialGold, letterSpacing: 4)),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: facilities.map((f) {
              final icon = _facilityIcons[f] ?? Icons.star_outline;
              return Container(
                decoration: BoxDecoration(
                  color: AtithyaColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AtithyaColors.royalMaroon.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AtithyaColors.imperialGold, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(f,
                        style: AtithyaTypography.caption.copyWith(fontSize: 10),
                        textAlign: TextAlign.center, maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Cuisine Tab ─────────────────────────────────────────────────────────
  Widget _buildCuisineTab(Map<String, dynamic> estate) {
    final menuItems = [
      {'category': 'BREAKFAST', 'items': [
        {'name': 'Maharaja Morning Platter', 'desc': 'Handpicked seasonal fruits from palace gardens, accompanied by Rajasthani bhapa doi, saffron lassi and royal grain porridge', 'tag': 'Signature', 'price': '₹ 2,800'},
        {'name': 'Forest Honey & Ancient Grain Toast', 'desc': 'Artisan sourdough with wild forest honey, cultured butter and a selection of homemade preserves', 'tag': 'Vegetarian', 'price': '₹ 1,600'},
        {'name': 'Heritage Egg Ceremony', 'desc': 'Farm-fresh eggs prepared four ways with truffle toast, herb oil and a glass of cold-pressed pomegranate', 'tag': 'Chef\'s Choice', 'price': '₹ 2,200'},
      ]},
      {'category': 'ROYAL MAINS', 'items': [
        {'name': 'Dum Pukht Biryani', 'desc': 'Slow-cooked for six hours in a sealed vessel over charcoal, with aged basmati, rose petals and silver leaf', 'tag': 'Heritage', 'price': '₹ 4,400'},
        {'name': 'Lamb Rogan Josh à la Maharaja', 'desc': 'Tender Kashmiri lamb braised in aromatic spices with charred garlic, dried apricots and saffron yogurt', 'tag': 'Signature', 'price': '₹ 5,200'},
        {'name': 'Crystal Bay Lobster', 'desc': 'Whole fresh water lobster grilled with palace-blend spices, lemon butter and micro herb salad', 'tag': 'Seafood', 'price': '₹ 7,800'},
        {'name': 'Dal Makhani — Century Recipe', 'desc': 'Black lentils simmered for 36 hours in a wood-fired pot, finished with cream and white truffle oil', 'tag': 'Vegetarian', 'price': '₹ 1,800'},
      ]},
      {'category': 'ROYAL DESSERTS', 'items': [
        {'name': 'Saffron Kulfi with Gold Leaf', 'desc': 'Traditional kulfi infused with Persian saffron, pistachios and genuine 24-karat gold leaf garnish', 'tag': 'Signature', 'price': '₹ 1,400'},
        {'name': 'Gulab Jamun Soufflé', 'desc': 'Warm soufflé with a molten gulab jamun centre, rose water emulsion and crystallized rose petals', 'tag': 'Chef\'s Choice', 'price': '₹ 1,600'},
      ]},
      {'category': 'ROYAL BEVERAGES', 'items': [
        {'name': 'Palace Rose Water Sherbet', 'desc': 'Centuries-old recipe — rose petals, cardamom, sugar crystal syrup and chilled spring water', 'tag': 'Non-Alcoholic', 'price': '₹ 800'},
        {'name': 'Kashmir Kahwa Ceremony', 'desc': 'Traditional green tea with cinnamon, clove, cardamom, saffron and crushed almonds, served in copper cups', 'tag': 'Heritage', 'price': '₹ 1,200'},
        {'name': 'Vintage Champagne & Mango Pearls', 'desc': 'Vintage Moët & Chandon with molecular mango pearls and edible gold flakes', 'tag': 'Celebratory', 'price': '₹ 6,800'},
      ]},
    ];

    final tagColors = {
      'Signature': AtithyaColors.royalMaroon,
      'Heritage': const Color(0xFF2C4A1A),
      'Chef\'s Choice': const Color(0xFF2A1A4A),
      'Vegetarian': const Color(0xFF1A3A1A),
      'Seafood': const Color(0xFF1A2A4A),
      'Non-Alcoholic': const Color(0xFF2A2A1A),
      'Celebratory': const Color(0xFF4A2A1A),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
      physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A120A), Color(0xFF0D0A06)],
              ),
              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Text('👨‍🍳', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ROYAL DINING', style: AtithyaTypography.labelSmall.copyWith(letterSpacing: 3)),
                      const SizedBox(height: 4),
                      Text('Michelin-Trained Palace Chef',
                          style: AtithyaTypography.displaySmall.copyWith(fontSize: 14, height: 1.2)),
                      const SizedBox(height: 4),
                      Text('All ingredients sourced from heritage farms & palace gardens',
                          style: AtithyaTypography.caption.copyWith(color: AtithyaColors.parchment.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...menuItems.map((section) {
            final cat = section['category'] as String;
            final items = section['items'] as List;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    children: [
                      Container(width: 3, height: 14, decoration: BoxDecoration(color: AtithyaColors.imperialGold, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Text(cat, style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.imperialGold, letterSpacing: 4, fontSize: 10)),
                    ],
                  ),
                ),
                ...items.map((item) {
                  final mi = item as Map<String, dynamic>;
                  final tag = mi['tag'] as String;
                  final tagColor = tagColors[tag] ?? AtithyaColors.darkSurface;
                  return Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AtithyaColors.darkSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(mi['name'] as String,
                                  style: AtithyaTypography.displaySmall.copyWith(fontSize: 15, height: 1.25)),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(tag, style: AtithyaTypography.labelMicro.copyWith(
                                  color: AtithyaColors.shimmerGold, fontSize: 7, letterSpacing: 1.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(mi['desc'] as String,
                            style: AtithyaTypography.bodyElegant.copyWith(
                                color: AtithyaColors.parchment.withValues(alpha: 0.65), fontSize: 13, height: 1.6),
                            maxLines: 3),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(mi['price'] as String,
                                style: AtithyaTypography.labelSmall.copyWith(fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Experiences Tab ─────────────────────────────────────────────────────
  Widget _buildExperiencesTab(Map<String, dynamic> estate) {
    final experiences = [
      {
        'title': 'Helicopter Palace Arrival',
        'desc': 'Arrive in regal style aboard a private helicopter that lands directly on the palace helipad. A traditional aarti welcome and flower petal shower awaits.',
        'duration': '30 min experience',
        'price': '₹ 48,000 per person',
        'icon': '🚁',
        'tag': 'ELITE',
      },
      {
        'title': 'Private Michelin Chef Dinner',
        'desc': 'A multi-course candlelit dinner in the palace courtyard, curated by a Michelin-trained chef using ingredients sourced from the royal estate gardens and heritage farms.',
        'duration': '3-hour ceremony',
        'price': '₹ 24,000 per couple',
        'icon': '🍽',
        'tag': 'SIGNATURE',
      },
      {
        'title': 'Ancient Ayurvedic Royal Spa',
        'desc': 'A full-day spa experience rooted in 5,000-year-old Ayurvedic traditions. Includes herbal oil abhyanga, udvartana body scrub, and shirodara therapy.',
        'duration': 'Full day',
        'price': '₹ 18,000 per person',
        'icon': '✨',
        'tag': 'WELLNESS',
      },
      {
        'title': 'Exclusive Heritage Architecture Walk',
        'desc': 'A private guided tour through centuries of palace history — from hand-painted frescoes and carved sandstone jharokhas to the secret royal gardens and ancient library.',
        'duration': '2 hour walk',
        'price': 'Complimentary',
        'icon': '🏛',
        'tag': 'HERITAGE',
      },
      {
        'title': 'Sunrise Hot Air Balloon over Palace',
        'desc': 'Float above the palace and landscape at dawn in a private hot air balloon. Champagne breakfast served mid-air as the sun crowns the palace turrets.',
        'duration': '90 min flight',
        'price': '₹ 32,000 per couple',
        'icon': '🎈',
        'tag': 'PREMIUM',
      },
      {
        'title': 'Royal Elephant Procession',
        'desc': 'Ride into the palace grounds atop a ceremonially decorated royal elephant, accompanied by dhol players and flower petal showers — as Maharajas once did.',
        'duration': '45 min procession',
        'price': '₹ 12,000 per couple',
        'icon': '🐘',
        'tag': 'CULTURAL',
      },
      {
        'title': 'Sunset Vintage Car Excursion',
        'desc': 'A private sunset drive through the surrounding heritage landscape in a restored vintage Rolls Royce Silver Shadow, stopping at the most dramatic vistas for photographs.',
        'duration': '2 hour drive',
        'price': '₹ 15,000 per couple',
        'icon': '🚗',
        'tag': 'EXCLUSIVE',
      },
      {
        'title': 'Private Night Stargazing Ceremony',
        'desc': 'The palace rooftop is set with a telescope, velvet cushions, ancient star maps and a master astronomer-guide. Midnight rose kahwa and desserts served under the stars.',
        'duration': '2.5 hour evening',
        'price': '₹ 8,000 per couple',
        'icon': '🌟',
        'tag': 'ROMANTIC',
      },
    ];

    final tagColors = {
      'ELITE': AtithyaColors.royalMaroon,
      'SIGNATURE': const Color(0xFF2A1A0A),
      'WELLNESS': const Color(0xFF1A2A1A),
      'HERITAGE': const Color(0xFF2A2A1A),
      'PREMIUM': const Color(0xFF1A1A3A),
      'CULTURAL': const Color(0xFF3A1A1A),
      'EXCLUSIVE': const Color(0xFF1A2A3A),
      'ROMANTIC': const Color(0xFF2A1A2A),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 110),
      physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURATED EXPERIENCES',
                    style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.imperialGold, letterSpacing: 4, fontSize: 9)),
                const SizedBox(height: 6),
                Text('Moments that become memories',
                    style: AtithyaTypography.displaySmall.copyWith(fontSize: 18)),
                const SizedBox(height: 6),
                Text('Each experience is personally arranged by your dedicated royal concierge. All services require 24–48 hours advance notice.',
                    style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite, fontSize: 13, height: 1.6)),
              ],
            ),
          ),
          ...experiences.asMap().entries.map((entry) {
            final i = entry.key;
            final exp = entry.value;
            final tag = exp['tag']!;
            final tagColor = tagColors[tag] ?? AtithyaColors.darkSurface;
            return Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AtithyaColors.darkSurface, tagColor.withValues(alpha: 0.25)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                        ),
                        child: Center(child: Text(exp['icon']!, style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(exp['title']!,
                                      style: AtithyaTypography.displaySmall.copyWith(fontSize: 15, height: 1.2)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tagColor.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(tag, style: AtithyaTypography.labelMicro.copyWith(
                                      color: AtithyaColors.shimmerGold, fontSize: 7, letterSpacing: 1.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.schedule_outlined, color: AtithyaColors.ashWhite, size: 11),
                                const SizedBox(width: 4),
                                Text(exp['duration']!, style: AtithyaTypography.caption.copyWith(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(exp['desc']!,
                      style: AtithyaTypography.bodyElegant.copyWith(
                          color: AtithyaColors.parchment.withValues(alpha: 0.7), fontSize: 13, height: 1.6),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Text(exp['price']!, style: AtithyaTypography.labelSmall.copyWith(fontSize: 13)),
                ],
              ),
            ).animate(delay: (i * 60).ms).fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildExploreTab(Map<String, dynamic> estate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
      physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 360° Virtual Tour Card
          GestureDetector(
            onTap: () => _show360Tour(context),
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AtithyaColors.darkSurface, AtithyaColors.surfaceElevated],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background shimmer hint
                  if ((estate['panoramaImage'] as String? ?? '').isNotEmpty)
                  Opacity(
                    opacity: 0.08,
                    child: CachedNetworkImage(
                      imageUrl: estate['panoramaImage'] as String,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AtithyaColors.imperialGold, width: 1.5),
                          gradient: const RadialGradient(colors: [
                            AtithyaColors.royalMaroon, AtithyaColors.deepMaroon
                          ]),
                        ),
                        child: const Icon(Icons.vrpano_outlined, color: AtithyaColors.imperialGold, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text('360° VIRTUAL TOUR',
                          style: AtithyaTypography.labelMicro.copyWith(
                              color: AtithyaColors.imperialGold, letterSpacing: 4)),
                      const SizedBox(height: 4),
                      Text('Watch the full estate video tour',
                          style: AtithyaTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms),

          const SizedBox(height: 16),

          // AR Experience Card
          GestureDetector(
            onTap: () => _showARPreview(context),
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AtithyaColors.roseGlow.withValues(alpha: 0.3)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AtithyaColors.darkSurface, Color(0xFF1A0D18)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AtithyaColors.roseGlow, width: 1.5),
                        gradient: const RadialGradient(
                          colors: [AtithyaColors.roseGlow, AtithyaColors.deepMaroon],
                        ),
                      ),
                      child: const Icon(Icons.view_in_ar_rounded, color: AtithyaColors.pearl, size: 28),
                    ),
                    const SizedBox(height: 14),
                    Text('PANORAMA TOUR',
                        style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.roseGlow, letterSpacing: 4)),
                    const SizedBox(height: 4),
                    Text('Swipe left to explore the estate panorama',
                        style: AtithyaTypography.caption),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
        ],
      ),
    );
  }

  void _show360Tour(BuildContext context) {
    final videoId = (widget.estate['videoId360'] as String?)?.trim();
    if (videoId == null || videoId.isEmpty) return;
    final viewId = 'yt-$videoId-${DateTime.now().millisecondsSinceEpoch}';
    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
        return html.IFrameElement()
          ..src = 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1&fs=1'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true
          ..setAttribute('allow', 'autoplay; fullscreen; accelerometer; gyroscope; picture-in-picture');
      });
    }
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogCtx) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // YouTube iframe
            if (kIsWeb)
              HtmlElementView(viewType: viewId)
            else
              const Center(
                child: Text('360° video available on web',
                    style: TextStyle(color: Colors.white)),
              ),
            // Close button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(dialogCtx),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.7),
                      border: Border.all(
                          color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _vrCorner() => CustomPaint(
    size: const Size(20, 20),
    painter: _CornerPainter(),
  );

  void _showARPreview(BuildContext context) {
    final panorama = (widget.estate['panoramaImage'] as String?) ?? '';
    final images = _getImages();
    final urls = panorama.isNotEmpty ? List.filled(3, panorama) : images;
    final tileMultiplier = panorama.isNotEmpty ? 2.2 : 1.1;
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _ARPanoramaDialog(urls: urls, tileMultiplier: tileMultiplier),
    );
  }

  String _formatPrice(dynamic price) {
    final n = ((price as num?)?.toDouble()) ?? 0.0;
    return _locale.formatPrice(n);
  }
}

// Sticky tab bar delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AtithyaColors.obsidian,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}

// VR corner painter
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtithyaColors.imperialGold.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }
  @override bool shouldRepaint(_) => false;
}

/// Panoramic AR viewer with gyroscope/DeviceOrientation support.
/// On mobile web: tilting the phone pans the panorama automatically.
/// Manual drag always works as well.
class _ARPanoramaDialog extends StatefulWidget {
  final List<String> urls;
  final double tileMultiplier;
  const _ARPanoramaDialog({required this.urls, required this.tileMultiplier});

  @override
  State<_ARPanoramaDialog> createState() => _ARPanoramaDialogState();
}

class _ARPanoramaDialogState extends State<_ARPanoramaDialog> {
  late final ScrollController _ctrl;
  html.EventListener? _orientationListener;
  double _lastGamma = 0.0;

  /// null = not yet determined, true = active, false = denied / unavailable
  bool? _gyroGranted;
  /// true only on iOS Safari where `requestPermission` is required
  bool _needsPermission = false;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectGyro());
  }

  // --------------- platform detection ---------------

  void _detectGyro() {
    if (!kIsWeb || !mounted) return;
    // iOS 13+ exposes DeviceOrientationEvent.requestPermission as a static function.
    // Android Chrome / desktop fire events without any permission call.
    final doe = globalContext['DeviceOrientationEvent'] as JSObject?;
    if (doe != null && doe.has('requestPermission')) {
      setState(() => _needsPermission = true); // show “Enable Motion” button
    } else {
      _startListening(); // Android / desktop — start right away
    }
  }

  // --------------- iOS permission request (must be inside a user gesture) ---------------

  Future<void> _requestPermission() async {
    if (!kIsWeb || !mounted) return;
    try {
      final doe = globalContext['DeviceOrientationEvent'] as JSObject?;
      if (doe == null) {
        setState(() { _needsPermission = false; _gyroGranted = false; });
        return;
      }
      // DeviceOrientationEvent.requestPermission() returns Promise<'granted'|'denied'>
      final prom =
          doe.callMethod('requestPermission'.toJS) as JSPromise<JSString>;
      final jsResult = await prom.toDart;
      if (!mounted) return;
      if (jsResult.toDart == 'granted') {
        setState(() => _needsPermission = false);
        _startListening();
      } else {
        setState(() { _needsPermission = false; _gyroGranted = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _needsPermission = false; _gyroGranted = false; });
    }
  }

  // --------------- listener ---------------

  void _startListening() {
    _orientationListener = (html.Event event) {
      if (!mounted || !_ctrl.hasClients) return;
      final e = event as html.DeviceOrientationEvent;
      // gamma = left/right tilt in degrees: -90 (left) .. +90 (right)
      final double gamma = (e.gamma ?? 0.0).clamp(-60.0, 60.0).toDouble();
      if ((gamma - _lastGamma).abs() < 0.8) return; // dead-zone to avoid jitter
      _lastGamma = gamma;
      // Normalise -60°..+60° to 0..1 scroll position
      final double t = ((gamma + 60.0) / 120.0).clamp(0.0, 1.0);
      final double target = t * _ctrl.position.maxScrollExtent;
      _ctrl.animateTo(target,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut);
    };
    html.window.addEventListener('deviceorientation', _orientationListener!);
    if (mounted) setState(() => _gyroGranted = true);
  }

  @override
  void dispose() {
    if (kIsWeb && _orientationListener != null) {
      html.window.removeEventListener('deviceorientation', _orientationListener!);
    }
    _ctrl.dispose();
    super.dispose();
  }

  // --------------- UI ---------------

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final tileW = screenW * widget.tileMultiplier;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Panorama — panned by gyro or by drag
          SizedBox(
            width: screenW,
            height: screenH,
            child: SingleChildScrollView(
              controller: _ctrl,
              scrollDirection: Axis.horizontal,
              physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
              child: Row(
                children: widget.urls.map((url) => CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  height: screenH,
                  width: tileW,
                  placeholder: (_, __) => Container(width: tileW, color: AtithyaColors.darkSurface),
                  errorWidget: (_, __, ___) => Container(width: tileW, color: AtithyaColors.darkSurface),
                )).toList(),
              ),
            ),
          ),

          // VR corner markers
          IgnorePointer(
            child: Stack(children: [
              Positioned(top: 48, left: 24,
                  child: CustomPaint(size: const Size(20, 20), painter: _CornerPainter())),
              Positioned(top: 48, right: 24,
                  child: Transform.flip(flipX: true,
                      child: CustomPaint(size: const Size(20, 20), painter: _CornerPainter()))),
              Positioned(bottom: 80, left: 24,
                  child: Transform.flip(flipY: true,
                      child: CustomPaint(size: const Size(20, 20), painter: _CornerPainter()))),
              Positioned(bottom: 80, right: 24,
                  child: Transform.flip(flipX: true, flipY: true,
                      child: CustomPaint(size: const Size(20, 20), painter: _CornerPainter()))),
            ]),
          ),

          // iOS "Enable Motion" permission button — shown before permission is requested
          if (_needsPermission)
            Center(
              child: GestureDetector(
                onTap: _requestPermission,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.screen_rotation_outlined,
                          color: AtithyaColors.imperialGold, size: 36),
                      const SizedBox(height: 12),
                      Text('ENABLE MOTION',
                          style: AtithyaTypography.labelMicro.copyWith(
                              color: AtithyaColors.imperialGold, letterSpacing: 4)),
                      const SizedBox(height: 6),
                      Text('Tap to allow gyroscope access',
                          style: AtithyaTypography.caption),
                    ],
                  ),
                ),
              ),
            ),

          // Status hint at bottom (shown once state is resolved)
          if (!_needsPermission)
            Positioned(
              bottom: 32, left: 0, right: 0,
              child: Column(
                children: [
                  Text(
                    _gyroGranted == true
                        ? '← TILT PHONE TO EXPLORE →'
                        : '← DRAG TO EXPLORE PANORAMA →',
                    textAlign: TextAlign.center,
                    style: AtithyaTypography.labelMicro.copyWith(
                        color: AtithyaColors.imperialGold, letterSpacing: 4)),
                  const SizedBox(height: 6),
                  Text(
                    _gyroGranted == true
                        ? 'Tilt left / right to pan the estate'
                        : 'Swipe horizontally for 360° view',
                    textAlign: TextAlign.center,
                    style: AtithyaTypography.caption),
                ],
              ),
            ),

          // Close
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.7),
                      border: Border.all(
                          color: AtithyaColors.imperialGold.withValues(alpha: 0.5))),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

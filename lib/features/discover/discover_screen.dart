import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/colors.dart';
import '../../core/network/api_client.dart';
import '../../core/typography.dart';
import '../../providers/estate_provider.dart';
import '../../providers/discover_provider.dart';
import '../../providers/locale_provider.dart';
import '../dossier/dossier_screen.dart';

// Fallback city data when backend is unreachable
const _fallbackCities = <Map<String, dynamic>>[
  {'city': 'Udaipur',   'count': 2, 'minPrice': 15000, 'heroImage': ''},
  {'city': 'Jaipur',    'count': 1, 'minPrice': 20000, 'heroImage': ''},
  {'city': 'Jodhpur',   'count': 1, 'minPrice': 18000, 'heroImage': ''},
  {'city': 'Goa',       'count': 1, 'minPrice': 12000, 'heroImage': ''},
  {'city': 'Kerala',    'count': 2, 'minPrice': 10000, 'heroImage': ''},
  {'city': 'Manali',    'count': 1, 'minPrice': 9000,  'heroImage': ''},
  {'city': 'Jaisalmer', 'count': 1, 'minPrice': 8500,  'heroImage': ''},
];

// Gradient palette per city (fallback when no heroImage)
const _cityGradients = <String, List<Color>>{
  'Udaipur':    [Color(0xFF1A237E), Color(0xFF4A148C)],
  'Jaipur':     [Color(0xFF880E4F), Color(0xFFB71C1C)],
  'Jodhpur':    [Color(0xFF0D47A1), Color(0xFF006064)],
  'Goa':        [Color(0xFF1B5E20), Color(0xFF006064)],
  'Kerala':     [Color(0xFF1A5E20), Color(0xFF0277BD)],
  'Manali':     [Color(0xFF0D47A1), Color(0xFF1A237E)],
  'Jaisalmer':  [Color(0xFFBF360C), Color(0xFFE65100)],
  'Hyderabad':  [Color(0xFF4A148C), Color(0xFF880E4F)],
  'Alleppey':   [Color(0xFF1B5E20), Color(0xFF004D40)],
  'Gulmarg':    [Color(0xFF0D47A1), Color(0xFF263238)],
};

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String? _selectedCity;
  String _searchQuery = '';
  String? _selectedCategory;
  int? _maxPrice; // null = any price

  // ── Nearby location state ────────────────────────────────────────────────
  final _api = ApiClient();
  List<Map<String, dynamic>> _nearbyEstates = [];
  String? _nearbyLabel;
  bool _nearbyLoading = false;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    setState(() { _nearbyLoading = true; _locationDenied = false; });
    try {
      // Check / request permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() { _nearbyLoading = false; _locationDenied = true; });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      final lat = pos.latitude;
      final lng = pos.longitude;

      // Progressive radius: city → nearby → state
      final checks = [
        (30,  'disc.nearCity'),
        (150, 'disc.nearby'),
        (500, 'disc.region'),
      ];

      for (final (radius, label) in checks) {
        try {
          final result = await _api.get(
              '/estates/nearby?lat=$lat&lng=$lng&radius=$radius');
          final list = (result as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ?? [];
          if (list.isNotEmpty) {
            setState(() {
              _nearbyEstates = list;
              _nearbyLabel = label;
              _nearbyLoading = false;
            });
            return;
          }
        } catch (_) {
          // try next radius
        }
      }
      // Nothing found at any radius
      setState(() { _nearbyEstates = []; _nearbyLoading = false; });
    } catch (_) {
      setState(() { _nearbyLoading = false; });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _selectCity(String city) {
    setState(() {
      _selectedCity = city;
      _searchQuery = '';
      _searchCtrl.clear();
    });
    ref.read(estateProvider.notifier).fetchEstates(city: city);
    _scrollCtrl.animateTo(0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic);
  }

  void _clearCity() {
    setState(() {
      _selectedCity = null;
      _searchQuery = '';
      _searchCtrl.clear();
    });
    ref.read(estateProvider.notifier).fetchEstates();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(discoverFeedProvider);
    final estateState = ref.watch(estateProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _selectedCity == null
            ? _buildPicker(feed, context, locale)
            : _buildEstateList(estateState, context),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DESTINATION PICKER
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildPicker(DiscoverFeedState feed, BuildContext context, LocaleState locale) {
    final rawCities = feed.cities.isNotEmpty
        ? feed.cities
        : _fallbackCities.cast<Map<String, dynamic>>();
    final cities = _searchQuery.isEmpty
        ? rawCities
        : rawCities
            .where((c) => (c['city'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    return CustomScrollView(
      key: const ValueKey('picker'),
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _pickerHero(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: _SearchBar(
              controller: _searchCtrl,
              hint: locale.t('disc.search'),
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
        ),
        // ── NEAR YOU section ────────────────────────────────────────────────
        if (_nearbyLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
              child: Row(children: [
                Container(width: 3, height: 18, color: AtithyaColors.imperialGold),
                const SizedBox(width: 10),
                Text(locale.t('disc.nearYou'),
                    style: AtithyaTypography.labelMicro.copyWith(
                        color: AtithyaColors.imperialGold, letterSpacing: 2.5)),
                const SizedBox(width: 10),
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AtithyaColors.imperialGold,
                  ),
                ),
              ]),
            ),
          )
        else if (_locationDenied)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: GestureDetector(
                onTap: _loadNearby,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AtithyaColors.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_outlined,
                          color: AtithyaColors.imperialGold, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Enable location to discover nearby estates',
                          style: AtithyaTypography.caption
                              .copyWith(color: AtithyaColors.ashWhite),
                        ),
                      ),
                      const Icon(Icons.refresh,
                          color: AtithyaColors.imperialGold, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (_nearbyEstates.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
                  child: Row(children: [
                    Container(width: 3, height: 18, color: AtithyaColors.imperialGold),
                    const SizedBox(width: 10),
                    Text(locale.t(_nearbyLabel ?? 'disc.nearYou'),
                        style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.imperialGold, letterSpacing: 2.5)),
                  ]),
                ),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _nearbyEstates.length > 6 ? 6 : _nearbyEstates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) {
                      final e = _nearbyEstates[i];
                      final imgs = e['images'] as List<dynamic>?;
                      final img = imgs != null && imgs.isNotEmpty
                          ? imgs[0] as String
                          : '';
                      final name = e['name'] as String? ?? '';
                      final city = e['city'] as String? ?? '';
                      final price = e['pricePerNight'];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => DossierScreen(estate: e, index: i),
                          ),
                        ),
                        child: Container(
                          width: 150,
                          decoration: BoxDecoration(
                            color: AtithyaColors.darkSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: img.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: img,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorWidget: (_, __, ___) => Container(
                                          color: const Color(0xFF1A1A2E),
                                          child: const Icon(Icons.image_not_supported_outlined,
                                              color: Colors.white24),
                                        ),
                                      )
                                    : Container(color: const Color(0xFF1A1A2E)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AtithyaTypography.bodyElegant.copyWith(
                                            fontSize: 12, color: AtithyaColors.cream)),
                                    Text(city,
                                        style: AtithyaTypography.caption.copyWith(fontSize: 10)),
                                    if (price != null)
                                      Text('₹${(price as num).toStringAsFixed(0)}/n',
                                          style: AtithyaTypography.labelMicro.copyWith(
                                              color: AtithyaColors.imperialGold,
                                              fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
            child: Row(
              children: [
                Container(width: 3, height: 18, color: AtithyaColors.imperialGold),
                const SizedBox(width: 10),
                Text(
                  locale.t('disc.popular'),
                  style: AtithyaTypography.labelMicro.copyWith(
                    color: AtithyaColors.imperialGold,
                    letterSpacing: 2.5,
                  ),
                ),
                const Spacer(),
                if (feed.isLoading)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AtithyaColors.imperialGold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 110),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                if (i >= cities.length) return null;
                return _CityCard(
                  data: cities[i],
                  index: i,
                  onTap: () => _selectCity(cities[i]['city'] as String),
                );
              },
              childCount: cities.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.80,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pickerHero(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(minHeight: h * 0.28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0800), Color(0xFF3B0A14), Color(0xFF080A0E)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AtithyaColors.imperialGold.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 28, height: 1,
                          color: AtithyaColors.imperialGold),
                      const SizedBox(width: 8),
                      Text('आतिथ्य',
                          style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.imperialGold,
                            letterSpacing: 2,
                          )),
                    ],
                  ).animate().fadeIn(duration: 600.ms),
                  const SizedBox(height: 14),
                  Text(
                    'Where would you\nlike to go?',
                    style: AtithyaTypography.displaySmall.copyWith(
                      fontSize: 26, height: 1.25,
                      color: AtithyaColors.parchment,
                    ),
                  ).animate()
                      .fadeIn(duration: 700.ms, delay: 100.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 8),
                  Text(
                    "India's finest palaces & heritage estates",
                    style: AtithyaTypography.bodyText.copyWith(
                      color: AtithyaColors.parchment.withValues(alpha: 0.65),
                    ),
                  ).animate().fadeIn(duration: 700.ms, delay: 200.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ESTATE LIST
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildEstateList(EstateState state, BuildContext context) {
    final all = state.estates;
    var estates = _searchQuery.isEmpty
        ? all
        : all.where((e) {
            final t = (e['title'] as String? ?? '').toLowerCase();
            final c = (e['category'] as String? ?? '').toLowerCase();
            final q = _searchQuery.toLowerCase();
            return t.contains(q) || c.contains(q);
          }).toList();

    // Apply category filter
    if (_selectedCategory != null) {
      estates = estates.where((e) {
        final cat = (e['category'] as String? ?? '').toLowerCase();
        return cat.contains(_selectedCategory!.toLowerCase());
      }).toList();
    }

    // Apply price filter
    if (_maxPrice != null) {
      estates = estates.where((e) {
        final price = (e['pricePerNight'] as num?)?.toInt() ?? 0;
        return price <= _maxPrice!;
      }).toList();
    }

    return CustomScrollView(
      key: const ValueKey('estates'),
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _estateHeader(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _SearchBar(
              controller: _searchCtrl,
              hint: 'Search estates in $_selectedCity…',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
        ),
        // ── Filter chips ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _FilterRow(
            selectedCategory: _selectedCategory,
            maxPrice: _maxPrice,
            onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
            onPriceChanged: (price) => setState(() => _maxPrice = price),
          ),
        ),
        if (state.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: AtithyaColors.imperialGold,
                  ),
                ),
              ),
            ),
          )
        else if (state.error != null && estates.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.wifi_off_rounded,
                      color: AtithyaColors.imperialGold.withValues(alpha: 0.4),
                      size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load estates in $_selectedCity',
                    style: AtithyaTypography.bodyText
                        .copyWith(color: AtithyaColors.parchment),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref
                        .read(estateProvider.notifier)
                        .fetchEstates(city: _selectedCity),
                    child: Text('Retry',
                        style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.imperialGold,
                            letterSpacing: 1.5)),
                  ),
                ],
              ),
            ),
          )
        else if (estates.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No estates found in $_selectedCity',
                  style: AtithyaTypography.bodyText
                      .copyWith(color: AtithyaColors.parchment),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 110),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _EstateCard(estate: estates[i], index: i),
                ),
                childCount: estates.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _estateHeader(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: top + 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AtithyaColors.royalMaroon.withValues(alpha: 0.35),
            AtithyaColors.obsidian,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _clearCity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded,
                      size: 13,
                      color: AtithyaColors.imperialGold.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text('All Destinations',
                      style: AtithyaTypography.labelMicro.copyWith(
                        color: AtithyaColors.imperialGold,
                        letterSpacing: 1.5,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCity ?? '',
              style: AtithyaTypography.displaySmall.copyWith(
                fontSize: 28, color: AtithyaColors.parchment,
              ),
            ).animate()
                .fadeIn(duration: 500.ms)
                .slideX(begin: -0.05, end: 0, curve: Curves.easeOut),
            const SizedBox(height: 4),
            Text(
              'Heritage estates & luxury retreats',
              style: AtithyaTypography.bodyText.copyWith(
                color: AtithyaColors.parchment.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CITY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;
  final VoidCallback onTap;

  const _CityCard({required this.data, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name       = data['city']     as String? ?? '';
    final count      = data['count']    as int?    ?? 0;
    final minPrice   = data['minPrice'];
    final heroImage  = data['heroImage'] as String? ?? '';
    final gradColors = _cityGradients[name] ??
        [const Color(0xFF1A237E), const Color(0xFF4A148C)];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.22)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image or gradient
              if (heroImage.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: heroImage,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _GradientBg(colors: gradColors),
                )
              else
                _GradientBg(colors: gradColors),

              // Dark overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),

              // Decorative ring
              Positioned(
                top: -30, right: -30,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05), width: 1),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Spacer(),
                    Text(
                      name,
                      style: AtithyaTypography.cardTitle.copyWith(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AtithyaColors.imperialGold.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count ${count == 1 ? 'estate' : 'estates'}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AtithyaColors.obsidian,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (minPrice != null && (minPrice as num) > 0)
                      Text(
                        'From ₹${_fmt(minPrice)}/night',
                        style: AtithyaTypography.labelMicro.copyWith(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: Duration(milliseconds: 55 * index))
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }

  String _fmt(dynamic price) {
    final p = (price as num?)?.toInt() ?? 0;
    if (p >= 100000) return '${(p / 100000).toStringAsFixed(1)}L';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K';
    return '$p';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ESTATE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _EstateCard extends StatelessWidget {
  final dynamic estate;
  final int index;
  const _EstateCard({required this.estate, required this.index});

  @override
  Widget build(BuildContext context) {
    final title     = estate['title']     as String? ?? 'Estate';
    final city      = estate['city']      as String? ?? '';
    final category  = estate['category']  as String? ?? '';
    final basePrice = estate['basePrice'] ?? 0;
    final rating    = ((estate['rating'] ?? 4.5) as num).toDouble();
    final heroImage = estate['heroImage'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => DossierScreen(
                  estate: estate as Map<String, dynamic>, index: index))),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (heroImage.isNotEmpty)
                CachedNetworkImage(
                    imageUrl: heroImage,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AtithyaColors.darkSurface),
                    errorWidget: (_, __, ___) =>
                        Container(color: AtithyaColors.darkSurface))
              else
                Container(color: AtithyaColors.darkSurface),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.30, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AtithyaColors.imperialGold
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AtithyaColors.imperialGold
                                .withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.shimmerGold,
                          letterSpacing: 1.5,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: AtithyaTypography.cardTitle.copyWith(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12,
                            color: AtithyaColors.imperialGold
                                .withValues(alpha: 0.75)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(city,
                              style: AtithyaTypography.labelMicro.copyWith(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.star_rounded,
                            size: 12, color: AtithyaColors.shimmerGold),
                        const SizedBox(width: 3),
                        Text(rating.toStringAsFixed(1),
                            style: AtithyaTypography.labelMicro.copyWith(
                                color: AtithyaColors.shimmerGold,
                                fontSize: 11)),
                        const SizedBox(width: 8),
                        Text('₹${_fmt(basePrice)}',
                            style: AtithyaTypography.cardTitle.copyWith(
                              color: AtithyaColors.imperialGold,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                        Text('/n',
                            style: AtithyaTypography.labelMicro.copyWith(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: Duration(milliseconds: 70 * index))
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
    );
  }

  String _fmt(dynamic price) {
    final p = (price as num?)?.toInt() ?? 0;
    if (p >= 100000) return '${(p / 100000).toStringAsFixed(1)}L';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K';
    return '$p';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _GradientBg extends StatelessWidget {
  final List<Color> colors;
  const _GradientBg({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: AtithyaColors.imperialGold.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.07),
              blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(Icons.search_rounded,
              color: AtithyaColors.imperialGold.withValues(alpha: 0.65),
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: AtithyaTypography.bodyText
                  .copyWith(color: AtithyaColors.parchment),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AtithyaTypography.bodyText.copyWith(
                    color: AtithyaColors.parchment.withValues(alpha: 0.45)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(Icons.close_rounded,
                    size: 18,
                    color: AtithyaColors.parchment.withValues(alpha: 0.5)),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER ROW — category pills + price range
// ─────────────────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final String? selectedCategory;
  final int? maxPrice;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<int?> onPriceChanged;

  const _FilterRow({
    required this.selectedCategory,
    required this.maxPrice,
    required this.onCategoryChanged,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    const categories = ['Palace', 'Heritage', 'Villa', 'Resort', 'Treehouse', 'Haveli'];
    const prices = <String, int?>{
      'Any Price': null,
      'Under ₹10K': 10000,
      'Under ₹20K': 20000,
      'Under ₹50K': 50000,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category pills
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip(
                label: 'All',
                selected: selectedCategory == null,
                onTap: () => onCategoryChanged(null),
              ),
              ...categories.map((cat) => _chip(
                label: cat,
                selected: selectedCategory == cat,
                onTap: () => onCategoryChanged(selectedCategory == cat ? null : cat),
              )),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Price pills
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: prices.entries.map((e) => _chip(
              label: e.key,
              selected: maxPrice == e.value,
              onTap: () => onPriceChanged(e.value),
              small: true,
            )).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _chip({required String label, required bool selected, required VoidCallback onTap, bool small = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: small ? 10 : 14, vertical: small ? 5 : 8),
        decoration: BoxDecoration(
          color: selected
              ? AtithyaColors.imperialGold.withValues(alpha: 0.15)
              : const Color(0xFF111318),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AtithyaColors.imperialGold.withValues(alpha: 0.6)
                : AtithyaColors.imperialGold.withValues(alpha: 0.18),
          ),
        ),
        child: Text(label, style: AtithyaTypography.labelMicro.copyWith(
          color: selected ? AtithyaColors.imperialGold : AtithyaColors.ashWhite,
          fontSize: small ? 8 : 9,
          letterSpacing: 1.5,
        )),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/widgets.dart';
import '../../providers/estate_provider.dart';
import '../../providers/locale_provider.dart';
import '../dossier/dossier_screen.dart';

// ── Filter State (Riverpod 3.x Notifiers) ─────────────────────────

class _PriceRangeNotifier extends Notifier<RangeValues> {
  @override RangeValues build() => const RangeValues(0, 400000);
  void set(RangeValues v) => state = v;
}
class _CategoryNotifier extends Notifier<String> {
  @override String build() => 'All';
  void set(String v) => state = v;
}
class _SortNotifier extends Notifier<String> {
  @override String build() => 'default';
  void set(String v) => state = v;
}
class _FacilitiesNotifier extends Notifier<List<String>> {
  @override List<String> build() => [];
  void set(List<String> v) => state = v;
}

final priceRangeProvider = NotifierProvider<_PriceRangeNotifier, RangeValues>(_PriceRangeNotifier.new);
final eFilterCategoryProvider = NotifierProvider<_CategoryNotifier, String>(_CategoryNotifier.new);
final eSortProvider = NotifierProvider<_SortNotifier, String>(_SortNotifier.new);
final eSelectedFacilitiesProvider = NotifierProvider<_FacilitiesNotifier, List<String>>(_FacilitiesNotifier.new);

const _facilities = ['Pool', 'Spa', 'Helipad', 'Butler', 'Kitchen', 'Garden', 'Chauffeur', 'Yoga', 'Beach Access'];
const _sortOptions = ['default', 'price_asc', 'price_desc', 'rating'];
const _sortLabels = {'default': 'Recommended', 'price_asc': 'Price: Low→High', 'price_desc': 'Price: High→Low', 'rating': 'Top Rated'};

class EstatesScreen extends ConsumerStatefulWidget {
  /// When set, filters estates by city and shows a back-navigable header.
  final String? filterCity;
  const EstatesScreen({super.key, this.filterCity});

  @override
  ConsumerState<EstatesScreen> createState() => _EstatesScreenState();
}

class _EstatesScreenState extends ConsumerState<EstatesScreen> {
  bool _isGrid = true;
  LocaleState _locale = const LocaleState();

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    _locale = ref.watch(localeProvider);
    final estateState = ref.watch(estateProvider);
    // Apply city filter if launched from JourneyDetailScreen
    final rawEstates = estateState.estates;
    final estates = widget.filterCity != null
        ? rawEstates.where((e) =>
            (e['city'] as String? ?? '').toLowerCase() ==
            widget.filterCity!.toLowerCase()).toList()
        : rawEstates;

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: CustomScrollView(
        physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
        slivers: [
          // ── Top Bar ─────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AtithyaColors.obsidian,
            floating: true,
            pinned: widget.filterCity != null,
            leading: widget.filterCity != null
                ? GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AtithyaColors.darkSurface,
                        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AtithyaColors.imperialGold, size: 14),
                    ),
                  )
                : null,
            elevation: 0,
            toolbarHeight: 90,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.filterCity != null
                                ? widget.filterCity!.toUpperCase()
                                : _locale.t('est.allEstates'),
                            style: AtithyaTypography.labelMicro.copyWith(
                                color: AtithyaColors.imperialGold, letterSpacing: 4)),
                          Text(
                            widget.filterCity != null
                                ? '${estates.length} ${_locale.t('est.propertiesIn')} ${widget.filterCity}'
                                : '${estates.length} ${_locale.t('est.royalProperties')}',
                            style: AtithyaTypography.displaySmall.copyWith(fontSize: 20),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Toggle grid/list
                    GestureDetector(
                      onTap: () => setState(() => _isGrid = !_isGrid),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AtithyaColors.darkSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                        ),
                        child: Icon(_isGrid ? Icons.view_list : Icons.grid_view,
                            color: AtithyaColors.imperialGold, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.imperialGold]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tune_outlined, color: AtithyaColors.obsidian, size: 16),
                            const SizedBox(width: 6),
                            Text(_locale.t('est.filter'), style: AtithyaTypography.labelMicro.copyWith(
                                color: AtithyaColors.obsidian, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter chips row ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 0, 16),
              child: Consumer(builder: (context, ref, _) {
                final _loc = ref.watch(localeProvider);
                final _sl = {'default': _loc.t('est.sortRec'), 'price_asc': _loc.t('est.sortPriceLow'), 'price_desc': _loc.t('est.sortPriceHigh'), 'rating': _loc.t('est.sortRating')};
                final sortLabel = _sl[ref.watch(eSortProvider)] ?? _loc.t('est.sortRec');
                final filterCat = ref.watch(eFilterCategoryProvider);
                final facs = ref.watch(eSelectedFacilitiesProvider);
                return SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
                    children: [
                      _filterChip(sortLabel, Icons.sort, true),
                      const SizedBox(width: 8),
                      if (filterCat != 'All') _filterChip(filterCat, Icons.castle_outlined, true),
                      ...facs.map((f) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _filterChip(f, Icons.check_circle_outline, true),
                      )),
                    ],
                  ),
                );
              }),
            ),
          ),

          // ── Estate List/Grid ─────────────────────────────────
          if (estateState.isLoading)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const ShimmerEstateCard(),
                  childCount: 6,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.65,
                ),
              ),
            )
          else if (estates.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AtithyaColors.darkSurface,
                        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.castle_outlined, color: AtithyaColors.imperialGold, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      estateState.error != null ? _locale.t('com.error') : _locale.t('est.noResults'),
                      style: AtithyaTypography.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      estateState.error != null
                          ? 'Check your connection and try again.'
                          : 'Try adjusting your filters.',
                      style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => ref.read(estateProvider.notifier).fetchEstates(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_locale.t('com.retry'), style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.imperialGold, letterSpacing: 2)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_isGrid)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildGridCard(estates[i], i),
                  childCount: estates.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.65,
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildListCard(estates[i], i),
                  ),
                  childCount: estates.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, IconData icon, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AtithyaColors.imperialGold.withValues(alpha: 0.15) : AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AtithyaColors.imperialGold.withValues(alpha: 0.4) : AtithyaColors.surfaceElevated,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AtithyaColors.imperialGold, size: 12),
          const SizedBox(width: 6),
          Text(label, style: AtithyaTypography.caption.copyWith(
              color: AtithyaColors.cream, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> estate, int i) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DossierScreen(estate: estate, index: i))),
      child: Container(
        decoration: BoxDecoration(
          color: AtithyaColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: estate['heroImage'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AtithyaColors.surfaceElevated),
                    errorWidget: (_, __, ___) => Container(color: AtithyaColors.surfaceElevated,
                        child: const Icon(Icons.castle_outlined, color: AtithyaColors.ashWhite)),
                  ),
                  if (estate['featured'] == true)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text('✦', style: TextStyle(fontSize: 8, color: AtithyaColors.obsidian)),
                      ),
                    ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: AtithyaColors.royalMaroon.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(3)),
                      child: Text((estate['category'] ?? '').toUpperCase(),
                          style: AtithyaTypography.labelMicro.copyWith(
                              color: AtithyaColors.shimmerGold, fontSize: 7)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((estate['city'] ?? '').toUpperCase(),
                            style: AtithyaTypography.labelMicro.copyWith(
                                color: AtithyaColors.imperialGold, fontSize: 8)),
                        const SizedBox(height: 3),
                        Text(estate['title'] ?? '',
                            style: AtithyaTypography.displaySmall.copyWith(fontSize: 13),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AtithyaColors.imperialGold, size: 10),
                        const SizedBox(width: 3),
                        Text('${estate['rating'] ?? 4.8}',
                            style: AtithyaTypography.caption.copyWith(
                                color: AtithyaColors.parchment, fontSize: 10)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(_formatPrice(estate['basePrice'] ?? 0),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: AtithyaTypography.labelSmall.copyWith(fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> estate, int i) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DossierScreen(estate: estate, index: i))),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: AtithyaColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: CachedNetworkImage(
                imageUrl: estate['heroImage'] ?? '',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AtithyaColors.surfaceElevated),
                errorWidget: (_, __, ___) => Container(color: AtithyaColors.surfaceElevated),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((estate['city'] ?? '').toUpperCase(),
                            style: AtithyaTypography.labelMicro.copyWith(
                                color: AtithyaColors.imperialGold, fontSize: 8)),
                        const SizedBox(height: 4),
                        Text(estate['title'] ?? '',
                            style: AtithyaTypography.displaySmall.copyWith(fontSize: 15),
                            maxLines: 2),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AtithyaColors.imperialGold, size: 12),
                        const SizedBox(width: 4),
                        Text('${estate['rating'] ?? 4.8}',
                            style: AtithyaTypography.caption.copyWith(
                                color: AtithyaColors.parchment)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('${_formatPrice(estate['basePrice'] ?? 0)}/n',
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: AtithyaTypography.labelSmall.copyWith(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final n = price is num ? price : num.tryParse('$price') ?? 0;
    return _locale.formatPrice(n);
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────
class _FilterSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late RangeValues _priceRange;
  late String _category;
  late String _sort;
  late List<String> _selectedFacilities;

  @override
  void initState() {
    super.initState();
    _priceRange = ref.read(priceRangeProvider);
    _category = ref.read(eFilterCategoryProvider);
    _sort = ref.read(eSortProvider);
    _selectedFacilities = List.from(ref.read(eSelectedFacilitiesProvider));
  }

  void _applyFilters() {
    ref.read(priceRangeProvider.notifier).set(_priceRange);
    ref.read(eFilterCategoryProvider.notifier).set(_category);
    ref.read(eSortProvider.notifier).set(_sort);
    ref.read(eSelectedFacilitiesProvider.notifier).set(_selectedFacilities);
    ref.read(estateProvider.notifier).fetchEstates(
      category: _category == 'All' ? null : _category,
      maxPrice: _priceRange.end.toInt(),
      minPrice: _priceRange.start.toInt(),
      sort: _sort == 'default' ? null : _sort,
      facilities: _selectedFacilities.isEmpty ? null : _selectedFacilities.join(','),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final sortLabels = {'default': locale.t('est.sortRec'), 'price_asc': locale.t('est.sortPriceLow'), 'price_desc': locale.t('est.sortPriceHigh'), 'rating': locale.t('est.sortRating')};
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: AtithyaColors.deepMidnight.withValues(alpha: 0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(top: BorderSide(color: Color(0x33C8972B))),
          ),
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(width: 48, height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterHeader(locale.t('est.sortBy')),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: _sortOptions.map((s) {
                      final isActive = _sort == s;
                      return GestureDetector(
                        onTap: () => setState(() => _sort = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? AtithyaColors.imperialGold : AtithyaColors.darkSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isActive ? AtithyaColors.imperialGold : AtithyaColors.surfaceElevated),
                          ),
                          child: Text(sortLabels[s] ?? s,
                              style: AtithyaTypography.caption.copyWith(
                                  color: isActive ? AtithyaColors.obsidian : AtithyaColors.cream)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  _FilterHeader(locale.t('est.category')),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: ['All', 'Palace', 'Heritage', 'Beach', 'Mountain', 'Forest', 'Desert', 'Urban', 'Island'].map((c) {
                      final isActive = _category == c;
                      return GestureDetector(
                        onTap: () => setState(() => _category = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? AtithyaColors.royalMaroon : AtithyaColors.darkSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isActive ? AtithyaColors.roseGlow : AtithyaColors.surfaceElevated),
                          ),
                          child: Text(c, style: AtithyaTypography.caption.copyWith(
                              color: isActive ? AtithyaColors.pearl : AtithyaColors.cream)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  _FilterHeader(locale.t('est.tariff')),
                  Text(
                    '₹${(_priceRange.start / 1000).toStringAsFixed(0)}K — ₹${(_priceRange.end / 1000).toStringAsFixed(0)}K',
                    style: AtithyaTypography.displaySmall.copyWith(color: AtithyaColors.imperialGold, fontSize: 18),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AtithyaColors.imperialGold,
                      inactiveTrackColor: AtithyaColors.surfaceElevated,
                      thumbColor: AtithyaColors.shimmerGold,
                      overlayColor: AtithyaColors.imperialGold.withValues(alpha: 0.2),
                    ),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0, max: 400000, divisions: 40,
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FilterHeader(locale.t('est.amenities')),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: _facilities.map((f) {
                      final selected = _selectedFacilities.contains(f);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) _selectedFacilities.remove(f);
                          else _selectedFacilities.add(f);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AtithyaColors.surfaceElevated : AtithyaColors.darkSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? AtithyaColors.imperialGold : AtithyaColors.surfaceElevated),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) const Icon(Icons.check, color: AtithyaColors.imperialGold, size: 12),
                              if (selected) const SizedBox(width: 4),
                              Text(f, style: AtithyaTypography.caption.copyWith(
                                  color: selected ? AtithyaColors.imperialGold : AtithyaColors.cream)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SafeArea(
              top: false,
              child: GoldButton(label: locale.t('est.apply'), onTap: _applyFilters),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _FilterHeader extends StatelessWidget {
  final String title;
  const _FilterHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(title,
          style: AtithyaTypography.labelMicro.copyWith(
              color: AtithyaColors.imperialGold, letterSpacing: 4)),
    );
  }
}

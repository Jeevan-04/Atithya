import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../auth/auth_foyer_screen.dart';
import '../dossier/dossier_screen.dart';
import 'journey_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Trip Planner Screen
// ─────────────────────────────────────────────────────────────────────────────

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _expandedRoute = -1;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: NestedScrollView(
        physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
        headerSliverBuilder: (ctx, inner) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildTabBar()),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _CuratedCircuitsTab(
              expandedRoute: _expandedRoute,
              onExpand: (i) => setState(() =>
                  _expandedRoute = _expandedRoute == i ? -1 : i),
            ),
            const _CustomTripBuilderTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C0E12), Color(0xFF1A0E08), Color(0xFF0E0814)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 24, height: 1.5,
                      color: AtithyaColors.imperialGold),
                  const SizedBox(width: 8),
                  Text('ATITHYA JOURNEYS',
                      style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.imperialGold, letterSpacing: 3)),
                ],
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 10),
              Text('Plan Your Journey',
                  style: AtithyaTypography.displayLarge.copyWith(
                    fontSize: 28, color: AtithyaColors.pearl,
                  )).animate().fadeIn(duration: 700.ms, delay: 100.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 6),
              Text(
                'Multi-stop journeys across India\'s sacred circuits & royal trails',
                style: AtithyaTypography.bodyText.copyWith(
                    color: AtithyaColors.parchment.withValues(alpha: 0.6)),
              ).animate().fadeIn(duration: 700.ms, delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AtithyaColors.obsidian,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AtithyaColors.darkSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.18)),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: AtithyaTypography.labelMicro.copyWith(
              color: AtithyaColors.obsidian,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700),
          unselectedLabelStyle: AtithyaTypography.labelMicro.copyWith(
              color: AtithyaColors.parchment,
              letterSpacing: 1.5),
          labelColor: AtithyaColors.obsidian,
          unselectedLabelColor: AtithyaColors.parchment,
          tabs: const [
            Tab(text: 'CURATED CIRCUITS'),
            Tab(text: 'BUILD YOUR OWN'),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CURATED CIRCUITS TAB
// ═════════════════════════════════════════════════════════════════════════════

class _CuratedCircuitsTab extends ConsumerWidget {
  final int expandedRoute;
  final ValueChanged<int> onExpand;

  const _CuratedCircuitsTab({
    required this.expandedRoute,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(tripRoutesProvider);

    if (routeState.isLoading) {
      return const Center(
        child: SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AtithyaColors.imperialGold),
        ),
      );
    }

    if (routeState.error != null && routeState.routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: AtithyaColors.imperialGold.withValues(alpha: 0.4),
                size: 48),
            const SizedBox(height: 16),
            Text('Could not load journey circuits',
                style: AtithyaTypography.bodyText
                    .copyWith(color: AtithyaColors.parchment)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  ref.read(tripRoutesProvider.notifier).fetchRoutes(),
              child: Text('Retry',
                  style: AtithyaTypography.labelMicro.copyWith(
                      color: AtithyaColors.imperialGold, letterSpacing: 1.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 20),
      physics: const BouncingScrollPhysics(),
      itemCount: routeState.routes.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _RouteCard(
          route: routeState.routes[i],
          index: i,
          isExpanded: expandedRoute == i,
          onExpand: () => onExpand(i),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One route card (collapsible)
// ─────────────────────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final int index;
  final bool isExpanded;
  final VoidCallback onExpand;

  const _RouteCard({
    required this.route,
    required this.index,
    required this.isExpanded,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final name     = route['name']     as String? ?? '';
    final tagline  = route['tagline']  as String? ?? '';
    final icon     = route['icon']     as String? ?? '🗺️';
    final duration = route['duration'] as String? ?? '';
    final stops    = (route['stops'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? AtithyaColors.imperialGold.withValues(alpha: 0.45)
              : AtithyaColors.imperialGold.withValues(alpha: 0.18),
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                    color:
                        AtithyaColors.imperialGold.withValues(alpha: 0.12),
                    blurRadius: 20)
              ]
            : null,
      ),
      child: Column(
        children: [
          // Header tap area
          GestureDetector(
            onTap: onExpand,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon circle
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A0E08), Color(0xFF2A1808)],
                      ),
                      border: Border.all(
                          color: AtithyaColors.imperialGold
                              .withValues(alpha: 0.35)),
                    ),
                    child: Center(
                      child: Text(icon,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: AtithyaTypography.cardTitle.copyWith(
                              color: AtithyaColors.pearl,
                              fontSize: 15,
                            )),
                        const SizedBox(height: 3),
                        Text(tagline,
                            style: AtithyaTypography.bodyText.copyWith(
                              color: AtithyaColors.parchment
                                  .withValues(alpha: 0.6),
                              fontSize: 11,
                            )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _pill(Icons.location_on_rounded,
                                '${stops.length} stops'),
                            const SizedBox(width: 8),
                            _pill(Icons.schedule_rounded, duration),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AtithyaColors.imperialGold.withValues(alpha: 0.7),
                        size: 22),
                  ),
                ],
              ),
            ),
          ),

          // Expanded stop details
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 350),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                    color: AtithyaColors.imperialGold.withValues(alpha: 0.15),
                    height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      ...stops.asMap().entries.map((e) =>
                          _StopTile(
                              stop: e.value,
                              stopIndex: e.key,
                              isLast: e.key == stops.length - 1)),
                      const SizedBox(height: 16),
                      // Plan this journey CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _openRouteDetail(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.all(
                                Colors.transparent),
                            overlayColor: WidgetStateProperty.all(
                                AtithyaColors.burnishedGold
                                    .withValues(alpha: 0.1)),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AtithyaColors.burnishedGold,
                                  AtithyaColors.shimmerGold
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              child: Text('PLAN THIS JOURNEY',
                                  style: AtithyaTypography.labelMicro
                                      .copyWith(
                                    color: AtithyaColors.obsidian,
                                    letterSpacing: 2.5,
                                    fontWeight: FontWeight.w800,
                                  )),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.07, end: 0, curve: Curves.easeOutCubic);
  }

  void _openRouteDetail(BuildContext context) {
    final stops = (route['stops'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => _RouteDetailScreen(route: route, stops: stops)));
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AtithyaColors.obsidian,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AtithyaColors.imperialGold.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AtithyaColors.subtleGold),
          const SizedBox(width: 4),
          Text(label,
              style: AtithyaTypography.caption.copyWith(
                  color: AtithyaColors.parchment.withValues(alpha: 0.7),
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stop tile inside collapsed route card
// ─────────────────────────────────────────────────────────────────────────────

class _StopTile extends StatelessWidget {
  final Map<String, dynamic> stop;
  final int stopIndex;
  final bool isLast;

  const _StopTile({
    required this.stop,
    required this.stopIndex,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final city     = stop['city']        as String? ?? '';
    final nights   = stop['nights']      as int?    ?? 1;
    final desc     = stop['description'] as String? ?? '';
    final estates  = (stop['estates'] as List? ?? []).cast<Map<String, dynamic>>();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AtithyaColors.obsidian,
                  border: Border.all(color: AtithyaColors.imperialGold, width: 1.5),
                ),
                child: Center(
                  child: Text('${stopIndex + 1}',
                      style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.imperialGold,
                          fontSize: 9)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: AtithyaColors.imperialGold.withValues(alpha: 0.25),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Stop content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(city,
                          style: AtithyaTypography.cardTitle.copyWith(
                              color: AtithyaColors.pearl, fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AtithyaColors.royalMaroon
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$nights nights',
                            style: AtithyaTypography.caption.copyWith(
                                color: AtithyaColors.shimmerGold,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: AtithyaTypography.caption.copyWith(
                          color: AtithyaColors.parchment.withValues(alpha: 0.55),
                          letterSpacing: 0.3)),
                  if (estates.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: estates.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (ctx, i) =>
                            _EstateThumb(estate: estates[i], index: i),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text('Coming soon · Estates being curated',
                        style: AtithyaTypography.caption.copyWith(
                            color: AtithyaColors.subtleGold
                                .withValues(alpha: 0.55),
                            letterSpacing: 0.5,
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Small estate thumbnail inside a stop
class _EstateThumb extends StatelessWidget {
  final Map<String, dynamic> estate;
  final int index;
  const _EstateThumb({required this.estate, required this.index});

  @override
  Widget build(BuildContext context) {
    final title     = estate['title']     as String? ?? '';
    final heroImage = estate['heroImage'] as String? ?? '';
    final basePrice = estate['basePrice'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  DossierScreen(estate: estate, index: index))),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              heroImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: heroImage,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(color: AtithyaColors.darkSurface),
                    )
                  : Container(color: AtithyaColors.darkSurface),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 6, left: 8, right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('₹${_fmt(basePrice)}/night',
                        style: TextStyle(
                            color: AtithyaColors.shimmerGold
                                .withValues(alpha: 0.9),
                            fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(dynamic price) {
    final p = (price as num?)?.toInt() ?? 0;
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K';
    return '$p';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CUSTOM TRIP BUILDER TAB
// ═════════════════════════════════════════════════════════════════════════════

class _CustomTripBuilderTab extends ConsumerStatefulWidget {
  const _CustomTripBuilderTab();

  @override
  ConsumerState<_CustomTripBuilderTab> createState() => _CustomTripBuilderTabState();
}

class _CustomTripBuilderTabState extends ConsumerState<_CustomTripBuilderTab> {
  final List<_TripStop> _stops = [];
  final TextEditingController _tripNameCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _tripNameCtrl.dispose();
    super.dispose();
  }

  void _addStop() {
    setState(() => _stops.add(_TripStop()));
  }

  void _removeStop(int i) {
    setState(() => _stops.removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip name
          _SectionLabel('TRIP NAME'),
          const SizedBox(height: 8),
          _GoldTextField(
              controller: _tripNameCtrl,
              hint: 'e.g. My Rajasthan Adventure'),
          const SizedBox(height: 24),

          // Stops
          Row(
            children: [
              _SectionLabel('STOPS'),
              const Spacer(),
              GestureDetector(
                onTap: _addStop,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AtithyaColors.imperialGold
                            .withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 14,
                          color: AtithyaColors.imperialGold),
                      const SizedBox(width: 4),
                      Text('ADD STOP',
                          style: AtithyaTypography.labelMicro.copyWith(
                              color: AtithyaColors.imperialGold,
                              letterSpacing: 1.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_stops.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AtithyaColors.darkSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AtithyaColors.imperialGold.withValues(alpha: 0.12),
                    style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.map_outlined,
                      size: 40,
                      color: AtithyaColors.subtleGold.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Add your first destination',
                      style: AtithyaTypography.bodyText.copyWith(
                          color: AtithyaColors.parchment
                              .withValues(alpha: 0.5))),
                  const SizedBox(height: 4),
                  Text('Tap "Add Stop" to start building your journey',
                      style: AtithyaTypography.caption.copyWith(
                          color: AtithyaColors.ashWhite
                              .withValues(alpha: 0.4),
                          letterSpacing: 0.3)),
                ],
              ),
            )
          else
            ...List.generate(
              _stops.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StopEditor(
                  stopNumber: i + 1,
                  stop: _stops[i],
                  onRemove: () => _removeStop(i),
                  onChanged: () => setState(() {}),
                ),
              ),
            ),

          if (_stops.isNotEmpty) ...[
            const SizedBox(height: 24),
            // Save CTA
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    AtithyaColors.burnishedGold,
                    AtithyaColors.shimmerGold,
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AtithyaColors.imperialGold
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: _isSaving ? null : () => _savePlan(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              color: AtithyaColors.obsidian))
                      : Text('SAVE JOURNEY PLAN',
                          style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.obsidian,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w800,
                          )),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _savePlan(BuildContext context) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AuthFoyerScreen()));
      return;
    }
    final name = _tripNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AtithyaColors.royalMaroon,
        content: Text('Please enter a trip name',
            style: AtithyaTypography.bodyText.copyWith(color: AtithyaColors.pearl)),
      ));
      return;
    }
    final incomplete = _stops.any((s) => s.city.isEmpty);
    if (incomplete) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AtithyaColors.royalMaroon,
        content: Text('Please fill in all stop cities',
            style: AtithyaTypography.bodyText.copyWith(color: AtithyaColors.pearl)),
      ));
      return;
    }

    setState(() => _isSaving = true);
    final stopMaps = _stops.map((s) => {
      'city': s.city,
      'nights': s.nights,
      'notes': s.notes,
    }).toList();

    final result = await ref.read(userTripsProvider.notifier).saveTrip(
      name: name,
      stops: stopMaps,
    );
    setState(() => _isSaving = false);

    if (!context.mounted) return;
    if (result != null) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => JourneyDetailScreen(trip: result)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AtithyaColors.errorRed.withValues(alpha: 0.15),
        content: Text('Could not save journey. Please try again.',
            style: AtithyaTypography.caption.copyWith(color: AtithyaColors.errorRed)),
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stop editor widget for custom trip builder
// ─────────────────────────────────────────────────────────────────────────────

class _StopEditor extends StatefulWidget {
  final int stopNumber;
  final _TripStop stop;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _StopEditor({
    required this.stopNumber,
    required this.stop,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_StopEditor> createState() => _StopEditorState();
}

class _StopEditorState extends State<_StopEditor> {
  late TextEditingController _cityCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(text: widget.stop.city);
    _notesCtrl = TextEditingController(text: widget.stop.notes);
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AtithyaColors.imperialGold.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AtithyaColors.imperialGold.withValues(alpha: 0.15),
                  border: Border.all(
                      color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text('${widget.stopNumber}',
                      style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.imperialGold, fontSize: 9)),
                ),
              ),
              const SizedBox(width: 10),
              Text('Stop ${widget.stopNumber}',
                  style: AtithyaTypography.cardTitle.copyWith(
                      color: AtithyaColors.pearl, fontSize: 12)),
              const Spacer(),
              GestureDetector(
                onTap: widget.onRemove,
                child: Icon(Icons.close_rounded,
                    size: 18,
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GoldTextField(
            controller: _cityCtrl,
            hint: 'City (e.g. Udaipur)',
            onChanged: (v) {
              widget.stop.city = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NIGHTS',
                        style: AtithyaTypography.caption.copyWith(
                            color: AtithyaColors.subtleGold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            if (widget.stop.nights > 1) {
                              widget.stop.nights--;
                              widget.onChanged();
                            }
                          }),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: AtithyaColors.obsidian,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AtithyaColors.imperialGold
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.remove_rounded,
                                size: 14,
                                color: AtithyaColors.imperialGold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('${widget.stop.nights}',
                              style: AtithyaTypography.cardTitle.copyWith(
                                  color: AtithyaColors.pearl, fontSize: 16)),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            if (widget.stop.nights < 14) {
                              widget.stop.nights++;
                              widget.onChanged();
                            }
                          }),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: AtithyaColors.obsidian,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AtithyaColors.imperialGold
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.add_rounded,
                                size: 14,
                                color: AtithyaColors.imperialGold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Route detail full screen
// ─────────────────────────────────────────────────────────────────────────────

class _RouteDetailScreen extends StatelessWidget {
  final Map<String, dynamic> route;
  final List<Map<String, dynamic>> stops;

  const _RouteDetailScreen({required this.route, required this.stops});

  @override
  Widget build(BuildContext context) {
    final name    = route['name']    as String? ?? '';
    final tagline = route['tagline'] as String? ?? '';
    final icon    = route['icon']    as String? ?? '🗺️';
    final dur     = route['duration'] as String? ?? '';

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AtithyaColors.obsidian,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AtithyaColors.darkSurface,
                  border: Border.all(
                      color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AtithyaColors.imperialGold, size: 14),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A0E08), Color(0xFF0E0814), Color(0xFF080A0E)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(icon,
                          style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(name,
                          style: AtithyaTypography.displayMedium.copyWith(
                              color: AtithyaColors.pearl)),
                      Text(tagline,
                          style: AtithyaTypography.caption.copyWith(
                              color: AtithyaColors.parchment
                                  .withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          _infoChip(Icons.location_on_rounded,
                              '${stops.length} Stops'),
                          const SizedBox(width: 10),
                          _infoChip(Icons.schedule_rounded, dur),
                        ],
                      ),
                    );
                  }
                  final stopIdx = i - 1;
                  if (stopIdx >= stops.length) return null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _StopTile(
                      stop: stops[stopIdx],
                      stopIndex: stopIdx,
                      isLast: stopIdx == stops.length - 1,
                    ),
                  );
                },
                childCount: stops.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AtithyaColors.imperialGold.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AtithyaColors.imperialGold),
          const SizedBox(width: 6),
          Text(label,
              style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.parchment, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _TripStop {
  String city = '';
  int nights = 2;
  String notes = '';
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: AtithyaTypography.labelMicro.copyWith(
          color: AtithyaColors.imperialGold, letterSpacing: 3));
}

class _GoldTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const _GoldTextField({
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AtithyaColors.imperialGold.withValues(alpha: 0.22)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AtithyaTypography.bodyText.copyWith(color: AtithyaColors.pearl),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AtithyaTypography.bodyText.copyWith(
              color: AtithyaColors.ashWhite.withValues(alpha: 0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

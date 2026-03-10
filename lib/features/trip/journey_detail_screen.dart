import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../auth/auth_foyer_screen.dart';
import '../estates/estates_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Journey Detail Screen
// Shows full journey plan: timeline of stops, hotel finder per stop, save/delete
// ─────────────────────────────────────────────────────────────────────────────

class JourneyDetailScreen extends ConsumerStatefulWidget {
  /// A trip from the backend (has _id) or a curated route preview (no _id).
  final Map<String, dynamic> trip;

  /// If true, show a "Save This Journey" CTA (curated route preview mode).
  final bool isPreview;

  const JourneyDetailScreen({
    super.key,
    required this.trip,
    this.isPreview = false,
  });

  @override
  ConsumerState<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends ConsumerState<JourneyDetailScreen> {
  bool _saving = false;
  bool _deleting = false;

  Map<String, dynamic> get _trip => widget.trip;

  List<Map<String, dynamic>> get _stops =>
      (_trip['stops'] as List? ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();

  int get _totalNights =>
      _stops.fold<int>(0, (sum, s) => sum + ((s['nights'] as num?)?.toInt() ?? 2));

  int get _stopsWithHotel =>
      _stops.where((s) => s['estateId'] != null).length;

  Future<void> _saveJourney() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AuthFoyerScreen()));
      return;
    }

    setState(() => _saving = true);
    final result = await ref.read(userTripsProvider.notifier).saveTrip(
          name: _trip['name'] as String? ?? 'My Journey',
          stops: _stops,
          type: 'curated',
          routeKey: _trip['key'] as String?,
        );
    setState(() => _saving = false);

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AtithyaColors.darkSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.4)),
          ),
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: AtithyaColors.shimmerGold, size: 18),
            const SizedBox(width: 10),
            Text('Journey saved to My Trips',
                style: AtithyaTypography.caption.copyWith(color: AtithyaColors.pearl)),
          ]),
        ));
        // Navigate to non-preview mode with saved trip
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => JourneyDetailScreen(trip: result)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AtithyaColors.errorRed.withValues(alpha: 0.15),
          content: Text('Could not save. Please try again.',
              style: AtithyaTypography.caption.copyWith(color: AtithyaColors.errorRed)),
        ));
      }
    }
  }

  Future<void> _deleteJourney() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtithyaColors.darkSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.2))),
        title: Text('Delete Journey?',
            style: AtithyaTypography.displaySmall.copyWith(fontSize: 16)),
        content: Text('This journey plan will be removed.',
            style: AtithyaTypography.caption.copyWith(color: AtithyaColors.ashWhite)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AtithyaTypography.labelSmall
                .copyWith(color: AtithyaColors.parchment)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: AtithyaTypography.labelSmall
                .copyWith(color: AtithyaColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _deleting = true);
      final ok = await ref.read(userTripsProvider.notifier)
          .deleteTrip(_trip['_id'].toString());
      if (mounted) {
        if (ok) Navigator.pop(context);
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name     = _trip['name']     as String? ?? 'Journey Plan';
    final iconKey  = (_trip['key']  as String? ?? _trip['icon'] as String? ?? '');
    final tagline  = _trip['tagline']  as String? ?? '';
    final duration = _trip['duration'] as String? ?? '$_totalNights nights';
    final cities   = _stops.map((s) => s['city'] as String? ?? '').where((c) => c.isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AtithyaColors.obsidian,
            leading: GestureDetector(
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
            ),
            actions: [
              if (!widget.isPreview && _trip['_id'] != null)
                GestureDetector(
                  onTap: _deleting ? null : _deleteJourney,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AtithyaColors.darkSurface,
                      border: Border.all(color: AtithyaColors.errorRed.withValues(alpha: 0.3)),
                    ),
                    child: _deleting
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AtithyaColors.errorRed))
                        : Icon(Icons.delete_outline_rounded,
                            color: AtithyaColors.errorRed.withValues(alpha: 0.8), size: 16),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A0E08), Color(0xFF0E0814), Color(0xFF080A0E)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1A0E08),
                                border: Border.all(
                                    color: AtithyaColors.imperialGold, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AtithyaColors.imperialGold
                                        .withValues(alpha: 0.28),
                                    blurRadius: 16, spreadRadius: 2),
                                ],
                              ),
                              child: Icon(journeyIcon(iconKey),
                                  color: AtithyaColors.imperialGold, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: AtithyaTypography.displayMedium.copyWith(
                                          color: AtithyaColors.pearl, fontSize: 20)),
                                  if (tagline.isNotEmpty)
                                    Text(tagline,
                                        style: AtithyaTypography.caption.copyWith(
                                            color: AtithyaColors.parchment.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _pill(Icons.location_on_rounded, '${_stops.length} stops'),
                            const SizedBox(width: 8),
                            _pill(Icons.schedule_rounded, duration),
                            if (_stopsWithHotel > 0) ...[
                              const SizedBox(width: 8),
                              _pill(Icons.hotel_rounded,
                                  '$_stopsWithHotel/${_stops.length} hotels',
                                  color: AtithyaColors.shimmerGold),
                            ],
                          ],
                        ),
                        if (cities.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(cities,
                              style: AtithyaTypography.caption.copyWith(
                                  color: AtithyaColors.imperialGold.withValues(alpha: 0.7),
                                  letterSpacing: 0.4),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Save CTA (preview mode) ──────────────────────────────────────
          if (widget.isPreview)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: _saving ? null : _saveJourney,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: AtithyaColors.imperialGold.withValues(alpha: 0.3),
                            blurRadius: 16),
                      ],
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2,
                                  color: AtithyaColors.obsidian))
                          : Text('SAVE TO MY JOURNEYS',
                              style: AtithyaTypography.labelMicro.copyWith(
                                  color: AtithyaColors.obsidian,
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

          // ── Section label ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(width: 3, height: 18, color: AtithyaColors.imperialGold),
                  const SizedBox(width: 10),
                  Text('JOURNEY STOPS',
                      style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.imperialGold, letterSpacing: 2.5)),
                ],
              ),
            ),
          ),

          // ── Stop Timeline ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _StopCard(
                  stop: _stops[i],
                  stopIndex: i,
                  isLast: i == _stops.length - 1,
                  tripId: widget.isPreview ? null : _trip['_id']?.toString(),
                ).animate(delay: Duration(milliseconds: 80 * i))
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                childCount: _stops.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, {Color? color}) {
    final c = color ?? AtithyaColors.parchment.withValues(alpha: 0.7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: c),
        const SizedBox(width: 4),
        Text(label,
            style: AtithyaTypography.caption.copyWith(color: c, letterSpacing: 0.3)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single stop card with timeline line
// ─────────────────────────────────────────────────────────────────────────────

class _StopCard extends ConsumerWidget {
  final Map<String, dynamic> stop;
  final int stopIndex;
  final bool isLast;
  final String? tripId;

  const _StopCard({
    required this.stop,
    required this.stopIndex,
    required this.isLast,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city        = stop['city']        as String? ?? '';
    final nights      = (stop['nights']     as num?)?.toInt() ?? 2;
    final desc        = stop['description'] as String? ?? stop['notes'] as String? ?? '';
    final estateData  = stop['estateId'];   // populated by backend or null
    final hasEstate   = estateData is Map;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasEstate ? AtithyaColors.imperialGold.withValues(alpha: 0.25) : AtithyaColors.obsidian,
                    border: Border.all(
                        color: hasEstate ? AtithyaColors.imperialGold : AtithyaColors.imperialGold.withValues(alpha: 0.45),
                        width: 1.5),
                  ),
                  child: Center(
                    child: hasEstate
                        ? const Icon(Icons.check, color: AtithyaColors.shimmerGold, size: 13)
                        : Text('${stopIndex + 1}',
                            style: AtithyaTypography.labelMicro.copyWith(
                                color: AtithyaColors.imperialGold, fontSize: 10)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1.5,
                        color: AtithyaColors.imperialGold.withValues(alpha: 0.2),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Card content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 12, bottom: isLast ? 0 : 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AtithyaColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasEstate
                        ? AtithyaColors.imperialGold.withValues(alpha: 0.35)
                        : AtithyaColors.imperialGold.withValues(alpha: 0.12),
                  ),
                  boxShadow: hasEstate
                      ? [BoxShadow(
                          color: AtithyaColors.imperialGold.withValues(alpha: 0.06),
                          blurRadius: 12)]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // City + nights
                    Row(
                      children: [
                        Expanded(
                          child: Text(city,
                              style: AtithyaTypography.cardTitle.copyWith(
                                  color: AtithyaColors.pearl, fontSize: 15)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AtithyaColors.royalMaroon.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$nights nights',
                              style: AtithyaTypography.caption.copyWith(
                                  color: AtithyaColors.shimmerGold, letterSpacing: 0.4)),
                        ),
                      ],
                    ),

                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(desc,
                          style: AtithyaTypography.caption.copyWith(
                              color: AtithyaColors.parchment.withValues(alpha: 0.55),
                              letterSpacing: 0.3)),
                    ],

                    const SizedBox(height: 12),

                    // Hotel linked or Find Hotels
                    if (hasEstate)
                      _LinkedHotelTile(estate: estateData as Map<String, dynamic>)
                    else
                      _FindHotelsButton(city: city),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estate already linked ────────────────────────────────────────────────────

class _LinkedHotelTile extends StatelessWidget {
  final Map<String, dynamic> estate;
  const _LinkedHotelTile({required this.estate});

  @override
  Widget build(BuildContext context) {
    final title     = estate['title']     as String? ?? '';
    final city      = estate['city']      as String? ?? '';
    final heroImage = estate['heroImage'] as String? ?? '';
    final price     = estate['basePrice'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 64, height: 64,
            child: heroImage.isNotEmpty
                ? CachedNetworkImage(imageUrl: heroImage, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AtithyaColors.obsidian))
                : Container(color: AtithyaColors.obsidian,
                    child: const Icon(Icons.castle_outlined, color: AtithyaColors.ashWhite)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AtithyaTypography.cardTitle.copyWith(
                        color: AtithyaColors.pearl, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(city,
                    style: AtithyaTypography.caption.copyWith(
                        color: AtithyaColors.imperialGold.withValues(alpha: 0.7),
                        fontSize: 10)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${_fmt(price)}/n',
                    style: AtithyaTypography.labelSmall.copyWith(
                        color: AtithyaColors.shimmerGold, fontSize: 11)),
                const SizedBox(height: 2),
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50), size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic p) {
    final n = (p as num?)?.toInt() ?? 0;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}

// ── Find Hotels button ───────────────────────────────────────────────────────

class _FindHotelsButton extends StatelessWidget {
  final String city;
  const _FindHotelsButton({required this.city});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EstatesScreen(filterCity: city))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AtithyaColors.imperialGold.withValues(alpha: 0.12),
              AtithyaColors.burnishedGold.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hotel_rounded,
                color: AtithyaColors.imperialGold, size: 16),
            const SizedBox(width: 8),
            Text(
              city.isNotEmpty ? 'FIND HOTELS IN ${city.toUpperCase()}' : 'BROWSE HOTELS',
              style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.imperialGold, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

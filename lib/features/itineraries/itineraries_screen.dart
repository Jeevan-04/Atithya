import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/trip_provider.dart';
import '../trip/journey_detail_screen.dart';
import '../trip/trip_planner_screen.dart';

class ItinerariesScreen extends ConsumerStatefulWidget {
  const ItinerariesScreen({super.key});

  @override
  ConsumerState<ItinerariesScreen> createState() => _ItinerariesScreenState();
}

class _ItinerariesScreenState extends ConsumerState<ItinerariesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  LocaleState _locale = const LocaleState();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        ref.read(bookingProvider.notifier).fetchMyBookings();
        ref.read(userTripsProvider.notifier).fetchMyTrips();
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bookingState = ref.watch(bookingProvider);
    final locale = ref.watch(localeProvider);
    _locale = locale;

    if (!authState.isAuthenticated) {
      return _buildGuestPrompt();
    }

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildBookingsTab(bookingState, locale),
                _buildMyTripsTab(locale),
                const _PlanTripLauncher(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final locale = _locale;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0C0E12), Color(0xFF1A1008), Color(0xFF120D1A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _LatticePatternPainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(width: 24, height: 1.5, color: AtithyaColors.imperialGold),
                        const SizedBox(width: 8),
                        Text(locale.t('it.mySanctuaries'), style: AtithyaTypography.labelSmall.copyWith(
                          color: AtithyaColors.imperialGold, letterSpacing: 4, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Royal Journeys', style: AtithyaTypography.heroTitle.copyWith(
                      fontSize: 34, color: AtithyaColors.pearl)),
                    const SizedBox(height: 6),
                    Text('Your escapes · Your planned circuits', style: AtithyaTypography.bodyElegant.copyWith(
                      color: Colors.white38, fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final locale = _locale;
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
                colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
              borderRadius: BorderRadius.circular(22),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: AtithyaTypography.labelMicro.copyWith(
                color: AtithyaColors.obsidian, letterSpacing: 1.5,
                fontWeight: FontWeight.w700),
            unselectedLabelStyle: AtithyaTypography.labelMicro.copyWith(
                color: AtithyaColors.parchment, letterSpacing: 1.5),
            labelColor: AtithyaColors.obsidian,
            unselectedLabelColor: AtithyaColors.parchment,
            tabs: [
              Tab(text: locale.t('it.bookings')),
              Tab(text: locale.t('it.myTrips')),
              Tab(text: locale.t('it.plan')),
            ],
          ),
        ),
    );
  }

  Widget _buildBookingsTab(bookingState, LocaleState locale) {
    if (bookingState.isLoading) {
      return const Center(
        child: SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: AtithyaColors.imperialGold),
        ),
      );
    }
    if (bookingState.bookings.isEmpty) {
      return Center(
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
              child: const Icon(Icons.bookmark_border_outlined,
                  color: AtithyaColors.imperialGold, size: 36),
            ),
            const SizedBox(height: 24),
            Text('No Sanctuaries Booked', style: AtithyaTypography.displaySmall),
            const SizedBox(height: 8),
            Text('Your royal escapes will appear here.',
                style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite)),
          ],
        ).animate().fadeIn(duration: 700.ms),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      itemCount: bookingState.bookings.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _buildBookingCard(bookingState.bookings[i], i),
      ),
    );
  }

  Widget _buildMyTripsTab(LocaleState locale) {
    final tripsState = ref.watch(userTripsProvider);

    if (tripsState.isLoading) {
      return const Center(
        child: SizedBox(width: 28, height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: AtithyaColors.imperialGold)),
      );
    }

    if (tripsState.trips.isEmpty) {
      return Center(
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
              child: const Icon(Icons.map_outlined, color: AtithyaColors.imperialGold, size: 36),
            ),
            const SizedBox(height: 24),
            Text('No Journeys Planned', style: AtithyaTypography.displaySmall),
            const SizedBox(height: 8),
            Text('Head to the PLAN tab to start a journey.',
                style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _tabCtrl.animateTo(2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(locale.t('it.planJourney'),
                    style: AtithyaTypography.labelMicro.copyWith(
                        color: AtithyaColors.obsidian, letterSpacing: 2)),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 700.ms),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      itemCount: tripsState.trips.length,
      itemBuilder: (ctx, i) {
        final trip = tripsState.trips[i];
        final stops = (trip['stops'] as List? ?? []);
        final totalNights = stops.fold<int>(0, (s, st) => s + ((st['nights'] as num?)?.toInt() ?? 2));
        final cities = stops
            .map((s) => s['city'] as String? ?? '')
            .where((c) => c.isNotEmpty)
            .join(' · ');
        final icon = trip['key'] as String? ?? trip['icon'] as String? ?? '';
        final name = trip['name'] as String? ?? 'Journey';
        final stopsLinked = stops.where((s) => s['estateId'] != null).length;
        final createdAt = trip['createdAt'] as String? ?? '';
        String dateStr = '';
        try {
          dateStr = DateFormat('dd MMM yy').format(DateTime.parse(createdAt));
        } catch (_) {}

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JourneyDetailScreen(trip: trip)),
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AtithyaColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.18)),
                boxShadow: [BoxShadow(
                  color: AtithyaColors.imperialGold.withValues(alpha: 0.04),
                  blurRadius: 16)],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AtithyaColors.obsidian,
                      border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.35)),
                    ),
                    child: Center(child: Icon(journeyIcon(icon), color: AtithyaColors.imperialGold, size: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: AtithyaTypography.cardTitle.copyWith(
                                color: AtithyaColors.pearl, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(cities,
                            style: AtithyaTypography.caption.copyWith(
                                color: AtithyaColors.parchment.withValues(alpha: 0.55),
                                letterSpacing: 0.3),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(children: [
                          _tripPill(Icons.schedule_rounded, '$totalNights nights'),
                          const SizedBox(width: 6),
                          _tripPill(Icons.location_on_outlined, '${stops.length} stops'),
                          if (stopsLinked > 0) ...[
                            const SizedBox(width: 6),
                            _tripPill(Icons.hotel_rounded,
                                '$stopsLinked linked',
                                color: AtithyaColors.shimmerGold),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (dateStr.isNotEmpty)
                        Text(dateStr, style: AtithyaTypography.caption.copyWith(
                            color: AtithyaColors.ashWhite.withValues(alpha: 0.4),
                            fontSize: 10)),
                      const SizedBox(height: 8),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: AtithyaColors.imperialGold),
                    ],
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 400.ms),
        );
      },
    );
  }

  Widget _tripPill(IconData icon, String label, {Color? color}) {
    final c = color ?? AtithyaColors.ashWhite.withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AtithyaColors.obsidian,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 9, color: c),
        const SizedBox(width: 3),
        Text(label, style: AtithyaTypography.caption.copyWith(color: c, fontSize: 9.5)),
      ]),
    );
  }

  Widget _buildGuestPrompt() {
    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AtithyaColors.royalMaroon, AtithyaColors.deepMaroon]),
                  border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.lock_outline, color: AtithyaColors.imperialGold, size: 36),
              ),
              const SizedBox(height: 28),
              Text('Members Only', style: AtithyaTypography.displayMedium),
              const SizedBox(height: 12),
              Text(
                'Login to access your personal itineraries and manage your royal escapes.',
                style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite),
                textAlign: TextAlign.center,
              ),
            ],
          ).animate().fadeIn(duration: 800.ms),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b, int i) {
    final estate = b['estate'] as Map<String, dynamic>? ?? {};
    final isConfirmed = (b['status'] ?? '') == 'Confirmed';
    final statusColor = isConfirmed ? const Color(0xFF4CAF50) : AtithyaColors.imperialGold;
    String checkIn = '', checkOut = '';
    try {
      checkIn = DateFormat('dd MMM').format(DateTime.parse(b['checkInDate'].toString()));
      checkOut = DateFormat('dd MMM yy').format(DateTime.parse(b['checkOutDate'].toString()));
    } catch (_) {}

    final images = (estate['images'] as List?)?.whereType<String>().toList() ?? [];
    final heroUrl = images.isNotEmpty ? images[0] : (estate['heroImage'] ?? '');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111318),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(color: AtithyaColors.imperialGold.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold accent line at top
          Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold, AtithyaColors.burnishedGold]),
            ),
          ),
          // Image
          SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: heroUrl, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: const Color(0xFF1A1C22)),
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1C22),
                    child: const Icon(Icons.castle_outlined, color: AtithyaColors.ashWhite)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, const Color(0xFF111318).withValues(alpha: 0.9)],
                    ),
                  ),
                ),
                // Status badge
                Positioned(top: 12, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                        const SizedBox(width: 5),
                        Text((b['status'] ?? '').toUpperCase(), style: AtithyaTypography.labelSmall.copyWith(
                          color: statusColor, fontSize: 9, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                ),
                // Location at bottom
                Positioned(bottom: 12, left: 14,
                  child: Text((estate['location'] ?? '').toUpperCase(),
                    style: AtithyaTypography.labelSmall.copyWith(color: AtithyaColors.imperialGold.withValues(alpha: 0.8), fontSize: 9, letterSpacing: 2)),
                ),
              ],
            ),
          ),
          // Info section
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(estate['title'] ?? 'Royal Estate', style: AtithyaTypography.displaySmall.copyWith(fontSize: 19)),
                const SizedBox(height: 14),
                // Date + guests + price row
                Row(
                  children: [
                    _infoTile(Icons.calendar_month_outlined, '$checkIn – $checkOut'),
                    const SizedBox(width: 18),
                    _infoTile(Icons.group_outlined, '${b['guests'] ?? 2} guests'),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_locale.t('it.total'), style: AtithyaTypography.labelSmall.copyWith(
                          color: AtithyaColors.ashWhite, fontSize: 8, letterSpacing: 2)),
                        Text('₹${(b['totalAmount'] ?? 0).toStringAsFixed(0)}',
                          style: AtithyaTypography.price.copyWith(fontSize: 18, color: AtithyaColors.shimmerGold)),
                      ],
                    ),
                  ],
                ),
                if (b['specialRequest'] != null && b['specialRequest'].toString().isNotEmpty) ...[  
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AtithyaColors.royalMaroon.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AtithyaColors.royalMaroon.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('✶ ', style: TextStyle(color: AtithyaColors.imperialGold, fontSize: 11)),
                        Expanded(child: Text(b['specialRequest'].toString(),
                          style: AtithyaTypography.caption.copyWith(color: AtithyaColors.parchment, fontSize: 11))),
                      ],
                    ),
                  ),
                ],
                // Cancel button — only for Confirmed bookings
                if ((b['status'] ?? '') == 'Confirmed') ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        AtithyaColors.imperialGold.withValues(alpha: 0.15),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // QR PASS button
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => _showQrPass(context, b),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AtithyaColors.imperialGold.withValues(alpha: 0.18),
                                AtithyaColors.burnishedGold.withValues(alpha: 0.1),
                              ]),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2_rounded,
                                    color: AtithyaColors.imperialGold, size: 16),
                                const SizedBox(width: 6),
                                Text(_locale.t('it.qrPass'),
                                    style: AtithyaTypography.labelSmall.copyWith(
                                        color: AtithyaColors.imperialGold,
                                        fontSize: 10, letterSpacing: 1.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _confirmCancel(context, b),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: AtithyaColors.errorRed.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_outlined,
                                    color: AtithyaColors.errorRed.withValues(alpha: 0.8), size: 14),
                                const SizedBox(width: 6),
                                Text(_locale.t('it.cancel'),
                                    style: AtithyaTypography.labelSmall.copyWith(
                                        color: AtithyaColors.errorRed.withValues(alpha: 0.8),
                                        fontSize: 10, letterSpacing: 1.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // QR only for non-Confirmed statuses (Checked In / Out)
                if ((b['status'] ?? '') == 'Checked In' || (b['status'] ?? '') == 'Checked Out') ...[
                  const SizedBox(height: 16),
                  Container(height: 1, decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, AtithyaColors.imperialGold.withValues(alpha: 0.12), Colors.transparent]))),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showQrPass(context, b),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AtithyaColors.imperialGold.withValues(alpha: 0.14),
                          AtithyaColors.burnishedGold.withValues(alpha: 0.08),
                        ]),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded, color: AtithyaColors.imperialGold, size: 16),
                          const SizedBox(width: 8),
                          Text(_locale.t('it.viewQrPass'),
                              style: AtithyaTypography.labelSmall.copyWith(
                                  color: AtithyaColors.imperialGold,
                                  fontSize: 10, letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate()
     .fadeIn(duration: 600.ms, delay: Duration(milliseconds: 80 * i))
     .slideY(begin: 0.08, end: 0, duration: 500.ms, delay: Duration(milliseconds: 80 * i));
  }

  void _showQrPass(BuildContext context, Map<String, dynamic> b) {
    final estate = (b['estate'] as Map<String, dynamic>?) ?? {};
    final qrData = b['qrToken'] as String? ?? b['_id'].toString();
    final status = b['status'] ?? '';
    String checkIn = '', checkOut = '';
    try {
      checkIn = DateFormat('dd MMM yy').format(DateTime.parse(b['checkInDate'].toString()));
      checkOut = DateFormat('dd MMM yy').format(DateTime.parse(b['checkOutDate'].toString()));
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1014),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: AtithyaColors.imperialGold, width: 0.6),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(width: 36, height: 3, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AtithyaColors.imperialGold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2))),
            Text(_locale.t('it.royalPass'),
                style: AtithyaTypography.labelMicro.copyWith(
                    color: AtithyaColors.imperialGold, letterSpacing: 5)),
            const SizedBox(height: 6),
            Text(estate['title'] ?? 'Royal Estate',
                style: AtithyaTypography.displaySmall.copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AtithyaColors.pearl,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: AtithyaColors.imperialGold.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 2),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF080A0E),
              ),
            ),
            const SizedBox(height: 20),
            // Booking info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AtithyaColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  _qrInfoRow('Room', '${b['roomType']} · ${b['roomNumber'] ?? '—'}'),
                  const SizedBox(height: 8),
                  _qrInfoRow('Check-In', checkIn),
                  const SizedBox(height: 8),
                  _qrInfoRow('Check-Out', checkOut),
                  const SizedBox(height: 8),
                  _qrInfoRow('Guests', '${b['guests'] ?? 2}'),
                  const SizedBox(height: 8),
                  _qrInfoRow('Status', status.toUpperCase(),
                      valueColor: status == 'Checked In'
                          ? const Color(0xFF4CAF50)
                          : AtithyaColors.imperialGold),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Present this QR at the gate, main desk, lift & room door for seamless access.',
              style: AtithyaTypography.caption.copyWith(
                  color: AtithyaColors.ashWhite.withValues(alpha: 0.45),
                  fontSize: 11, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AtithyaTypography.caption.copyWith(
            color: AtithyaColors.ashWhite.withValues(alpha: 0.5), fontSize: 11)),
        Text(value, style: AtithyaTypography.labelSmall.copyWith(
            color: valueColor ?? AtithyaColors.parchment, fontSize: 12)),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context, Map<String, dynamic> b) async {
    final estate = (b['estate'] as Map<String, dynamic>?) ?? {};
    final total = (b['totalAmount'] ?? 0) as num;
    final fee = (total * 0.20).toStringAsFixed(0);
    final refund = (total * 0.80).toStringAsFixed(0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF111318),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AtithyaColors.errorRed.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AtithyaColors.errorRed.withValues(alpha: 0.5)),
                  color: AtithyaColors.errorRed.withValues(alpha: 0.08),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: AtithyaColors.errorRed.withValues(alpha: 0.85), size: 28),
              ),
              const SizedBox(height: 20),
              Text('Cancel Reservation',
                  style: AtithyaTypography.displaySmall.copyWith(fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                estate['title'] ?? 'Royal Estate',
                style: AtithyaTypography.caption.copyWith(
                    color: AtithyaColors.imperialGold, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AtithyaColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.12)),
                ),
                child: Column(
                  children: [
                    _cancelFeeRow('Cancellation Fee (20%)', '₹$fee', AtithyaColors.errorRed),
                    const SizedBox(height: 8),
                    _cancelFeeRow('Refund Amount', '₹$refund', const Color(0xFF4CAF50)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Refunds are processed within 5–7 business days.',
                  style: AtithyaTypography.caption.copyWith(
                      color: AtithyaColors.ashWhite.withValues(alpha: 0.45), fontSize: 10),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AtithyaColors.darkSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                        ),
                        child: Center(child: Text(_locale.t('it.keep'),
                            style: AtithyaTypography.labelSmall.copyWith(
                                color: AtithyaColors.parchment, letterSpacing: 2))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AtithyaColors.errorRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AtithyaColors.errorRed.withValues(alpha: 0.5)),
                        ),
                        child: Center(child: Text(_locale.t('it.cancel'),
                            style: AtithyaTypography.labelSmall.copyWith(
                                color: AtithyaColors.errorRed, letterSpacing: 2))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final result = await ref.read(bookingProvider.notifier)
          .cancelBooking(b['_id'].toString());
      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AtithyaColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
              ),
              content: Text(
                'Booking cancelled. Refund of ₹${result['refundAmount']} will be processed.',
                style: AtithyaTypography.caption.copyWith(color: AtithyaColors.parchment),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AtithyaColors.errorRed.withValues(alpha: 0.15),
              content: Text('Cancellation failed. Please try again.',
                  style: AtithyaTypography.caption.copyWith(color: AtithyaColors.errorRed)),
            ),
          );
        }
      }
    }
  }

  Widget _cancelFeeRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AtithyaTypography.caption.copyWith(
            color: AtithyaColors.parchment.withValues(alpha: 0.7), fontSize: 11)),
        Text(value, style: AtithyaTypography.labelSmall.copyWith(
            color: valueColor, fontSize: 13)),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AtithyaColors.imperialGold.withValues(alpha: 0.7), size: 13),
        const SizedBox(width: 5),
        Text(label, style: AtithyaTypography.caption.copyWith(color: AtithyaColors.parchment, fontSize: 11.5)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LATTICE PATTERN — decorative gold grid for header background
// ─────────────────────────────────────────────────────────────────────────────
class _LatticePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AD4AF6A)
      ..strokeWidth = 0.8;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Diagonal accents
    final diag = Paint()..color = const Color(0x06D4AF6A)..strokeWidth = 0.5;
    for (double x = -size.height; x < size.width; x += step * 2) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), diag);
    }
  }
  @override bool shouldRepaint(_LatticePatternPainter _) => false;
}

// ── Plan-a-Trip launcher tab ──────────────────────────────────────────────────

class _PlanTripLauncher extends ConsumerWidget {
  const _PlanTripLauncher();

  static const _curatedRoutes = [
    {
      'key': 'royal_rajasthan',
      'icon': 'royal_rajasthan',
      'name': 'Royal Rajasthan',
      'tagline': 'Palaces, forts & desert royalty',
      'duration': '10-12 days',
      'stops': [
        {'city': 'Jaipur',    'nights': 3, 'description': 'Amber Fort & City Palace'},
        {'city': 'Jodhpur',   'nights': 2, 'description': 'The Blue City & Mehrangarh Fort'},
        {'city': 'Jaisalmer', 'nights': 2, 'description': 'Golden Fort in the Thar Desert'},
        {'city': 'Udaipur',   'nights': 3, 'description': 'City of Lakes & the Lake Palace'},
      ],
    },
    {
      'key': 'golden_triangle',
      'icon': 'golden_triangle',
      'name': 'Golden Triangle',
      'tagline': 'India\'s most iconic cultural circuit',
      'duration': '7-9 days',
      'stops': [
        {'city': 'Delhi', 'nights': 2, 'description': 'The imperial capital'},
        {'city': 'Agra',  'nights': 2, 'description': 'City of the Taj Mahal'},
        {'city': 'Jaipur','nights': 3, 'description': 'The Pink City of palaces'},
      ],
    },
    {
      'key': 'kerala_odyssey',
      'icon': 'kerala_odyssey',
      'name': 'Kerala Odyssey',
      'tagline': 'Backwaters, highlands & golden shores',
      'duration': '8-10 days',
      'stops': [
        {'city': 'Wayanad', 'nights': 2, 'description': 'Misty highlands & tribal heritage'},
        {'city': 'Alleppey','nights': 3, 'description': 'Houseboat on tranquil backwaters'},
        {'city': 'Goa',     'nights': 3, 'description': 'Sun-drenched beaches & heritage'},
      ],
    },
    {
      'key': 'himalayan_escape',
      'icon': 'himalayan_escape',
      'name': 'Himalayan Escape',
      'tagline': 'Snow peaks, valleys & mountain serenity',
      'duration': '9-11 days',
      'stops': [
        {'city': 'Manali', 'nights': 4, 'description': 'Valley of the Gods & Rohtang Pass'},
        {'city': 'Gulmarg','nights': 4, 'description': 'The Meadow of Flowers in Kashmir'},
      ],
    },
    {
      'key': 'char_dham',
      'icon': 'char_dham',
      'name': '4 Dham Yatra',
      'tagline': 'The sacred Himalayan pilgrimage',
      'duration': '14-16 days',
      'stops': [
        {'city': 'Yamunotri','nights': 2, 'description': 'Source of Yamuna river'},
        {'city': 'Gangotri', 'nights': 2, 'description': 'Origin of the Ganges'},
        {'city': 'Kedarnath','nights': 3, 'description': 'Shiva\'s high-altitude abode'},
        {'city': 'Badrinath','nights': 3, 'description': 'Vishnu\'s Himalayan sanctuary'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Build Your Own CTA ──────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const TripPlannerScreen())),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1A0E08), Color(0xFF2A1808)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(color: AtithyaColors.imperialGold.withValues(alpha: 0.12), blurRadius: 20),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [Color(0xFF2A1808), AtithyaColors.obsidian]),
                      border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                    ),
                    child: const Center(child: Icon(Icons.edit_rounded, color: AtithyaColors.imperialGold, size: 26)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Build Your Own Journey',
                            style: AtithyaTypography.cardTitle.copyWith(
                                color: AtithyaColors.pearl, fontSize: 15)),
                        const SizedBox(height: 5),
                        Text('Pick cities, set nights, browse hotels at every stop',
                            style: AtithyaTypography.caption.copyWith(
                                color: AtithyaColors.parchment.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AtithyaColors.imperialGold.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 28),

          // ── Curated Circuits ────────────────────────────────────────────
          Row(children: [
            Container(width: 3, height: 18, color: AtithyaColors.imperialGold),
            const SizedBox(width: 10),
            Text(locale.t('it.curatedCircuits'),
                style: AtithyaTypography.labelMicro.copyWith(
                    color: AtithyaColors.imperialGold, letterSpacing: 2.5)),
            const Spacer(),
            Text('Tap to preview · Save to plan',
                style: AtithyaTypography.caption.copyWith(
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.35), fontSize: 10)),
          ]),
          const SizedBox(height: 14),

          ..._curatedRoutes.asMap().entries.map((e) {
            final r = Map<String, dynamic>.from(e.value);
            final stops = r['stops'] as List;
            final cities = stops.map((s) => s['city']).join(' · ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => JourneyDetailScreen(trip: r, isPreview: true))),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AtithyaColors.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(journeyIcon(r['icon'] as String?), color: AtithyaColors.imperialGold, size: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['name'] as String,
                                style: AtithyaTypography.cardTitle.copyWith(
                                    color: AtithyaColors.pearl, fontSize: 13)),
                            const SizedBox(height: 3),
                            Text(cities,
                                style: AtithyaTypography.caption.copyWith(
                                    color: AtithyaColors.parchment.withValues(alpha: 0.5),
                                    letterSpacing: 0.3),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AtithyaColors.obsidian,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                            ),
                            child: Text(r['duration'] as String,
                                style: AtithyaTypography.caption.copyWith(
                                    color: AtithyaColors.subtleGold, fontSize: 9.5)),
                          ),
                          const SizedBox(height: 6),
                          Text('${stops.length} stops',
                              style: AtithyaTypography.caption.copyWith(
                                  color: AtithyaColors.ashWhite.withValues(alpha: 0.4), fontSize: 9.5)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: AtithyaColors.imperialGold.withValues(alpha: 0.35)),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 70 * e.key))
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.03, end: 0, curve: Curves.easeOut),
            );
          }),
        ],
      ),
    );
  }
}

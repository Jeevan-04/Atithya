import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../booking/booking_detail_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(authProvider).isAuthenticated) {
        ref.read(bookingProvider.notifier).fetchMyBookings();
      }
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime? _cin(Map b) => DateTime.tryParse(b['checkInDate']?.toString() ?? '');
  DateTime? _cout(Map b) {
    final d = DateTime.tryParse(b['checkOutDate']?.toString() ?? '');
    return d ?? _cin(b);
  }

  bool _overlapsMonth(Map b) {
    final ci = _cin(b);
    if (ci == null) return false;
    final co = _cout(b) ?? ci;
    final ms = DateTime(_focused.year, _focused.month, 1);
    final me = DateTime(_focused.year, _focused.month + 1, 0);
    // overlap if booking start ≤ monthEnd AND booking end ≥ monthStart
    final ciDay = DateTime(ci.year, ci.month, ci.day);
    final coDay = DateTime(co.year, co.month, co.day);
    return !ciDay.isAfter(me) && !coDay.isBefore(ms);
  }

  Map? _bookingForDay(DateTime d, List bookings) {
    for (final b in bookings) {
      final ci = _cin(b as Map);
      if (ci == null) continue;
      final co = _cout(b) ?? ci;
      final day = DateTime(d.year, d.month, d.day);
      final ciDay = DateTime(ci.year, ci.month, ci.day);
      final coDay = DateTime(co.year, co.month, co.day);
      if (!day.isBefore(ciDay) && !day.isAfter(coDay)) return b;
    }
    return null;
  }

  bool _isStart(DateTime d, Map b) {
    final ci = _cin(b);
    if (ci == null) return false;
    return DateTime(d.year, d.month, d.day) == DateTime(ci.year, ci.month, ci.day);
  }

  bool _isEnd(DateTime d, Map b) {
    final co = _cout(b);
    if (co == null) return false;
    return DateTime(d.year, d.month, d.day) == DateTime(co.year, co.month, co.day);
  }

  int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  String _monthName(int m) => DateFormat('MMMM').format(DateTime(2000, m));

  // Total spent (all time, Confirmed + Checked In/Out only)
  double _totalSpent(List bookings) {
    return bookings
        .where((b) => !['Cancelled'].contains(b['status']))
        .fold(0.0, (sum, b) => sum + ((b['totalAmount'] as num?) ?? 0));
  }

  // Group bookings by year-month for spending chart
  Map<String, double> _spendByMonth(List bookings) {
    final m = <String, double>{};
    for (final b in bookings) {
      if (b['status'] == 'Cancelled') continue;
      final ci = _cin(b as Map);
      if (ci == null) continue;
      final key = DateFormat('MMM yy').format(ci);
      m[key] = (m[key] ?? 0) + ((b['totalAmount'] as num?) ?? 0);
    }
    return m;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final allBookings = bookingState.bookings;
    final monthBookings = allBookings.where((b) => _overlapsMonth(b as Map)).toList();

    if (bookingState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator(
            color: AtithyaColors.imperialGold, strokeWidth: 1)),
      );
    }
    return Column(children: [
      _buildCalendar(allBookings),
      _buildGantt(monthBookings),
      _buildSpending(allBookings),
    ]);
  }


  // ── Calendar Grid ──────────────────────────────────────────────────────────

  Widget _buildCalendar(List bookings) {
    final days = _daysInMonth(_focused);
    final firstDow = DateTime(_focused.year, _focused.month, 1).weekday; // 1=Mon
    final paddedStart = firstDow - 1; // cells to skip before day 1

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Month navigator
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(
            onTap: () => setState(() => _focused = DateTime(_focused.year, _focused.month - 1)),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AtithyaColors.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.chevron_left, color: AtithyaColors.imperialGold, size: 20),
            ),
          ),
          Column(children: [
            Text(_monthName(_focused.month).toUpperCase(),
              style: AtithyaTypography.labelMicro.copyWith(
                color: AtithyaColors.imperialGold, letterSpacing: 4, fontSize: 10)),
            Text(_focused.year.toString(),
              style: AtithyaTypography.displaySmall.copyWith(fontSize: 20)),
          ]),
          GestureDetector(
            onTap: () => setState(() => _focused = DateTime(_focused.year, _focused.month + 1)),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AtithyaColors.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.chevron_right, color: AtithyaColors.imperialGold, size: 20),
            ),
          ),
        ]).animate().fadeIn(duration: 500.ms),

        const SizedBox(height: 20),

        // Weekday headers
        Row(children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) =>
          Expanded(child: Center(child: Text(d, style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.ashWhite.withValues(alpha: 0.4), fontSize: 10, letterSpacing: 1))))).toList()),

        const SizedBox(height: 8),

        // Build weeks
        ..._buildWeekRows(days, paddedStart, bookings),

        // Today marker legend
        const SizedBox(height: 12),
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(
            shape: BoxShape.circle, color: AtithyaColors.imperialGold)),
          const SizedBox(width: 6),
          Text('Today', style: AtithyaTypography.caption.copyWith(
            color: AtithyaColors.ashWhite.withValues(alpha: 0.5), fontSize: 11)),
          const SizedBox(width: 20),
          Container(width: 20, height: 8, decoration: BoxDecoration(
            color: AtithyaColors.imperialGold.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 6),
          Text('Booked', style: AtithyaTypography.caption.copyWith(
            color: AtithyaColors.ashWhite.withValues(alpha: 0.5), fontSize: 11)),
        ]),
      ]),
    );
  }

  List<Widget> _buildWeekRows(int daysInMonth, int paddedStart, List bookings) {
    final today = DateTime.now();
    final rows = <Widget>[];
    int dayOfMonth = 1 - paddedStart; // can be negative (padding cells)

    while (dayOfMonth <= daysInMonth) {
      final weekDays = <DateTime?>[];
      for (int col = 0; col < 7; col++, dayOfMonth++) {
        if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
          weekDays.add(null);
        } else {
          weekDays.add(DateTime(_focused.year, _focused.month, dayOfMonth));
        }
      }
      rows.add(_buildWeekRow(weekDays, bookings, today));
      rows.add(const SizedBox(height: 4));
    }
    return rows;
  }

  Widget _buildWeekRow(List<DateTime?> weekDays, List bookings, DateTime today) {
    // Find all booking segments in this week
    final segments = <_BookingSegment>[];
    for (final b in bookings) {
      final ci = _cin(b as Map);
      if (ci == null) continue;
      final co = _cout(b) ?? ci;
      final ciDay = DateTime(ci.year, ci.month, ci.day);
      final coDay = DateTime(co.year, co.month, co.day);

      int? segStart, segEnd;
      bool roundLeft = false, roundRight = false;
      for (int i = 0; i < 7; i++) {
        final d = weekDays[i];
        if (d == null) continue;
        final dDay = DateTime(d.year, d.month, d.day);
        if (!dDay.isBefore(ciDay) && !dDay.isAfter(coDay)) {
          segStart ??= i;
          segEnd = i;
          if (dDay == ciDay) roundLeft = true;
          if (dDay == coDay) roundRight = true;
        }
      }
      if (segStart != null && segEnd != null) {
        segments.add(_BookingSegment(
          colStart: segStart, colEnd: segEnd,
          roundLeft: roundLeft, roundRight: roundRight, booking: b,
        ));
      }
    }

    return SizedBox(
      height: 42,
      child: LayoutBuilder(builder: (ctx, constraints) {
        final cellW = constraints.maxWidth / 7;
        return Stack(children: [
          // Booking highlight layers
          for (final seg in segments)
            Positioned(
              left: seg.colStart * cellW,
              width: (seg.colEnd - seg.colStart + 1) * cellW,
              top: 4, bottom: 4,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(booking: Map<String, dynamic>.from(seg.booking)),
                )),
                child: Container(
                  decoration: BoxDecoration(
                    color: seg.booking['status'] == 'Cancelled'
                      ? AtithyaColors.ashWhite.withValues(alpha: 0.1)
                      : AtithyaColors.imperialGold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(seg.roundLeft ? 20 : 0),
                      bottomLeft: Radius.circular(seg.roundLeft ? 20 : 0),
                      topRight: Radius.circular(seg.roundRight ? 20 : 0),
                      bottomRight: Radius.circular(seg.roundRight ? 20 : 0),
                    ),
                  ),
                ),
              ),
            ),

          // Day numbers
          Row(children: List.generate(7, (i) {
            final d = weekDays[i];
            if (d == null) return const Expanded(child: SizedBox());
            final booking = _bookingForDay(d, bookings);
            final isStart = booking != null && _isStart(d, booking);
            final isEnd   = booking != null && _isEnd(d, booking);
            final isBooked = booking != null;
            final isToday  = DateTime(d.year, d.month, d.day) ==
                DateTime(today.year, today.month, today.day);
            return Expanded(child: Center(child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? AtithyaColors.imperialGold.withValues(alpha: 0.2) : Colors.transparent,
                border: isToday ? Border.all(color: AtithyaColors.imperialGold, width: 1) : null,
              ),
              child: Center(child: Text(d.day.toString(),
                style: AtithyaTypography.bodyElegant.copyWith(
                  fontSize: 13,
                  color: isToday ? AtithyaColors.imperialGold
                    : isBooked ? AtithyaColors.pearl
                    : AtithyaColors.pearl.withValues(alpha: 0.5),
                  fontWeight: (isStart || isEnd || isToday) ? FontWeight.w700 : FontWeight.w400,
                ))),
            )));
          })),
        ]);
      }),
    );
  }

  // ── Gantt ──────────────────────────────────────────────────────────────────

  Widget _buildGantt(List monthBookings) {
    if (monthBookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF111318),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
          ),
          child: Center(child: Column(children: [
            Icon(Icons.calendar_month_outlined,
              color: AtithyaColors.ashWhite.withValues(alpha: 0.3), size: 36),
            const SizedBox(height: 12),
            Text('No stays this month',
              style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite)),
          ])),
        ),
      );
    }

    final days = _daysInMonth(_focused);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section header
        Row(children: [
          Container(width: 3, height: 16, color: AtithyaColors.royalMaroon),
          const SizedBox(width: 10),
          Text('STAYS THIS MONTH', style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 9)),
        ]),

        const SizedBox(height: 16),

        ...monthBookings.asMap().entries.map((entry) {
          final b = entry.value as Map;
          final i = entry.key;
          final ci = _cin(b)!;
          final co = _cout(b) ?? ci;
          final ciDay = DateTime(ci.year, ci.month, ci.day);
          final coDay = DateTime(co.year, co.month, co.day);

          final monthStart = DateTime(_focused.year, _focused.month, 1);
          final monthEnd = DateTime(_focused.year, _focused.month, days);

          final barStart = ciDay.isBefore(monthStart) ? monthStart : ciDay;
          final barEnd = coDay.isAfter(monthEnd) ? monthEnd : coDay;

          final startFrac = (barStart.day - 1) / days;
          final endFrac = barEnd.day / days;
          final barFrac = (endFrac - startFrac).clamp(0.02, 1.0);

          final status = b['status'] as String? ?? 'Confirmed';
          final isConfirmed = status == 'Confirmed';
          final amt = (b['totalAmount'] as num?) ?? 0;
          final estate = b['estate'] as Map? ?? {};
          final images = (estate['images'] as List?)?.whereType<String>().toList() ?? [];
          final heroUrl = (estate['heroImage'] as String?) ?? (images.isNotEmpty ? images[0] : '');

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BookingDetailScreen(booking: Map<String, dynamic>.from(b)),
            )),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111318),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.14)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Estate name + status
                Row(children: [
                  if (heroUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: heroUrl, width: 44, height: 44, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(width: 44, height: 44,
                          color: AtithyaColors.darkSurface,
                          child: const Icon(Icons.castle_outlined, size: 20, color: AtithyaColors.ashWhite)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(estate['title'] ?? 'Estate', style: AtithyaTypography.displaySmall.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('d MMM').format(ci)} – ${DateFormat('d MMM').format(co)}  ·  ${co.difference(ci).inDays.clamp(1, 999)} nights',
                      style: AtithyaTypography.caption.copyWith(
                        color: AtithyaColors.ashWhite.withValues(alpha: 0.55)),
                    ),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isConfirmed ? const Color(0xFF4CAF50) : AtithyaColors.errorRed).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (isConfirmed ? const Color(0xFF4CAF50) : AtithyaColors.errorRed).withValues(alpha: 0.4)),
                      ),
                      child: Text(status.toUpperCase(), style: AtithyaTypography.labelSmall.copyWith(
                        color: isConfirmed ? const Color(0xFF4CAF50) : AtithyaColors.errorRed,
                        fontSize: 8, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 4),
                    Text('₹${NumberFormat('#,##,###').format(amt.toInt())}',
                      style: AtithyaTypography.price.copyWith(fontSize: 14, color: AtithyaColors.shimmerGold)),
                  ]),
                ]),

                const SizedBox(height: 14),

                // Gantt bar
                LayoutBuilder(builder: (ctx, constraints) {
                  final W = constraints.maxWidth;
                  return Stack(children: [
                    // Background track
                    Container(height: 8, decoration: BoxDecoration(
                      color: AtithyaColors.darkSurface, borderRadius: BorderRadius.circular(4))),
                    // Booking bar
                    Positioned(
                      left: startFrac * W,
                      width: (barFrac * W).clamp(8.0, W),
                      top: 0, bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isConfirmed
                              ? [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]
                              : [AtithyaColors.ashWhite.withValues(alpha: 0.3), AtithyaColors.ashWhite.withValues(alpha: 0.2)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ]);
                }),

                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('1', style: AtithyaTypography.caption.copyWith(
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.3), fontSize: 9)),
                  Text(days.toString(), style: AtithyaTypography.caption.copyWith(
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.3), fontSize: 9)),
                ]),
              ]),
            ).animate().fadeIn(duration: 500.ms, delay: Duration(milliseconds: 100 * i))
             .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: Duration(milliseconds: 100 * i)),
          );
        }),
      ]),
    );
  }

  // ── Spending ───────────────────────────────────────────────────────────────

  Widget _buildSpending(List allBookings) {
    final total = _totalSpent(allBookings);
    final byMonth = _spendByMonth(allBookings);
    final confirmedBookings = allBookings.where((b) => b['status'] != 'Cancelled').toList();
    final cancelledCount = allBookings.where((b) => b['status'] == 'Cancelled').length;

    if (byMonth.isEmpty) return const SizedBox.shrink();

    final maxSpend = byMonth.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section header
        Row(children: [
          Container(width: 3, height: 16, color: AtithyaColors.royalMaroon),
          const SizedBox(width: 10),
          Text('SPENDING OVERVIEW', style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 9)),
        ]),

        const SizedBox(height: 16),

        // Summary cards
        Row(children: [
          Expanded(child: _statCard('TOTAL SPENT',
            '₹${NumberFormat('#,##,###').format(total.toInt())}',
            Icons.account_balance_wallet_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('STAYS',
            confirmedBookings.length.toString(),
            Icons.hotel_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('CANCELLED',
            cancelledCount.toString(),
            Icons.cancel_outlined, danger: cancelledCount > 0)),
        ]).animate().fadeIn(duration: 600.ms),

        const SizedBox(height: 20),

        // Monthly bar chart
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF111318),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.12)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MONTHLY SPEND', style: AtithyaTypography.labelMicro.copyWith(
              color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 9)),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: byMonth.entries.map((e) {
                final frac = maxSpend > 0 ? e.value / maxSpend : 0.0;
                final isCurrent = e.key == DateFormat('MMM yy').format(_focused);
                return Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(children: [
                    // Label on top of bar
                    if (frac > 0.6)
                      Text('₹${_shortAmount(e.value)}',
                        style: AtithyaTypography.caption.copyWith(fontSize: 8, color: AtithyaColors.obsidian)),
                    Container(
                      height: 80 * frac.clamp(0.05, 1.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: isCurrent
                            ? [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]
                            : [AtithyaColors.imperialGold.withValues(alpha: 0.5), AtithyaColors.imperialGold.withValues(alpha: 0.3)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(e.key, style: AtithyaTypography.caption.copyWith(
                      fontSize: 8,
                      color: isCurrent ? AtithyaColors.imperialGold : AtithyaColors.ashWhite.withValues(alpha: 0.4))),
                  ]),
                ));
              }).toList(),
            ),
          ]),
        ).animate().fadeIn(duration: 700.ms, delay: 200.ms),

        // Per-booking breakdown
        const SizedBox(height: 20),
        ...allBookings.asMap().entries.map((entry) {
          final b = entry.value as Map;
          final i = entry.key;
          final ci = _cin(b);
          if (ci == null) return const SizedBox.shrink();
          final estate = b['estate'] as Map? ?? {};
          final amt = (b['totalAmount'] as num?) ?? 0;
          final status = b['status'] as String? ?? '';
          final isCancelled = status == 'Cancelled';

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BookingDetailScreen(booking: Map<String, dynamic>.from(b)),
            )),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111318),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: isCancelled ? 0.06 : 0.12)),
              ),
              child: Row(children: [
                Container(
                  width: 3, height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: isCancelled
                        ? [AtithyaColors.errorRed.withValues(alpha: 0.5), AtithyaColors.errorRed.withValues(alpha: 0.2)]
                        : [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(estate['title'] ?? 'Estate', style: AtithyaTypography.bodyElegant.copyWith(
                    fontSize: 13, color: isCancelled ? AtithyaColors.ashWhite.withValues(alpha: 0.5) : AtithyaColors.pearl)),
                  Text(DateFormat('MMM yyyy').format(ci), style: AtithyaTypography.caption.copyWith(
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.4), fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    isCancelled ? '— cancelled —' : '₹${NumberFormat('#,##,###').format(amt.toInt())}',
                    style: AtithyaTypography.price.copyWith(
                      fontSize: 13,
                      color: isCancelled ? AtithyaColors.ashWhite.withValues(alpha: 0.35) : AtithyaColors.shimmerGold,
                    ),
                  ),
                  if (!isCancelled)
                    Text('${_cout(b)?.difference(ci).inDays.clamp(1, 999) ?? 1}n',
                      style: AtithyaTypography.caption.copyWith(
                        color: AtithyaColors.ashWhite.withValues(alpha: 0.4), fontSize: 10)),
                ]),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AtithyaColors.ashWhite, size: 14),
              ]),
            ).animate()
             .fadeIn(duration: 500.ms, delay: Duration(milliseconds: 60 * i))
             .slideX(begin: 0.05, end: 0, duration: 400.ms, delay: Duration(milliseconds: 60 * i)),
          );
        }),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, {bool danger = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111318),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (danger ? AtithyaColors.errorRed : AtithyaColors.imperialGold).withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: danger ? AtithyaColors.errorRed : AtithyaColors.imperialGold),
        const SizedBox(height: 8),
        Text(value, style: AtithyaTypography.displaySmall.copyWith(
          fontSize: 18, color: danger ? AtithyaColors.errorRed : AtithyaColors.shimmerGold)),
        const SizedBox(height: 2),
        Text(label, style: AtithyaTypography.labelMicro.copyWith(
          color: AtithyaColors.ashWhite.withValues(alpha: 0.4), fontSize: 7, letterSpacing: 1.5)),
      ]),
    );
  }

  String _shortAmount(double amt) {
    if (amt >= 10000000) return '${(amt / 10000000).toStringAsFixed(1)}Cr';
    if (amt >= 100000) return '${(amt / 100000).toStringAsFixed(1)}L';
    if (amt >= 1000) return '${(amt / 1000).toStringAsFixed(0)}K';
    return amt.toStringAsFixed(0);
  }
}

class _BookingSegment {
  final int colStart;
  final int colEnd;
  final bool roundLeft;
  final bool roundRight;
  final Map booking;
  const _BookingSegment({
    required this.colStart,
    required this.colEnd,
    required this.roundLeft,
    required this.roundRight,
    required this.booking,
  });
}

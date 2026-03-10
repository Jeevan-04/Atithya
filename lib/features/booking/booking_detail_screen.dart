import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../providers/booking_provider.dart';
import '../dossier/dossier_screen.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _cancelling = false;

  Map<String, dynamic> get _b => widget.booking;
  Map<String, dynamic> get _estate => (_b['estate'] as Map<String, dynamic>?) ?? {};

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try { return DateFormat('EEE, d MMM yyyy').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
  }

  int _nights() {
    try {
      final ci = DateTime.parse(_b['checkInDate'].toString());
      final co = DateTime.parse(_b['checkOutDate'].toString());
      return co.difference(ci).inDays.abs().clamp(1, 999);
    } catch (_) { return 1; }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
        ),
        title: Text('Cancel Booking?', style: AtithyaTypography.displaySmall),
        content: Text(
          'A 20% cancellation fee will be deducted. Refund will be processed in 5–7 business days.',
          style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Booking', style: AtithyaTypography.labelSmall.copyWith(color: AtithyaColors.imperialGold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cancel Booking', style: AtithyaTypography.labelSmall.copyWith(color: AtithyaColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    final result = await ref.read(bookingProvider.notifier).cancelBooking(_b['_id'].toString());
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF1A1C22),
          content: Text(
            'Cancelled. Refund ₹${NumberFormat('#,##,###').format((result['refundAmount'] as num?)?.toInt() ?? 0)} in 5–7 days.',
            style: AtithyaTypography.bodyElegant,
          ),
        ));
        Navigator.pop(context, 'cancelled');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _b['status'] as String? ?? 'Confirmed';
    final isConfirmed = status == 'Confirmed';
    final statusColor = {
      'Confirmed': const Color(0xFF4CAF50),
      'Cancelled': AtithyaColors.errorRed,
      'Checked In': AtithyaColors.imperialGold,
      'Checked Out': AtithyaColors.ashWhite,
    }[status] ?? AtithyaColors.ashWhite;

    final images = (_estate['images'] as List?)?.whereType<String>().toList() ?? [];
    final heroUrl = (_estate['heroImage'] as String?) ?? (images.isNotEmpty ? images[0] : '');
    final nights = _nights();
    final amt = (_b['totalAmount'] as num?) ?? 0;
    final qrData = _b['qrData'] as String?;
    final checkIn = _fmt(_b['checkInDate']?.toString());
    final checkOut = _fmt(_b['checkOutDate']?.toString());

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AtithyaColors.obsidian,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 15),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DossierScreen(estate: _estate, index: 0),
                )),
                child: Stack(fit: StackFit.expand, children: [
                  heroUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: heroUrl, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: AtithyaColors.darkSurface,
                            child: const Icon(Icons.castle_outlined, size: 80, color: AtithyaColors.ashWhite)))
                      : Container(color: AtithyaColors.darkSurface,
                          child: const Icon(Icons.castle_outlined, size: 80, color: AtithyaColors.ashWhite)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.black26, AtithyaColors.obsidian],
                      ),
                    ),
                  ),
                  Positioned(bottom: 12, right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.open_in_new, color: Colors.white54, size: 11),
                        const SizedBox(width: 4),
                        Text('View Estate', style: AtithyaTypography.caption.copyWith(color: Colors.white54, fontSize: 10)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estate name + status ────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_estate['location'] ?? '').toString().toUpperCase(),
                            style: AtithyaTypography.labelMicro.copyWith(
                              color: AtithyaColors.imperialGold, fontSize: 9, letterSpacing: 3),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _estate['title'] ?? 'Royal Estate',
                            style: AtithyaTypography.displayMedium.copyWith(height: 1.1),
                          ),
                        ],
                      )),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 6, height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                          const SizedBox(width: 6),
                          Text(status.toUpperCase(), style: AtithyaTypography.labelSmall.copyWith(
                            color: statusColor, fontSize: 9, letterSpacing: 1.5)),
                        ]),
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms),

                  // Booking reference ─────────────────────────────────────
                  if (_b['qrData'] != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(text: _b['_id'].toString()));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: const Color(0xFF1A1C22),
                          content: Text('Booking ID copied', style: AtithyaTypography.caption),
                        ));
                      },
                      child: Row(children: [
                        Text(_b['_id']?.toString().substring(0, 12) ?? '',
                          style: AtithyaTypography.caption.copyWith(
                            color: AtithyaColors.ashWhite.withValues(alpha: 0.4),
                            letterSpacing: 1, fontSize: 10)),
                        const SizedBox(width: 4),
                        Icon(Icons.copy_outlined, size: 10,
                          color: AtithyaColors.ashWhite.withValues(alpha: 0.3)),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Dates card ────────────────────────────────────────────
                  _card(child: Column(children: [
                    Row(children: [
                      Expanded(child: _dateCol('CHECK-IN', checkIn, Icons.login_outlined)),
                      Container(width: 1, height: 56, color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
                      Expanded(child: _dateCol('CHECK-OUT', checkOut, Icons.logout_outlined)),
                    ]),
                    const SizedBox(height: 16),
                    Container(height: 1, color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
                    const SizedBox(height: 14),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _chip(Icons.nights_stay_outlined, '$nights night${nights != 1 ? 's' : ''}'),
                      _chip(Icons.people_outline, '${_b['guests'] ?? 2} guests'),
                      _chip(Icons.bed_outlined, _b['roomType']?.toString() ?? 'Deluxe'),
                    ]),
                  ])).animate().fadeIn(duration: 700.ms, delay: 100.ms),

                  const SizedBox(height: 14),

                  // ── Room details ──────────────────────────────────────────
                  _card(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('ROOM DETAILS'),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _detailRow(Icons.door_front_door_outlined, 'Room', _b['roomNumber']?.toString() ?? '—')),
                        Expanded(child: _detailRow(Icons.layers_outlined, 'Floor', _b['floorNumber']?.toString() ?? '—')),
                      ]),
                      if (_b['vehicleNumber'] != null && (_b['vehicleNumber'] as String).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _detailRow(Icons.directions_car_outlined, 'Vehicle', _b['vehicleNumber'].toString()),
                      ],
                      if (_b['specialRequest'] != null && (_b['specialRequest'] as String).isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(height: 1, color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
                        const SizedBox(height: 14),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.format_quote, color: AtithyaColors.imperialGold, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_b['specialRequest'].toString(),
                            style: AtithyaTypography.bodyElegant.copyWith(
                              color: AtithyaColors.parchment, fontStyle: FontStyle.italic, fontSize: 13))),
                        ]),
                      ],
                    ],
                  )).animate().fadeIn(duration: 700.ms, delay: 200.ms),

                  const SizedBox(height: 14),

                  // ── Payment ───────────────────────────────────────────────
                  _card(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('PAYMENT'),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('TOTAL PAID', style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.ashWhite, fontSize: 9, letterSpacing: 2)),
                          const SizedBox(height: 6),
                          Text('₹${NumberFormat('#,##,###').format(amt.toInt())}',
                            style: AtithyaTypography.price.copyWith(fontSize: 26, color: AtithyaColors.shimmerGold)),
                          Text('for $nights night${nights != 1 ? 's' : ''}',
                            style: AtithyaTypography.caption.copyWith(color: AtithyaColors.ashWhite)),
                        ]),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('PER NIGHT', style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.ashWhite, fontSize: 9, letterSpacing: 2)),
                          const SizedBox(height: 6),
                          Text('₹${NumberFormat('#,##,###').format((amt / nights).round())}',
                            style: AtithyaTypography.displaySmall.copyWith(color: AtithyaColors.pearl, fontSize: 16)),
                        ]),
                      ]),
                      if (_b['paymentId'] != null) ...[
                        const SizedBox(height: 14),
                        Container(height: 1, color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.receipt_long_outlined, color: AtithyaColors.ashWhite, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_b['paymentId'].toString(),
                            style: AtithyaTypography.caption.copyWith(
                              color: AtithyaColors.ashWhite.withValues(alpha: 0.45),
                              letterSpacing: 0.5, fontSize: 11),
                            overflow: TextOverflow.ellipsis)),
                        ]),
                      ],
                      if (_b['tenderDetails'] != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.credit_card_outlined, color: AtithyaColors.ashWhite, size: 14),
                          const SizedBox(width: 8),
                          Text(_b['tenderDetails'].toString(),
                            style: AtithyaTypography.caption.copyWith(
                              color: AtithyaColors.ashWhite.withValues(alpha: 0.45))),
                        ]),
                      ],
                    ],
                  )).animate().fadeIn(duration: 700.ms, delay: 300.ms),

                  // ── QR Code ───────────────────────────────────────────────
                  if (qrData != null && qrData.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _card(child: Column(children: [
                      _label('ENTRY QR CODE'),
                      const SizedBox(height: 4),
                      Text('Present at estate entrance',
                        style: AtithyaTypography.caption.copyWith(color: AtithyaColors.ashWhite)),
                      const SizedBox(height: 18),
                      Center(child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: QrImageView(data: qrData, size: 160, backgroundColor: Colors.white),
                      )),
                    ])).animate().fadeIn(duration: 700.ms, delay: 400.ms),
                  ],

                  // ── Cancel ────────────────────────────────────────────────
                  if (isConfirmed) ...[
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _cancelling ? null : _cancel,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AtithyaColors.errorRed.withValues(alpha: 0.4)),
                        ),
                        child: Center(child: _cancelling
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AtithyaColors.errorRed))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.cancel_outlined, color: AtithyaColors.errorRed, size: 16),
                              const SizedBox(width: 8),
                              Text('CANCEL BOOKING', style: AtithyaTypography.labelSmall.copyWith(
                                color: AtithyaColors.errorRed, letterSpacing: 3)),
                            ])),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF111318),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.12)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: AtithyaTypography.labelMicro.copyWith(
    color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 9));

  Widget _dateCol(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Column(children: [
      Icon(icon, size: 14, color: AtithyaColors.imperialGold),
      const SizedBox(height: 6),
      Text(label, style: AtithyaTypography.labelMicro.copyWith(
        color: AtithyaColors.ashWhite, fontSize: 8, letterSpacing: 2)),
      const SizedBox(height: 6),
      Text(value, style: AtithyaTypography.bodyElegant.copyWith(fontSize: 12, height: 1.35),
        textAlign: TextAlign.center),
    ]),
  );

  Widget _chip(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AtithyaColors.imperialGold),
    const SizedBox(width: 5),
    Text(text, style: AtithyaTypography.caption.copyWith(fontSize: 12)),
  ]);

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Icon(icon, size: 15, color: AtithyaColors.imperialGold),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AtithyaTypography.labelMicro.copyWith(
          color: AtithyaColors.ashWhite.withValues(alpha: 0.4), fontSize: 8, letterSpacing: 1.5)),
        const SizedBox(height: 2),
        Text(value, style: AtithyaTypography.bodyElegant.copyWith(fontSize: 14)),
      ]),
    ]),
  );
}

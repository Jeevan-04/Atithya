import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/colors.dart';
import '../../../core/typography.dart';

class BookingQRScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingQRScreen({super.key, required this.booking});

  String get _qrData => booking['qrData'] ?? '';
  String get _ref => booking['bookingRef'] ?? booking['_id'] ?? 'N/A';
  String get _room => booking['roomNumber'] ?? '--';
  String get _floor => booking['floorNumber']?.toString() ?? '1';
  String get _guest => booking['guestName'] ?? 'Guest';
  String get _estate => booking['estateName'] ?? 'Estate';
  String get _checkIn => booking['formattedCheckIn'] ??
      (booking['checkIn'] != null ? _formatDate(booking['checkIn'].toString()) : '--');
  String get _checkOut => booking['formattedCheckOut'] ??
      (booking['checkOut'] != null ? _formatDate(booking['checkOut'].toString()) : '--');

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AtithyaColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: AtithyaColors.pearl, size: 16),
                      ),
                    ),
                    const Spacer(),
                    Text('Your Access Pass', style: AtithyaTypography.cardTitle.copyWith(
                      color: AtithyaColors.imperialGold, fontSize: 14, letterSpacing: 2,
                    )),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Celebration ───────────────────────────────────────────────
              Text('✦ Booking Confirmed ✦',
                style: AtithyaTypography.heroTitle.copyWith(
                  color: AtithyaColors.shimmerGold, fontSize: 22, letterSpacing: 1.5,
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
              const SizedBox(height: 6),
              Text(_estate,
                style: AtithyaTypography.bodyText.copyWith(color: AtithyaColors.parchment, fontSize: 13),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 800.ms),

              const SizedBox(height: 32),

              // ── QR Card ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: AtithyaColors.darkSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AtithyaColors.imperialGold.withOpacity(0.12),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Gold corner brackets
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          _cornerBracket(false, false),
                          _cornerBracket(true, false),
                        ]),
                        const SizedBox(height: 12),

                        // QR Code
                        _qrData.isNotEmpty
                            ? QrImageView(
                                data: _qrData,
                                version: QrVersions.auto,
                                size: 200,
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              )
                            : Container(
                                width: 200, height: 200,
                                color: Colors.white,
                                child: const Center(child: CircularProgressIndicator()),
                              ),

                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          _cornerBracket(false, true),
                          _cornerBracket(true, true),
                        ]),

                        const SizedBox(height: 20),
                        _divider(),
                        const SizedBox(height: 20),

                        // Booking details grid
                        Row(children: [
                          Expanded(child: _infoTile('BOOKING REF', _ref)),
                          Expanded(child: _infoTile('ROOM', 'Room $_room')),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _infoTile('FLOOR', 'Floor $_floor')),
                          Expanded(child: _infoTile('GUEST', _guest)),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _infoTile('CHECK-IN', _checkIn)),
                          Expanded(child: _infoTile('CHECK-OUT', _checkOut)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 1000.ms).scale(begin: const Offset(0.9, 0.9)),

              const SizedBox(height: 28),

              // ── Usage Instructions ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text('SHOW THIS CODE AT', style: AtithyaTypography.cardTitle.copyWith(
                      color: AtithyaColors.parchment, fontSize: 11, letterSpacing: 2,
                    )),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _accessPoint(Icons.directions_car_outlined, 'Gate'),
                        _accessPoint(Icons.desk_outlined, 'Desk'),
                        _accessPoint(Icons.elevator_outlined, 'Lift'),
                        _accessPoint(Icons.door_back_door_outlined, 'Room'),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 1200.ms),

              const SizedBox(height: 32),

              // ── Actions ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _ref));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Booking ref copied', style: AtithyaTypography.bodyText.copyWith(fontSize: 13)),
                          backgroundColor: AtithyaColors.surfaceElevated,
                        ));
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Ref'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AtithyaColors.imperialGold,
                        side: const BorderSide(color: AtithyaColors.imperialGold),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Share.share('My Atithya booking at $_estate\nBooking Ref: $_ref\nCheck-in: $_checkIn\nRoom: $_room, Floor: $_floor');
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtithyaColors.imperialGold,
                        foregroundColor: AtithyaColors.obsidian,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text('View in Itineraries →',
                      style: AtithyaTypography.bodyText.copyWith(
                        color: AtithyaColors.parchment, fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cornerBracket(bool right, bool bottom) {
    return SizedBox(
      width: 20, height: 20,
      child: CustomPaint(painter: _BracketPainter(right: right, bottom: bottom)),
    );
  }

  Widget _divider() => Row(children: [
    const Expanded(child: Divider(color: Color(0x33D4AF6A))),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text('✦', style: TextStyle(color: AtithyaColors.imperialGold.withOpacity(0.5), fontSize: 10)),
    ),
    const Expanded(child: Divider(color: Color(0x33D4AF6A))),
  ]);

  Widget _infoTile(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: AtithyaColors.parchment.withOpacity(0.6), fontSize: 10, letterSpacing: 1.2)),
    const SizedBox(height: 4),
    Text(value, style: AtithyaTypography.cardTitle.copyWith(color: AtithyaColors.pearl, fontSize: 13)),
  ]);

  Widget _accessPoint(IconData icon, String label) => Column(children: [
    Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: AtithyaColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.25)),
      ),
      child: Icon(icon, color: AtithyaColors.imperialGold, size: 22),
    ),
    const SizedBox(height: 6),
    Text(label, style: TextStyle(color: AtithyaColors.parchment, fontSize: 11)),
  ]);
}

class _BracketPainter extends CustomPainter {
  final bool right;
  final bool bottom;

  _BracketPainter({required this.right, required this.bottom});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtithyaColors.imperialGold
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    if (!right && !bottom) {
      path.moveTo(0, size.height); path.lineTo(0, 0); path.lineTo(size.width, 0);
    } else if (right && !bottom) {
      path.moveTo(0, 0); path.lineTo(size.width, 0); path.lineTo(size.width, size.height);
    } else if (!right && bottom) {
      path.moveTo(0, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

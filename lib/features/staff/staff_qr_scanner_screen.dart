import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STAFF QR SCANNER — Gate / Desk Check-In
// ─────────────────────────────────────────────────────────────────────────────

class StaffQrScannerScreen extends StatefulWidget {
  final String location; // 'main_gate' | 'desk' | 'lift' | 'room'
  const StaffQrScannerScreen({super.key, this.location = 'main_gate'});

  @override
  State<StaffQrScannerScreen> createState() => _StaffQrScannerScreenState();
}

class _StaffQrScannerScreenState extends State<StaffQrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scanner = MobileScannerController();
  late AnimationController _scanLineCtrl;
  bool _processing = false;
  _ScanResult? _result;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanner.dispose();
    _scanLineCtrl.dispose();
    super.dispose();
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _processing = true);
    _scanner.stop();

    try {
      final data = await apiClient.post('/access/verify-qr', {
        'qrToken': barcode!.rawValue!,
        'location': widget.location,
      });

      if (!mounted) return;

      setState(() {
        _result = _ScanResult(
          allowed: data['allowed'] == true,
          alreadyCheckedIn: data['alreadyCheckedIn'] == true,
          guestName: data['guest']?['name'] ?? data['guest']?['phoneNumber'] ?? '—',
          estateName: data['estate']?['title'] ?? '—',
          roomNumber: data['booking']?['roomNumber'] ?? '—',
          roomType: data['booking']?['roomType'] ?? '—',
          status: data['booking']?['status'] ?? '—',
          tier: data['guest']?['memberTier'] ?? 'Bronze',
          message: data['error'],
          checkInDate: data['booking']?['checkInDate'],
          checkOutDate: data['booking']?['checkOutDate'],
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = _ScanResult(
          allowed: false,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      });
    }
  }

  void _rescan() {
    setState(() {
      _result = null;
      _processing = false;
    });
    _scanner.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Stack(
        children: [
          // Camera view (hidden when result shown)
          if (_result == null)
            MobileScanner(
              controller: _scanner,
              onDetect: _onQrDetected,
            )
          else
            Container(color: AtithyaColors.obsidian),

          // Dark overlay gradient
          if (_result == null)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xAA080A0E), Colors.transparent, Color(0xAA080A0E)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

          // ─── Header ────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AtithyaColors.obsidian.withValues(alpha: 0.8),
                        border: Border.all(
                            color: AtithyaColors.imperialGold.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: AtithyaColors.pearl, size: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GATE SCANNER',
                            style: AtithyaTypography.labelMicro.copyWith(
                                color: AtithyaColors.imperialGold, letterSpacing: 4)),
                        Text(_locationLabel(widget.location),
                            style: AtithyaTypography.caption.copyWith(
                                color: AtithyaColors.ashWhite.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  if (_result == null)
                    GestureDetector(
                      onTap: () {
                        _scanner.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _torchOn
                              ? AtithyaColors.imperialGold.withValues(alpha: 0.2)
                              : AtithyaColors.obsidian.withValues(alpha: 0.8),
                          border: Border.all(
                              color: AtithyaColors.imperialGold.withValues(alpha: 0.35)),
                        ),
                        child: Icon(
                          _torchOn ? Icons.flash_on : Icons.flash_off,
                          color: _torchOn ? AtithyaColors.imperialGold : AtithyaColors.ashWhite,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Scan Frame ─────────────────────────────────────────────────────
          if (_result == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // QR Frame
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      children: [
                        // Corner decorations
                        ..._buildCorners(),
                        // Animated scan line
                        AnimatedBuilder(
                          animation: _scanLineCtrl,
                          builder: (_, __) {
                            return Positioned(
                              top: _scanLineCtrl.value * 220 + 20,
                              left: 20,
                              right: 20,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.transparent,
                                    AtithyaColors.imperialGold.withValues(alpha: 0.8),
                                    AtithyaColors.shimmerGold,
                                    AtithyaColors.imperialGold.withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Align QR code within the frame',
                      style: AtithyaTypography.caption.copyWith(
                          color: AtithyaColors.pearl.withValues(alpha: 0.7))),
                  const SizedBox(height: 8),
                  if (_processing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AtithyaColors.imperialGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AtithyaColors.imperialGold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('Verifying…',
                              style: AtithyaTypography.caption.copyWith(
                                  color: AtithyaColors.imperialGold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // ─── Result Panel ────────────────────────────────────────────────────
          if (_result != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildResultPanel(_result!),
            ),
        ],
      ),
    );
  }

  Widget _buildResultPanel(_ScanResult r) {
    final isAllowed = r.allowed;
    final isAlready = r.alreadyCheckedIn;
    final Color accentColor = isAlready
        ? const Color(0xFFFFC107)   // amber — already checked in
        : isAllowed
            ? const Color(0xFF4CAF50)  // green — access granted
            : AtithyaColors.errorRed;  // red — access denied

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1014),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: accentColor.withValues(alpha: 0.5), width: 2),
        ),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 40),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
              border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 2),
            ),
            child: Icon(
              isAlready ? Icons.replay_rounded : isAllowed ? Icons.check_rounded : Icons.close_rounded,
              color: accentColor,
              size: 36,
            ),
          ).animate().scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            isAlready ? 'ALREADY CHECKED IN' : isAllowed ? 'ACCESS GRANTED' : 'ACCESS DENIED',
            style: AtithyaTypography.labelMicro.copyWith(
                color: accentColor, letterSpacing: 4, fontSize: 13),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 4),
          if (isAlready)
            Text('Guest is already inside the property',
                style: AtithyaTypography.caption.copyWith(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.7))),
          if (r.message != null && !isAllowed && !isAlready)
            Text(r.message!, style: AtithyaTypography.caption.copyWith(
                color: AtithyaColors.errorRed.withValues(alpha: 0.8))),
          const SizedBox(height: 20),
          if (isAllowed || isAlready) ...[  // show guest card for both ACCESS GRANTED and ALREADY CHECKED IN
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AtithyaColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.18)),
              ),
              child: Column(
                children: [
                  // Guest name large
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AtithyaColors.royalMaroon, AtithyaColors.deepMaroon],
                          ),
                        ),
                        child: const Icon(Icons.person, color: AtithyaColors.imperialGold, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.guestName ?? '—',
                                style: AtithyaTypography.displaySmall.copyWith(fontSize: 16)),
                            Text(r.tier ?? 'Bronze',
                                style: AtithyaTypography.caption.copyWith(
                                    color: AtithyaColors.imperialGold.withValues(alpha: 0.7),
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: AtithyaColors.imperialGold.withValues(alpha: 0.08)),
                  const SizedBox(height: 14),
                  _resultRow('Estate', r.estateName ?? '—'),
                  const SizedBox(height: 8),
                  _resultRow('Room', '${r.roomType} · ${r.roomNumber}'),
                  const SizedBox(height: 8),
                  _resultRow('Status', r.status?.toUpperCase() ?? '—', valueColor: accentColor),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
          ],
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _rescan,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold, AtithyaColors.burnishedGold],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: AtithyaColors.imperialGold.withValues(alpha: 0.3), blurRadius: 16),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1A0E00), size: 20),
                  const SizedBox(width: 10),
                  Text('SCAN NEXT GUEST',
                      style: AtithyaTypography.labelSmall.copyWith(
                          color: const Color(0xFF1A0E00), letterSpacing: 3, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AtithyaTypography.caption.copyWith(
            color: AtithyaColors.ashWhite.withValues(alpha: 0.45), fontSize: 11)),
        Text(value, style: AtithyaTypography.labelSmall.copyWith(
            color: valueColor ?? AtithyaColors.parchment, fontSize: 12)),
      ],
    );
  }

  List<Widget> _buildCorners() {
    // Gold corner brackets
    const d = 30.0;
    const w = 3.0;
    final c = AtithyaColors.imperialGold;
    return [
      // Top-left
      Positioned(top: 0, left: 0, child: _corner(c, d, w, top: true, left: true)),
      // Top-right
      Positioned(top: 0, right: 0, child: _corner(c, d, w, top: true, left: false)),
      // Bottom-left
      Positioned(bottom: 0, left: 0, child: _corner(c, d, w, top: false, left: true)),
      // Bottom-right
      Positioned(bottom: 0, right: 0, child: _corner(c, d, w, top: false, left: false)),
    ];
  }

  Widget _corner(Color c, double d, double w, {required bool top, required bool left}) {
    return SizedBox(
      width: d, height: d,
      child: CustomPaint(
        painter: _CornerPainter(c, w, top: top, left: left),
      ),
    );
  }

  String _locationLabel(String loc) {
    switch (loc) {
      case 'main_gate': return 'Main entrance check-in';
      case 'desk': return 'Front desk verification';
      case 'lift': return 'Lift access control';
      case 'room': return 'Room door unlock';
      default: return 'Access point scan';
    }
  }
}

// ─── Data Model ─────────────────────────────────────────────────────────────

class _ScanResult {
  final bool allowed;
  final bool alreadyCheckedIn;
  final String? guestName;
  final String? estateName;
  final String? roomNumber;
  final String? roomType;
  final String? status;
  final String? tier;
  final String? message;
  final dynamic checkInDate;
  final dynamic checkOutDate;

  const _ScanResult({
    required this.allowed,
    this.alreadyCheckedIn = false,
    this.guestName,
    this.estateName,
    this.roomNumber,
    this.roomType,
    this.status,
    this.tier,
    this.message,
    this.checkInDate,
    this.checkOutDate,
  });
}

// ─── Corner Painter ─────────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool top;
  final bool left;

  const _CornerPainter(this.color, this.strokeWidth,
      {required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x1 = left ? 0.0 : size.width;
    final y1 = top ? 0.0 : size.height;

    final x2 = left ? size.width : 0.0;
    final y2 = top ? size.height : 0.0;

    canvas.drawLine(Offset(x1, y1), Offset(x2, y1), paint); // horizontal
    canvas.drawLine(Offset(x1, y1), Offset(x1, y2), paint); // vertical
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

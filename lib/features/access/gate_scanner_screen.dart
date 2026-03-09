import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/colors.dart';
import '../../../core/typography.dart';
import '../../../providers/access_provider.dart';
import '../../../providers/auth_provider.dart';

class GateScannerScreen extends ConsumerStatefulWidget {
  const GateScannerScreen({super.key});

  @override
  ConsumerState<GateScannerScreen> createState() => _GateScannerScreenState();
}

class _GateScannerScreenState extends ConsumerState<GateScannerScreen> {
  MobileScannerController? _controller;
  bool _torchOn = false;
  bool _processing = false;
  final _vehicleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  String _myRole() {
    final user = ref.read(authProvider).user;
    return user?['role'] ?? 'gate_staff';
  }

  String _accessType() {
    switch (_myRole()) {
      case 'gate_staff': return 'gate';
      case 'desk_staff': return 'desk';
      default: return 'gate';
    }
  }

  Future<void> _onBarcode(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _processing = true);
    _controller?.stop();

    final result = await ref.read(accessProvider.notifier).verifyQR(raw, _accessType());

    if (!mounted) return;
    setState(() => _processing = false);

    _showResultSheet(result);
  }

  void _showResultSheet(dynamic result) {
    final ok = result?.success ?? false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultSheet(
        result: result,
        isGate: _myRole() == 'gate_staff',
        vehicleCtrl: _vehicleCtrl,
        onDriveIn: (bookingId, vehicle) async {
          await ref.read(accessProvider.notifier).approveDriveIn(bookingId, vehicle);
          if (mounted) Navigator.pop(context);
        },
        onDismiss: () {
          Navigator.pop(context);
          _controller?.start();
          ref.read(accessProvider.notifier).clearScanResult();
        },
      ),
    );
    if (!ok) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _controller?.start();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Stack(
        children: [
          // ── Camera ───────────────────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcode,
          ),

          // ── Overlay ──────────────────────────────────────────────────────
          _CameraOverlay(),

          // ── Processing Spinner ───────────────────────────────────────────
          if (_processing)
            Container(
              color: AtithyaColors.obsidian.withOpacity(0.7),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: AtithyaColors.imperialGold),
                  const SizedBox(height: 16),
                  Text('Verifying Access...', style: AtithyaTypography.bodyText.copyWith(
                    color: AtithyaColors.pearl,
                  )),
                ]),
              ),
            ),

          // ── Header ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AtithyaColors.obsidian.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: AtithyaColors.pearl, size: 16),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AtithyaColors.obsidian.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.3)),
                    ),
                    child: Text(
                      _myRole() == 'gate_staff' ? '🚗 Gate Scanner' : '🛎️ Desk Scanner',
                      style: AtithyaTypography.cardTitle.copyWith(
                        color: AtithyaColors.imperialGold, fontSize: 12, letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _controller?.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _torchOn
                            ? AtithyaColors.imperialGold.withOpacity(0.3)
                            : AtithyaColors.obsidian.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.3)),
                      ),
                      child: Icon(
                        _torchOn ? Icons.flash_on : Icons.flash_off,
                        color: _torchOn ? AtithyaColors.imperialGold : AtithyaColors.pearl,
                        size: 18,
                      ),
                    ),
                  ),
                ]),
              ),
              const Spacer(),
              // ── Bottom instruction ────────────────────────────────────────
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AtithyaColors.obsidian.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.2)),
                ),
                child: Text(
                  "Point camera at guest's QR code",
                  style: AtithyaTypography.bodyText.copyWith(color: AtithyaColors.parchment, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Camera Viewfinder Overlay ─────────────────────────────────────────────────

class _CameraOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _OverlayPainter(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const sq = 250.0;

    final darkPaint = Paint()..color = const Color(0x99000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cy - sq / 2), darkPaint);
    canvas.drawRect(Rect.fromLTWH(0, cy + sq / 2, size.width, size.height - cy - sq / 2), darkPaint);
    canvas.drawRect(Rect.fromLTWH(0, cy - sq / 2, cx - sq / 2, sq), darkPaint);
    canvas.drawRect(Rect.fromLTWH(cx + sq / 2, cy - sq / 2, size.width - cx - sq / 2, sq), darkPaint);

    final cornerPaint = Paint()
      ..color = const Color(0xFFD4AF6A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const cl = 30.0;
    final l = cx - sq / 2;
    final t = cy - sq / 2;
    final r = cx + sq / 2;
    final b = cy + sq / 2;

    // Top-left
    canvas.drawPath(Path()..moveTo(l, t + cl)..lineTo(l, t)..lineTo(l + cl, t), cornerPaint);
    // Top-right
    canvas.drawPath(Path()..moveTo(r - cl, t)..lineTo(r, t)..lineTo(r, t + cl), cornerPaint);
    // Bottom-left
    canvas.drawPath(Path()..moveTo(l, b - cl)..lineTo(l, b)..lineTo(l + cl, b), cornerPaint);
    // Bottom-right
    canvas.drawPath(Path()..moveTo(r - cl, b)..lineTo(r, b)..lineTo(r, b - cl), cornerPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Result Sheet ──────────────────────────────────────────────────────────────

class _ResultSheet extends StatefulWidget {
  final dynamic result;
  final bool isGate;
  final TextEditingController vehicleCtrl;
  final Function(String, String) onDriveIn;
  final VoidCallback onDismiss;

  const _ResultSheet({
    required this.result,
    required this.isGate,
    required this.vehicleCtrl,
    required this.onDriveIn,
    required this.onDismiss,
  });

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet> {
  bool _showDriveIn = false;

  Color get _bgColor => widget.result?.success == true
      ? AtithyaColors.success.withOpacity(0.08)
      : AtithyaColors.errorRed.withOpacity(0.08);

  Color get _accentColor => widget.result?.success == true
      ? AtithyaColors.success
      : const Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final ok = r?.success == true;

    return Container(
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: _accentColor.withOpacity(0.4), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(
          color: AtithyaColors.parchment.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(height: 24),

        // Status Icon
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: _accentColor, width: 2),
          ),
          child: Icon(
            ok ? Icons.check_rounded : Icons.close_rounded,
            color: _accentColor, size: 36,
          ),
        ).animate().scale(duration: 300.ms),

        const SizedBox(height: 16),
        Text(
          ok ? 'ACCESS GRANTED' : 'ACCESS DENIED',
          style: AtithyaTypography.heroTitle.copyWith(
            color: _accentColor, fontSize: 18, letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(r?.message ?? '', style: AtithyaTypography.bodyText.copyWith(
          color: AtithyaColors.parchment, fontSize: 13,
        ), textAlign: TextAlign.center),

        if (ok && r?.guestName != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AtithyaColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.2)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _chip(r?.memberTier ?? 'Bronze', Icons.star_rounded),
                Text(r?.guestName ?? '', style: AtithyaTypography.cardTitle.copyWith(
                  color: AtithyaColors.pearl, fontSize: 15,
                )),
                _tierBadge(r?.memberTier ?? 'Bronze'),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _info('ROOM', 'Room ${r?.roomNumber ?? "--"}')),
                Expanded(child: _info('FLOOR', 'Floor ${r?.floorNumber ?? "--"}')),
                Expanded(child: _info('CHECK-OUT', r?.checkOut?.split('T').first ?? '--')),
              ]),
              if (r?.addOns.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 6, children: (r?.addOns as List<String>? ?? [])
                    .map((a) => _addOnChip(a)).toList()),
              ],
            ]),
          ),
        ],

        // Drive-in section (gate staff only)
        if (ok && widget.isGate && !_showDriveIn) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showDriveIn = true),
            icon: const Icon(Icons.directions_car, size: 18),
            label: const Text('Register Drive-In'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AtithyaColors.imperialGold,
              side: const BorderSide(color: AtithyaColors.imperialGold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],

        if (_showDriveIn) ...[
          const SizedBox(height: 16),
          TextField(
            controller: widget.vehicleCtrl,
            style: AtithyaTypography.bodyText.copyWith(color: AtithyaColors.pearl),
            decoration: InputDecoration(
              labelText: 'Vehicle Number',
              labelStyle: TextStyle(color: AtithyaColors.parchment.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AtithyaColors.imperialGold.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AtithyaColors.imperialGold.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AtithyaColors.imperialGold),
              ),
              prefixIcon: const Icon(Icons.directions_car, color: AtithyaColors.imperialGold),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onDriveIn(r?.bookingRef ?? '', widget.vehicleCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AtithyaColors.imperialGold,
                foregroundColor: AtithyaColors.obsidian,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Approve Drive-In'),
            ),
          ),
        ],

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.onDismiss,
            child: Text('Scan Next', style: AtithyaTypography.bodyText.copyWith(
              color: AtithyaColors.parchment, fontSize: 14,
            )),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AtithyaColors.imperialGold.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AtithyaColors.imperialGold, size: 12),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: AtithyaColors.imperialGold, fontSize: 11)),
    ]),
  );

  Widget _tierBadge(String tier) {
    final colors = {
      'Bronze': const Color(0xFFCD7F32),
      'Silver': const Color(0xFFC0C0C0),
      'Gold': const Color(0xFFFFD700),
      'Platinum': const Color(0xFFE5E4E2),
      'Royal': const Color(0xFFD4AF6A),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[tier] ?? AtithyaColors.imperialGold).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors[tier] ?? AtithyaColors.imperialGold, width: 0.8),
      ),
      child: Text(tier, style: TextStyle(
        color: colors[tier] ?? AtithyaColors.imperialGold,
        fontSize: 10, fontWeight: FontWeight.w600,
      )),
    );
  }

  Widget _info(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: AtithyaColors.parchment.withOpacity(0.6), fontSize: 9, letterSpacing: 1)),
    const SizedBox(height: 2),
    Text(value, style: AtithyaTypography.cardTitle.copyWith(color: AtithyaColors.pearl, fontSize: 12)),
  ]);

  Widget _addOnChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AtithyaColors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.2)),
    ),
    child: Text(label, style: TextStyle(color: AtithyaColors.parchment, fontSize: 10)),
  );
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/network/api_client.dart';
import '../shell/app_shell.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> estate;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final String roomType;
  final String specialRequest;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.estate,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.roomType,
    required this.specialRequest,
    required this.totalAmount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with TickerProviderStateMixin {
  int _selectedMethod = 0; // 0=Card, 1=UPI, 2=Net Banking, 3=Black
  bool _isFlipped = false;
  bool _isProcessing = false;
  bool _isSuccess = false;

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  late AnimationController _confettiCtrl;
  late AnimationController _successCtrl;

  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController(text: '');
  final _upiCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(text: 'Maharaj Jeevan');

  final _methods = [
    ('Credit / Debit Card', Icons.credit_card_outlined),
    ('UPI Payment', Icons.account_balance_wallet_outlined),
    ('Net Banking', Icons.account_balance_outlined),
    ('Centurion Black', Icons.diamond_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _flipAnim = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );

    _confettiCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _successCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Auto-select Black card for admin/elite
    final role = ref.read(authProvider).user?['role'];
    if (role == 'admin' || role == 'elite') {
      _selectedMethod = 3;
    }
    // Rebuild card preview on typing
    _cardNumberCtrl.addListener(() => setState(() {}));
    _nameCtrl.addListener(() => setState(() {}));
    _expiryCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _confettiCtrl.dispose();
    _successCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _upiCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String _rupees(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    return '₹${v.toStringAsFixed(0)}';
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    try {
      // Call payment API
      final apiClient = ApiClient();
      await apiClient.post('/payment', {
        'amount': widget.totalAmount,
        'method': _methods[_selectedMethod].$1,
      });

      // Create booking
      final bookingSuccess = await ref.read(bookingProvider.notifier).createBooking({
        'estateId': widget.estate['_id'],
        'checkInDate': widget.checkIn.toIso8601String(),
        'checkOutDate': widget.checkOut.toIso8601String(),
        'guests': widget.guests,
        'roomType': widget.roomType,
        'specialRequest': widget.specialRequest,
        'totalAmount': widget.totalAmount,
        'tenderDetails': _methods[_selectedMethod].$1,
      });

      if (bookingSuccess != null) {
        setState(() { _isProcessing = false; _isSuccess = true; });
        _confettiCtrl.forward();
        _successCtrl.forward();
      } else {
        throw Exception('Booking failed');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed. Please try again.', style: AtithyaTypography.bodyElegant),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AtithyaColors.darkSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: AtithyaColors.pearl, size: 16),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text('PAYMENT', style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.imperialGold, letterSpacing: 4)),
                      Text(_rupees(widget.totalAmount),
                          style: AtithyaTypography.price.copyWith(fontSize: 24)),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Animated Credit Card ─────────────────
                  if (_selectedMethod == 0) ...[
                    Center(child: _buildAnimatedCard()),
                    const SizedBox(height: 24),
                    _buildCardInputs(),
                  ],
                  // ── UPI ─────────────────────────────────
                  if (_selectedMethod == 1) _buildUPISection(),
                  // ── Net Banking ──────────────────────────
                  if (_selectedMethod == 2) _buildNetBankingSection(),
                  // ── Centurion Black ──────────────────────
                  if (_selectedMethod == 3) _buildBlackCardSection(),

                  const SizedBox(height: 32),

                  // Payment methods selector
                  Text('PAYMENT METHOD', style: AtithyaTypography.labelMicro.copyWith(
                      color: AtithyaColors.imperialGold, letterSpacing: 4)),
                  const SizedBox(height: 14),

                  ...List.generate(_methods.length, (i) {
                    final isActive = _selectedMethod == i;
                    final isBlack = i == 3;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedMethod = i;
                        _isFlipped = false;
                        _flipCtrl.value = 0;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isActive ? (isBlack ? AtithyaColors.deepMaroon : AtithyaColors.darkSurface) : AtithyaColors.darkSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive ? (isBlack ? AtithyaColors.imperialGold : AtithyaColors.imperialGold) : AtithyaColors.surfaceElevated,
                            width: isActive ? 1 : 0.5,
                          ),
                          gradient: isActive && isBlack ? const LinearGradient(
                            colors: [AtithyaColors.deepMaroon, Color(0xFF1A0A0F)],
                          ) : null,
                        ),
                        child: Row(
                          children: [
                            Icon(_methods[i].$2,
                                color: isActive ? AtithyaColors.imperialGold : AtithyaColors.ashWhite, size: 20),
                            const SizedBox(width: 14),
                            Text(_methods[i].$1,
                                style: AtithyaTypography.bodyElegant.copyWith(
                                    color: isActive ? AtithyaColors.pearl : AtithyaColors.cream, fontSize: 15)),
                            const Spacer(),
                            if (isActive)
                              Container(
                                width: 20, height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
                                ),
                                child: const Icon(Icons.check, color: AtithyaColors.obsidian, size: 12),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: SafeArea(
              top: false,
              child: GoldButton(
                label: 'AUTHORIZE ✦ ${_rupees(widget.totalAmount)}',
                isLoading: _isProcessing,
                onTap: _processPayment,
                height: 62,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard() {
    return GestureDetector(
      onTap: () {
        setState(() => _isFlipped = !_isFlipped);
        if (_isFlipped) _flipCtrl.forward(); else _flipCtrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (_, __) {
          final angle = _flipAnim.value;
          final showBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _cardBack(),
                  )
                : _cardFront(),
          );
        },
      ),
    );
  }

  Widget _cardFront() {
    return Container(
      width: 320, height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1C1309), Color(0xFF2E1F08), Color(0xFF4A320F)],
        ),
        border: Border.all(color: AtithyaColors.burnishedGold.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: AtithyaColors.imperialGold.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Stack(
        children: [
          // Background ornament
          Positioned(top: -20, right: -20, child: Container(
            width: 120, height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0x33C09040), Colors.transparent]),
            ),
          )),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('आतिथ्य', style: AtithyaTypography.labelGold.copyWith(fontSize: 14, letterSpacing: 2)),
                    Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
                      ),
                      child: const Icon(Icons.diamond_outlined, size: 16, color: AtithyaColors.obsidian),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                    _cardNumberCtrl.text.isEmpty ? '•••• •••• •••• ••••' : _cardNumberCtrl.text,
                    style: AtithyaTypography.displaySmall.copyWith(
                        letterSpacing: 4, fontSize: 18, color: AtithyaColors.shimmerGold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CARD HOLDER', style: AtithyaTypography.caption.copyWith(fontSize: 8, letterSpacing: 2)),
                        Text(_nameCtrl.text, style: AtithyaTypography.bodyElegant.copyWith(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EXPIRES', style: AtithyaTypography.caption.copyWith(fontSize: 8, letterSpacing: 2)),
                        Text(_expiryCtrl.text.isEmpty ? '••/••' : _expiryCtrl.text, style: AtithyaTypography.bodyElegant.copyWith(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tap hint
          Positioned(
            bottom: 8, right: 12,
            child: Text('TAP TO FLIP', style: AtithyaTypography.caption.copyWith(fontSize: 8, color: AtithyaColors.ashWhite.withValues(alpha: 0.4))),
          ),
        ],
      ),
    );
  }

  Widget _cardBack() {
    return Container(
      width: 320, height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1C1309), Color(0xFF2E1F08)],
        ),
        border: Border.all(color: AtithyaColors.burnishedGold.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(height: 38, color: const Color(0xFF1A1209)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36, color: const Color(0xFFE0D0A0),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 10),
                    child: Text('•••', style: TextStyle(color: AtithyaColors.obsidian, fontSize: 18, letterSpacing: 4)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48, height: 36, color: const Color(0xFFE0D0A0),
                  alignment: Alignment.center,
                  child: Text('CVV', style: TextStyle(color: AtithyaColors.obsidian, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInputs() {
    return Column(
      children: [
        _glassInput(_cardNumberCtrl, '1234 5678 9012 3456', Icons.credit_card_outlined, false,
            formatters: [_CardNumberFormatter()],
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _glassInput(_expiryCtrl, 'MM/YY', Icons.calendar_month_outlined, false,
                formatters: [_CardExpiryFormatter()],
                keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _glassInput(_cvvCtrl, 'CVV', Icons.lock_outline, true, onTap: () {
              setState(() { _isFlipped = true; });
              _flipCtrl.forward();
            })),
          ],
        ),
        const SizedBox(height: 12),
        _glassInput(_nameCtrl, 'Name on Card', Icons.person_outline, false),
      ],
    );
  }

  Widget _buildUPISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              color: AtithyaColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: AtithyaColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_2, color: AtithyaColors.imperialGold, size: 80),
                  ),
                ),
                const SizedBox(height: 8),
                Text('SCAN QR', style: AtithyaTypography.caption.copyWith(fontSize: 10, letterSpacing: 2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(child: Text('— OR ENTER UPI ID —', style: AtithyaTypography.caption.copyWith(letterSpacing: 3))),
        const SizedBox(height: 16),
        _glassInput(_upiCtrl, 'yourname@upi', Icons.account_balance_wallet_outlined, false),
      ],
    );
  }

  Widget _buildNetBankingSection() {
    final banks = ['HDFC Bank', 'ICICI Bank', 'SBI', 'Axis Bank', 'Kotak', 'Yes Bank'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT BANK', style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.imperialGold, letterSpacing: 4)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3,
          children: banks.map((b) => Container(
            decoration: BoxDecoration(
              color: AtithyaColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
            ),
            alignment: Alignment.center,
            child: Text(b, style: AtithyaTypography.caption.copyWith(color: AtithyaColors.cream)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildBlackCardSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1C0A10), Color(0xFF0D0508)],
        ),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: AtithyaColors.royalMaroon.withValues(alpha: 0.3), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
                ),
                child: const Icon(Icons.diamond_outlined, color: AtithyaColors.obsidian, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CENTURION BLACK', style: AtithyaTypography.labelGold.copyWith(fontSize: 15)),
                  Text('Elite Member Card', style: AtithyaTypography.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AtithyaColors.imperialGold, size: 18),
                const SizedBox(width: 12),
                Text('Instant authorization enabled', style: AtithyaTypography.bodyElegant.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _glassInput(TextEditingController ctrl, String hint, IconData icon, bool obscure,
      {VoidCallback? onTap, List<TextInputFormatter>? formatters, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: AtithyaTypography.displaySmall.copyWith(fontSize: 16, color: AtithyaColors.pearl),
        cursorColor: AtithyaColors.imperialGold,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AtithyaTypography.displaySmall.copyWith(
              fontSize: 15, color: AtithyaColors.ashWhite.withValues(alpha: 0.4)),
          prefixIcon: Icon(icon, color: AtithyaColors.imperialGold, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Stack(
        children: [
          // Gold confetti
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(_confettiCtrl.value),
              size: MediaQuery.of(context).size,
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Checkmark
                    Container(
                      width: 100, height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AtithyaColors.burnishedGold, AtithyaColors.imperialGold, AtithyaColors.shimmerGold],
                        ),
                      ),
                      child: const Icon(Icons.check, color: AtithyaColors.obsidian, size: 52),
                    ).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1),
                        duration: 600.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 40),

                    Text('SANCTUARY', style: AtithyaTypography.labelMicro.copyWith(
                        color: AtithyaColors.imperialGold, letterSpacing: 6))
                        .animate().fadeIn(duration: 800.ms, delay: 400.ms),

                    const SizedBox(height: 8),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('CONFIRMED',
                        style: AtithyaTypography.heroTitle.copyWith(fontSize: 44)),
                    ).animate().fadeIn(duration: 1000.ms, delay: 600.ms)
                     .slideY(begin: 0.2, end: 0, duration: 800.ms, delay: 600.ms),

                    const SizedBox(height: 20),

                    Text(
                      'Your royal escape has been reserved. A confirmation has been sent.',
                      style: AtithyaTypography.bodyLarge.copyWith(color: AtithyaColors.parchment),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 1000.ms, delay: 1000.ms),

                    const SizedBox(height: 12),

                    Text(
                      widget.estate['title'] ?? '',
                      style: AtithyaTypography.displayItalic,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 1000.ms, delay: 1200.ms),

                    const SizedBox(height: 60),

                    GoldButton(
                      label: 'VIEW ITINERARY',
                      onTap: () {
                        // Switch to Journeys tab (index 3) and pop to AppShell
                        ref.read(shellTabProvider.notifier).switchTo(2);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ).animate().fadeIn(duration: 800.ms, delay: 1500.ms),

                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: Text('Return to Collection →', style: AtithyaTypography.labelSmall),
                    ).animate().fadeIn(duration: 800.ms, delay: 1800.ms),
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

// ── Confetti Painter ─────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;
  late final List<_Particle> _particles;

  _ConfettiPainter(this.progress) {
    _particles = List.generate(80, (i) => _Particle(math.Random(i)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = p.x * size.width;
      final y = size.height * progress * p.speed + p.startY * size.height;
      final paint = Paint()..color = p.color.withValues(alpha: (1 - progress).clamp(0.0, 1.0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y % size.height), width: p.size, height: p.size * 2.5),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override bool shouldRepaint(_ConfettiPainter old) => true;
}

class _Particle {
  final double x, startY, speed, size;
  final Color color;

  _Particle(math.Random rng)
      : x = rng.nextDouble(),
        startY = rng.nextDouble() * -0.5,
        speed = 1.5 + rng.nextDouble() * 2,
        size = 4 + rng.nextDouble() * 6,
        color = [
          AtithyaColors.imperialGold, AtithyaColors.shimmerGold,
          AtithyaColors.roseGlow, AtithyaColors.pearl,
          AtithyaColors.burnishedGold
        ][rng.nextInt(5)];
}

// Auto-formats card number as groups of 4 digits separated by spaces: XXXX XXXX XXXX XXXX
class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final buffer = StringBuffer();

    if (digits.length == 1) {
      // If first digit > 1, auto-pad with 0 (e.g. '3' → '03/')
      if (int.parse(digits[0]) > 1) {
        buffer.write('0${digits[0]}/');
      } else {
        buffer.write(digits[0]);
      }
    } else {
      // Clamp month 01–12
      int month = int.parse(digits.substring(0, 2));
      if (month < 1) month = 1;
      if (month > 12) month = 12;
      buffer.write('${month.toString().padLeft(2, '0')}/');

      // Year: 1 or 2 digits — if 2 digits, clamp to >= current year
      if (digits.length > 2) {
        final yearRaw = digits.substring(2, digits.length.clamp(0, 4));
        if (yearRaw.length == 2) {
          final currentYY = DateTime.now().year % 100;
          int year = int.parse(yearRaw);
          if (year < currentYY) year = currentYY;
          if (year > currentYY + 10) year = currentYY + 10;
          buffer.write(year.toString().padLeft(2, '0'));
        } else {
          buffer.write(yearRaw);
        }
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buffer = StringBuffer();
    for (int i = 0; i < capped.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(capped[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

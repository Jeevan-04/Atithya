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
import '../shell/app_shell.dart';
import '../access/staff_dashboard_screen.dart';

class AuthFoyerScreen extends ConsumerStatefulWidget {
  const AuthFoyerScreen({super.key});

  @override
  ConsumerState<AuthFoyerScreen> createState() => _AuthFoyerScreenState();
}

class _AuthFoyerScreenState extends ConsumerState<AuthFoyerScreen>
    with TickerProviderStateMixin {

  // local UI state
  bool _isStaffMode = false;
  bool _showEntryPanel = false; // true = show phone/OTP/name panels

  // controllers
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();
  final _nameFocus = FocusNode();

  late AnimationController _backgroundCtrl;

  @override
  void initState() {
    super.initState();
    _backgroundCtrl = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundCtrl.dispose();
    _phoneCtrl.dispose(); _otpCtrl.dispose(); _nameCtrl.dispose(); _pinCtrl.dispose();
    _phoneFocus.dispose(); _otpFocus.dispose(); _nameFocus.dispose();
    super.dispose();
  }

  // ── Navigation helpers ─────────────────────────────────────────────────

  void _goToApp() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 1200),
      pageBuilder: (_, __, ___) => const AppShell(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child),
    ));
  }

  void _goToStaffDashboard() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (_, __, ___) => const StaffDashboardScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child),
    ));
  }

  // ── Auth actions ───────────────────────────────────────────────────────

  Future<void> _sendOTP() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) return;
    await ref.read(authProvider.notifier).sendOTP(phone);
    // Step transitions to otp via provider state
    WidgetsBinding.instance.addPostFrameCallback((_) => _otpFocus.requestFocus());
  }

  Future<void> _verifyOTP() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) return;
    await ref.read(authProvider.notifier).verifyOTP(otp);
    WidgetsBinding.instance.addPostFrameCallback((_) => _nameFocus.requestFocus());
  }

  Future<void> _completeName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await ref.read(authProvider.notifier).completeName(name);
  }

  Future<void> _staffLogin() async {
    final phone = _phoneCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (phone.isEmpty || pin.isEmpty) return;
    await ref.read(authProvider.notifier).staffLogin(phone, pin);
  }

  Future<void> _loginGuest() async {
    await ref.read(authProvider.notifier).loginAsGuest();
  }

  void _goBack() {
    final step = ref.read(authProvider).step;
    if (step == AuthStep.otp || step == AuthStep.name) {
      _otpCtrl.clear();
      ref.read(authProvider.notifier).goBack();
    } else {
      setState(() { _showEntryPanel = false; _isStaffMode = false; });
      ref.read(authProvider.notifier).clearError();
    }
  }

  // ── Shared input widget ────────────────────────────────────────────────

  Widget _buildInput(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
    TextInputType type = TextInputType.text,
    FocusNode? focusNode,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    VoidCallback? onSubmit,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.45))),
      ),
      child: TextField(
        controller: ctrl,
        focusNode: focusNode,
        obscureText: obscure,
        style: AtithyaTypography.displaySmall.copyWith(color: AtithyaColors.pearl),
        cursorColor: AtithyaColors.imperialGold,
        keyboardType: type,
        inputFormatters: formatters,
        maxLength: maxLength,
        onSubmitted: onSubmit != null ? (_) => onSubmit() : null,
        textInputAction: onSubmit != null ? TextInputAction.go : TextInputAction.done,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          hintStyle: AtithyaTypography.displaySmall.copyWith(
              color: AtithyaColors.ashWhite.withValues(alpha: 0.35)),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AtithyaColors.imperialGold, size: 18),
        ),
      ),
    );
  }

  // ── OTP boxes (6 digit visual display) ────────────────────────────────

  Widget _buildOtpBoxes(String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < value.length;
        final current = i == value.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 42, height: 52,
          decoration: BoxDecoration(
            color: filled
                ? AtithyaColors.imperialGold.withValues(alpha: 0.12)
                : AtithyaColors.surfaceElevated.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: current
                  ? AtithyaColors.imperialGold
                  : filled
                      ? AtithyaColors.burnishedGold.withValues(alpha: 0.7)
                      : AtithyaColors.imperialGold.withValues(alpha: 0.2),
              width: current ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: filled
              ? Text(value[i],
                  style: AtithyaTypography.displaySmall.copyWith(
                      color: AtithyaColors.imperialGold, fontWeight: FontWeight.w600, fontSize: 22))
              : const SizedBox.shrink(),
        );
      }),
    );
  }

  // ── Panel widgets for each step ────────────────────────────────────────

  Widget _buildPhonePanel(AuthState auth) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ELITE MEMBER ACCESS',
              style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.imperialGold, letterSpacing: 5)),
          const SizedBox(height: 20),
          _buildInput(
            _phoneCtrl, 'Mobile Number', Icons.phone_outlined,
            type: TextInputType.phone,
            focusNode: _phoneFocus,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            onSubmit: _sendOTP,
          ),
          const SizedBox(height: 20),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(auth.error!,
                  style: const TextStyle(color: Color(0xFFE53935), fontSize: 12),
                  textAlign: TextAlign.center),
            ),
          GoldButton(
            label: 'SEND OTP',
            isLoading: auth.isLoading,
            onTap: _sendOTP,
          ),
          const SizedBox(height: 12),
          _backButton(),
          const SizedBox(height: 6),
          Center(
            child: Text('Use your registered mobile number',
                style: AtithyaTypography.caption.copyWith(
                    fontSize: 9, color: AtithyaColors.ashWhite.withValues(alpha: 0.35))),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildOtpPanel(AuthState auth) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('VERIFY YOUR IDENTITY',
              style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.imperialGold, letterSpacing: 5)),
          const SizedBox(height: 6),
          Text('OTP sent to +91 ${auth.pendingPhone ?? ''}',
              style: AtithyaTypography.caption.copyWith(
                  color: AtithyaColors.parchment.withValues(alpha: 0.7))),
          const SizedBox(height: 24),

          // OTP visual boxes
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _otpCtrl,
            builder: (_, val, __) => _buildOtpBoxes(val.text),
          ),
          const SizedBox(height: 12),

          // Hidden OTP input
          SizedBox(
            height: 0,
            child: TextField(
              controller: _otpCtrl,
              focusNode: _otpFocus,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) { if (v.length == 6) _verifyOTP(); },
              decoration: const InputDecoration(
                border: InputBorder.none, counterText: ''),
              style: const TextStyle(height: 0, color: Colors.transparent),
              cursorColor: Colors.transparent,
              autofocus: true,
            ),
          ),

          // Show OTP boxes as tappable
          GestureDetector(
            onTap: () => _otpFocus.requestFocus(),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Tap above to enter OTP',
                  style: AtithyaTypography.caption.copyWith(
                      color: AtithyaColors.ashWhite.withValues(alpha: 0.45), fontSize: 10)),
            ),
          ),

          const SizedBox(height: 16),

          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(auth.error!,
                  style: const TextStyle(color: Color(0xFFE53935), fontSize: 12),
                  textAlign: TextAlign.center),
            ),

          GoldButton(
            label: auth.isLoading ? 'VERIFYING…' : 'VERIFY & ENTER',
            isLoading: auth.isLoading,
            onTap: _verifyOTP,
          ),
          const SizedBox(height: 12),
          _backButton(),

          // Dev OTP hint
          if (auth.debugOtp != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AtithyaColors.imperialGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                ),
                child: Text('Dev OTP: ${auth.debugOtp}',
                    style: AtithyaTypography.labelGold.copyWith(
                        fontSize: 12, letterSpacing: 4)),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildNamePanel(AuthState auth) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('WELCOME TO THE PALACE',
              style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.imperialGold, letterSpacing: 4)),
          const SizedBox(height: 6),
          Text('Please tell us your name to complete your profile.',
              style: AtithyaTypography.caption.copyWith(
                  color: AtithyaColors.parchment.withValues(alpha: 0.7))),
          const SizedBox(height: 22),
          _buildInput(
            _nameCtrl, 'Your Name', Icons.person_outline,
            focusNode: _nameFocus,
            onSubmit: _completeName,
          ),
          const SizedBox(height: 20),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(auth.error!,
                  style: const TextStyle(color: Color(0xFFE53935), fontSize: 12),
                  textAlign: TextAlign.center),
            ),
          GoldButton(
            label: 'ENTER THE PALACE',
            isLoading: auth.isLoading,
            onTap: _completeName,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildStaffPanel(AuthState auth) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('STAFF ACCESS',
              style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.imperialGold, letterSpacing: 6)),
          const SizedBox(height: 20),
          _buildInput(_phoneCtrl, 'Staff Phone Number', Icons.badge_outlined,
              type: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10),
          const SizedBox(height: 16),
          _buildInput(_pinCtrl, 'PIN Code', Icons.lock_outline,
              obscure: true, type: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              onSubmit: _staffLogin),
          const SizedBox(height: 20),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(auth.error!,
                  style: const TextStyle(color: Color(0xFFE53935), fontSize: 12),
                  textAlign: TextAlign.center),
            ),
          GoldButton(
            label: 'STAFF SIGN IN',
            isLoading: auth.isLoading,
            onTap: _staffLogin,
          ),
          const SizedBox(height: 12),
          _backButton(),
          const SizedBox(height: 8),
          Center(
            child: Text('Gate: 2222222222 / PIN: 2222',
                style: AtithyaTypography.caption.copyWith(
                    fontSize: 9, color: AtithyaColors.ashWhite.withValues(alpha: 0.35))),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _backButton() {
    return Center(
      child: GestureDetector(
        onTap: _goBack,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('← Back',
              style: AtithyaTypography.caption.copyWith(color: AtithyaColors.ashWhite.withValues(alpha: 0.6))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate on successful auth
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.step == AuthStep.authenticated && next.isAuthenticated) {
        final role = next.user?['role'] ?? 'elite';
        if (['gate_staff', 'desk_staff', 'manager'].contains(role)) {
          _goToStaffDashboard();
        } else {
          _goToApp();
        }
      }
    });

    // Determine which panel to show
    final step = authState.step;
    final showPanel = _showEntryPanel || step == AuthStep.otp || step == AuthStep.name;

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Animated Jali Background ──────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundCtrl,
              builder: (_, __) => CustomPaint(
                painter: _JaliPainter(phase: _backgroundCtrl.value),
              ),
            ),
          ),

          // ── Gradient overlays ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xEE080A0E), Color(0x88080A0E), Color(0x55080A0E)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33080A0E), Color(0x00080A0E), Color(0xFF080A0E)],
                stops: [0.0, 0.3, 0.85],
              ),
            ),
          ),

          // ── Left gold accent bar ──────────────────────────────────────────
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AtithyaColors.imperialGold,
                    AtithyaColors.burnishedGold,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // ── Brand mark ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✦ ATITHYA',
                                style: AtithyaTypography.labelGold.copyWith(letterSpacing: 6, fontSize: 11))
                                .animate().fadeIn(duration: 1000.ms, delay: 200.ms),
                            const SizedBox(height: 8),
                            Text('ROYAL\nESTATES',
                                style: AtithyaTypography.heroTitle.copyWith(height: 0.9))
                                .animate().fadeIn(duration: 1200.ms, delay: 400.ms)
                                .slideX(begin: -0.1, end: 0, duration: 1000.ms, delay: 400.ms),
                            const SizedBox(height: 16),
                            Text('of India',
                                style: AtithyaTypography.displayItalic.copyWith(fontSize: 22))
                                .animate().fadeIn(duration: 1200.ms, delay: 600.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Bottom panel ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!showPanel && step != AuthStep.otp && step != AuthStep.name) ...[
                              // Tagline
                              Text(
                                'Your palatial escape awaits.\nA kingdom curated for royalty.',
                                style: AtithyaTypography.bodyElegant.copyWith(
                                    color: AtithyaColors.parchment.withValues(alpha: 0.9), fontSize: 16),
                              ).animate().fadeIn(duration: 1000.ms, delay: 800.ms),
                              const SizedBox(height: 28),

                              // Elite member CTA
                              GoldButton(
                                label: 'ENTER AS ELITE MEMBER',
                                onTap: () {
                                  _phoneCtrl.clear(); _otpCtrl.clear();
                                  setState(() { _showEntryPanel = true; _isStaffMode = false; });
                                  WidgetsBinding.instance.addPostFrameCallback(
                                      (_) => _phoneFocus.requestFocus());
                                },
                              ).animate().fadeIn(duration: 800.ms, delay: 1000.ms)
                               .slideY(begin: 0.15, end: 0),
                              const SizedBox(height: 14),

                              // Guest CTA
                              GestureDetector(
                                onTap: _loginGuest,
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.35)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('Continue as Royal Guest →',
                                      style: AtithyaTypography.labelSmall.copyWith(
                                          color: AtithyaColors.cream, letterSpacing: 3, fontWeight: FontWeight.w500)),
                                ),
                              ).animate().fadeIn(duration: 800.ms, delay: 1200.ms),
                              const SizedBox(height: 14),

                              // Staff CTA
                              GestureDetector(
                                onTap: () {
                                  _phoneCtrl.clear(); _pinCtrl.clear();
                                  setState(() { _showEntryPanel = true; _isStaffMode = true; });
                                },
                                child: Container(
                                  height: 44,
                                  alignment: Alignment.center,
                                  child: Text('Staff Access →',
                                      style: AtithyaTypography.caption.copyWith(
                                          color: AtithyaColors.ashWhite.withValues(alpha: 0.6), letterSpacing: 2)),
                                ),
                              ).animate().fadeIn(duration: 800.ms, delay: 1400.ms),

                            ] else if (_isStaffMode) ...[
                              _buildStaffPanel(authState),

                            ] else if (step == AuthStep.otp) ...[
                              _buildOtpPanel(authState),

                            ] else if (step == AuthStep.name) ...[
                              _buildNamePanel(authState),

                            ] else ...[
                              // Phone input panel (idle or showEntryPanel)
                              _buildPhonePanel(authState),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indian Jali (stone lattice) background painter — unchanged, purely decorative
// ─────────────────────────────────────────────────────────────────────────────
class _JaliPainter extends CustomPainter {
  final double phase;
  const _JaliPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0A0608),
          const Color(0xFF12080C),
          AtithyaColors.obsidian,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final glowX = size.width * (0.25 + phase * 0.25);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          AtithyaColors.imperialGold.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(glowX, size.height * 0.5),
        radius: size.width * 0.6,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    final linePaint = Paint()
      ..color = AtithyaColors.imperialGold.withValues(alpha: 0.07)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    const cell = 48.0;
    final cols = (size.width / cell).ceil() + 2;
    final rows = (size.height / cell).ceil() + 2;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final cx = col * cell + (row.isOdd ? cell / 2 : 0);
        final cy = row * cell;
        _drawJaliCell(canvas, Offset(cx, cy), cell * 0.44, linePaint);
      }
    }

    final accentPaint = Paint()
      ..color = AtithyaColors.burnishedGold.withValues(alpha: 0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double d = 0; d < size.width + size.height; d += 38) {
      canvas.drawLine(Offset(d, 0), Offset(0, d), accentPaint);
    }
  }

  void _drawJaliCell(Canvas canvas, Offset center, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final outerAngle = i * math.pi / 4 - math.pi / 8;
      final innerAngle = outerAngle + math.pi / 8;
      final outerPt = Offset(
        center.dx + r * math.cos(outerAngle),
        center.dy + r * math.sin(outerAngle),
      );
      final innerPt = Offset(
        center.dx + r * 0.45 * math.cos(innerAngle),
        center.dy + r * 0.45 * math.sin(innerAngle),
      );
      if (i == 0) path.moveTo(outerPt.dx, outerPt.dy);
      else path.lineTo(outerPt.dx, outerPt.dy);
      path.lineTo(innerPt.dx, innerPt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
    canvas.drawCircle(center, r * 0.22, p);
  }

  @override
  bool shouldRepaint(_JaliPainter old) => old.phase != phase;
}



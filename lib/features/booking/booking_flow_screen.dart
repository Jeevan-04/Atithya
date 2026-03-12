import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/locale_provider.dart';
import '../payment/payment_screen.dart';
import '../auth/auth_foyer_screen.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> estate;
  const BookingFlowScreen({super.key, required this.estate});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late PageController _pageCtrl;
  LocaleState _locale = const LocaleState();

  // Step state
  DateTime _checkIn = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 12));
  int _adults = 2, _children = 0, _infants = 0;
  String _roomType = 'Deluxe';
  String _specialRequest = '';
  final TextEditingController _requestCtrl = TextEditingController();

  double _addOnsTotal = 0;
  final Set<String> _selectedAddOns = {};

  static const _addOns = [
    (icon: Icons.restaurant_menu, label: 'Private Chef Dinner', desc: '11-course Mughal feast', price: 24000.0),
    (icon: Icons.flight, label: 'Helicopter Transfer', desc: 'Bell 407 from city airport', price: 48000.0),
    (icon: Icons.spa_outlined, label: 'Royal Spa Ritual', desc: '3-hr Ayurvedic Abhyanga', price: 18000.0),
    (icon: Icons.local_florist_outlined, label: 'Floral Suite Decor', desc: 'Fresh roses & jasmine setup', price: 8000.0),
    (icon: Icons.wine_bar_outlined, label: 'Royal Vintage Bar', desc: 'Curated spirits & mocktails', price: 12000.0),
    (icon: Icons.photo_camera_outlined, label: 'Heritage Photography', desc: 'Royal portrait session', price: 15000.0),
  ];

  final _roomTypes = ['Standard', 'Deluxe', 'Royal Suite', 'Presidential'];
  final _requests = ['Honeymoon Setup', 'Anniversary Decor', 'Birthday Celebration', 'Corporate Retreat', 'Wellness Retreat'];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _requestCtrl.dispose();
    super.dispose();
  }

  int get _nights => _checkOut.difference(_checkIn).inDays;
  int get _guests => _adults + _children + _infants;
  double get _baseTotal => ((widget.estate['basePrice'] as num?) ?? 0).toDouble() * _nights;
  double get _taxes => (_baseTotal + _addOnsTotal) * 0.18;
  double get _total => _baseTotal + _addOnsTotal + _taxes;

  String _rupees(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    return '₹${v.toStringAsFixed(0)}';
  }

  void _nextStep() {
    if (_currentStep == 0) {
      _checkOverlapAndProceed();
    } else {
      _advance();
    }
  }

  void _advance() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageCtrl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuart);
    }
  }

  /// Checks for active booking overlaps before advancing from the date step.
  /// An exact back-to-back (new checkIn == existing checkOut, or vice-versa) is NOT an overlap.
  Future<void> _checkOverlapAndProceed() async {
    final existingBookings = ref.read(bookingProvider).bookings;
    final newCi = DateTime(_checkIn.year, _checkIn.month, _checkIn.day);
    final newCo = DateTime(_checkOut.year, _checkOut.month, _checkOut.day);

    final overlapping = existingBookings.where((b) {
      final bMap = b as Map;
      if (bMap['status'] == 'Cancelled') return false;
      final ci = DateTime.tryParse(bMap['checkInDate']?.toString() ?? '');
      final co = DateTime.tryParse(bMap['checkOutDate']?.toString() ?? '');
      if (ci == null || co == null) return false;
      final ciDay = DateTime(ci.year, ci.month, ci.day);
      final coDay = DateTime(co.year, co.month, co.day);
      // True overlap only — back-to-back boundaries are allowed
      return newCi.isBefore(coDay) && newCo.isAfter(ciDay);
    }).toList();

    if (overlapping.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF15151E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.25)),
          ),
          title: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: AtithyaColors.imperialGold, size: 22),
            const SizedBox(width: 10),
            Text('Dates Already Booked',
                style: AtithyaTypography.displaySmall.copyWith(fontSize: 16)),
          ]),
          content: Text(
            'You already have ${overlapping.length == 1
                ? 'an active booking'
                : '${overlapping.length} active bookings'} '
            'that overlap these dates. Are you sure you want to add another?',
            style: AtithyaTypography.bodyElegant
                .copyWith(color: AtithyaColors.ashWhite, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Go Back',
                  style: AtithyaTypography.bodyElegant
                      .copyWith(color: AtithyaColors.ashWhite.withValues(alpha: 0.6))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes, Continue',
                  style: AtithyaTypography.bodyElegant
                      .copyWith(color: AtithyaColors.imperialGold)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    _advance();
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageCtrl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuart);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    _locale = ref.watch(localeProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: AtithyaColors.obsidian,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AtithyaColors.maroonGradient,
                    ),
                    child: const Icon(Icons.lock_outline, color: AtithyaColors.imperialGold, size: 36),
                  ),
                  const SizedBox(height: 28),
                  Text(_locale.t('bk.membersOnly'), style: AtithyaTypography.displayMedium),
                  const SizedBox(height: 12),
                  Text(_locale.t('bk.signInReserve'),
                      style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  GoldButton(
                    label: _locale.t('bk.loginContinue'),
                    onTap: () => Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (_) => const AuthFoyerScreen())),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(_locale.t('com.goBack'), style: AtithyaTypography.labelSmall),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Header ────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _currentStep > 0 ? _prevStep() : Navigator.pop(context),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AtithyaColors.darkSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: AtithyaColors.pearl, size: 16),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              Text(_locale.t('bk.reservation'), style: AtithyaTypography.labelMicro.copyWith(
                                  color: AtithyaColors.imperialGold, letterSpacing: 4)),
                              const SizedBox(height: 2),
                              Text('Step ${_currentStep + 1} of 4',
                                  style: AtithyaTypography.caption),
                            ],
                          ),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Progress steps with labels
                      Row(
                        children: List.generate(4, (i) {
                          final isActive = i == _currentStep;
                          final isDone = i < _currentStep;
                          return Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      AnimatedContainer(
                                        duration: 300.ms,
                                        width: isActive ? 28 : 20, height: isActive ? 28 : 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: isDone || isActive
                                              ? const LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold])
                                              : null,
                                          color: isDone || isActive ? null : AtithyaColors.surfaceElevated,
                                          border: isActive ? null : Border.all(
                                            color: isDone ? AtithyaColors.burnishedGold : AtithyaColors.surfaceElevated),
                                        ),
                                        child: Center(
                                          child: isDone
                                              ? const Icon(Icons.check, color: AtithyaColors.obsidian, size: 12)
                                              : Text('${i + 1}', style: TextStyle(
                                                  color: isActive ? AtithyaColors.obsidian : AtithyaColors.ashWhite,
                                                  fontSize: 11, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [_locale.t('bk.datesStep'), _locale.t('bk.guests'), _locale.t('bk.extrasStep'), _locale.t('bk.reviewStep')][i],
                                        style: AtithyaTypography.labelSmall.copyWith(
                                          color: isActive ? AtithyaColors.imperialGold : AtithyaColors.ashWhite,
                                          fontSize: 9, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                                if (i < 3) Expanded(
                                  child: Container(
                                    height: 1,
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: i < _currentStep
                                            ? [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]
                                            : [AtithyaColors.surfaceElevated, AtithyaColors.surfaceElevated],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Steps ──────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                  ],
                ),
              ),

              // ── CTA Button ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: SafeArea(
                  top: false,
                  child: GoldButton(
                    label: _currentStep < 3 ? _locale.t('bk.continueBtn') : _locale.t('bk.proceedPayment'),
                    onTap: _currentStep < 3 ? _nextStep : _goToPayment,
                    height: 60,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          estate: widget.estate,
          checkIn: _checkIn,
          checkOut: _checkOut,
          guests: _guests,
          roomType: _roomType,
          specialRequest: _specialRequest,
          totalAmount: _total,
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel(_locale.t('bk.selectDates'), _locale.t('bk.whenEscape')),
          const SizedBox(height: 24),

          // Date display cards
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _checkIn,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => _datePickerTheme(child!),
                    );
                    if (d != null) setState(() => _checkIn = d);
                  },
                  child: _dateCard(_locale.t('bk.checkInLabel'), _checkIn, Icons.flight_takeoff_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _checkOut,
                      firstDate: _checkIn.add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => _datePickerTheme(child!),
                    );
                    if (d != null) setState(() => _checkOut = d);
                  },
                  child: _dateCard(_locale.t('bk.checkOutLabel'), _checkOut, Icons.flight_land_outlined),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Night count badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AtithyaColors.imperialGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.nights_stay_outlined, color: AtithyaColors.imperialGold, size: 18),
                  const SizedBox(width: 10),
                  Text("$_nights ${_nights > 1 ? _locale.t('bk.nights') : _locale.t('bk.night')} • ${_locale.t('bk.royalStay')}",
                      style: AtithyaTypography.labelSmall.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel(_locale.t('bk.guestsRoom'), _locale.t('bk.configStay')),
          const SizedBox(height: 28),

          // Guest counters
          ...[
            (_locale.t('bk.adults'), 'Age 13+', _adults, (v) => setState(() => _adults = v)),
            (_locale.t('bk.children'), 'Age 2–12', _children, (v) => setState(() => _children = v)),
            (_locale.t('bk.infants'), 'Under 2', _infants, (v) => setState(() => _infants = v)),
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _guestCounter(item.$1, item.$2, item.$3, item.$4),
          )),

          const SizedBox(height: 24),
          Text(_locale.t('bk.roomType'), style: AtithyaTypography.labelMicro.copyWith(
              color: AtithyaColors.imperialGold, letterSpacing: 4)),
          const SizedBox(height: 14),

          // Room type grid
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            children: _roomTypes.map((r) {
              final isActive = _roomType == r;
              return GestureDetector(
                onTap: () => setState(() => _roomType = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isActive ? AtithyaColors.imperialGold.withValues(alpha: 0.15) : AtithyaColors.darkSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isActive ? AtithyaColors.imperialGold : AtithyaColors.surfaceElevated),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isActive) const Icon(Icons.check_circle_outline, color: AtithyaColors.imperialGold, size: 14),
                      if (isActive) const SizedBox(width: 6),
                      Text(r, style: AtithyaTypography.caption.copyWith(
                          color: isActive ? AtithyaColors.imperialGold : AtithyaColors.cream,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel(_locale.t('bk.specialReqs'), _locale.t('bk.makeUnforgettable')),
          const SizedBox(height: 24),

          // Request chips
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _requests.map((r) {
              final isActive = _specialRequest == r;
              return GestureDetector(
                onTap: () => setState(() => _specialRequest = isActive ? '' : r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? AtithyaColors.royalMaroon.withValues(alpha: 0.6) : AtithyaColors.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isActive ? AtithyaColors.roseGlow : AtithyaColors.surfaceElevated),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive) const Icon(Icons.favorite, color: AtithyaColors.roseGlow, size: 12),
                      if (isActive) const SizedBox(width: 6),
                      Text(r, style: AtithyaTypography.caption.copyWith(
                          color: isActive ? AtithyaColors.pearl : AtithyaColors.cream)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),
          // ── Royal Enhancements ───────────────────────────────
          Row(
            children: [
              Container(width: 16, height: 1, color: AtithyaColors.imperialGold),
              const SizedBox(width: 8),
              Text(_locale.t('bk.enhancements'), style: AtithyaTypography.labelMicro.copyWith(
                color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Curated experiences to elevate your stay',
            style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite, fontSize: 12)),
          const SizedBox(height: 14),
          ...List.generate(_addOns.length, (i) {
            final addon = _addOns[i];
            final isSelected = _selectedAddOns.contains(addon.label);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedAddOns.remove(addon.label);
                  _addOnsTotal -= addon.price;
                } else {
                  _selectedAddOns.add(addon.label);
                  _addOnsTotal += addon.price;
                }
              }),
              child: AnimatedContainer(
                duration: 250.ms,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? AtithyaColors.imperialGold.withValues(alpha: 0.08) : const Color(0xFF111318),
                  border: Border.all(
                    color: isSelected ? AtithyaColors.imperialGold.withValues(alpha: 0.5) : const Color(0x22FFFFFF),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AtithyaColors.imperialGold.withValues(alpha: 0.15) : const Color(0xFF1A1C22),
                        border: Border.all(color: isSelected ? AtithyaColors.imperialGold.withValues(alpha: 0.4) : const Color(0x22FFFFFF)),
                      ),
                      child: Icon(addon.icon, color: isSelected ? AtithyaColors.imperialGold : AtithyaColors.ashWhite, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(addon.label, style: AtithyaTypography.bodyElegant.copyWith(
                            color: isSelected ? AtithyaColors.pearl : AtithyaColors.cream, fontSize: 13.5)),
                          Text(addon.desc, style: AtithyaTypography.caption.copyWith(
                            color: AtithyaColors.ashWhite, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${(addon.price ~/ 1000)}K', style: AtithyaTypography.price.copyWith(
                          fontSize: 14, color: isSelected ? AtithyaColors.shimmerGold : AtithyaColors.ashWhite)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: 250.ms,
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AtithyaColors.imperialGold : Colors.transparent,
                            border: Border.all(color: isSelected ? AtithyaColors.imperialGold : AtithyaColors.ashWhite.withValues(alpha: 0.3)),
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 12, color: AtithyaColors.obsidian) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: (i * 40).ms).fadeIn(duration: 300.ms),
            );
          }),
          const SizedBox(height: 20),
          Text(_locale.t('bk.personalNotes'), style: AtithyaTypography.labelMicro.copyWith(
              color: AtithyaColors.imperialGold, letterSpacing: 3)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AtithyaColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
            ),
            child: TextField(
              controller: _requestCtrl,
              maxLines: 4,
              style: AtithyaTypography.bodyElegant.copyWith(fontSize: 15),
              cursorColor: AtithyaColors.imperialGold,
              decoration: InputDecoration(
                hintText: 'Any specific preferences, dietary needs, or arrangements...',
                hintStyle: AtithyaTypography.bodyElegant.copyWith(
                    fontSize: 14, color: AtithyaColors.ashWhite.withValues(alpha: 0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (v) => _specialRequest = v,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    final images = (widget.estate['images'] as List?)?.whereType<String>().toList() ?? [];
    final heroUrl = images.isNotEmpty ? images.first : (widget.estate['heroImage'] ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel(_locale.t('bk.confirmPay'), _locale.t('bk.royalReview')),
          const SizedBox(height: 20),

          // Estate mini card
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(imageUrl: heroUrl, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AtithyaColors.darkSurface)),
                Container(decoration: const BoxDecoration(gradient: AtithyaColors.heroGradient)),
                Positioned(
                  bottom: 14, left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((widget.estate['city'] ?? '').toUpperCase(),
                          style: AtithyaTypography.labelMicro.copyWith(
                              color: AtithyaColors.imperialGold, fontSize: 9)),
                      Text(widget.estate['title'] ?? '',
                          style: AtithyaTypography.displaySmall.copyWith(fontSize: 18)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Summary rows
          _summaryRow(_locale.t('bk.checkIn'), '${_checkIn.day} ${_monthName(_checkIn.month)} ${_checkIn.year}'),
          _summaryRow(_locale.t('bk.checkOut'), '${_checkOut.day} ${_monthName(_checkOut.month)} ${_checkOut.year}'),
          _summaryRow(_locale.t('bk.duration'), "$_nights ${_nights > 1 ? _locale.t('bk.nights') : _locale.t('bk.night')}"),
          _summaryRow(_locale.t('bk.guests'), "$_guests Person${_guests != 1 ? 's' : ''}"),
          _summaryRow(_locale.t('bk.roomTypeLabel'), _roomType),
          if (_specialRequest.isNotEmpty) _summaryRow(_locale.t('bk.specialRequest'), _specialRequest),

          const SizedBox(height: 20),
          Container(height: 1, color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
          const SizedBox(height: 20),

          // Price breakdown
          _priceRow(_locale.t('bk.baseTariff'), "${_rupees(((widget.estate['basePrice'] as num?) ?? 0).toDouble())} × $_nights ${_locale.t('bk.nights')}", _rupees(_baseTotal)),
          if (_selectedAddOns.isNotEmpty) ...[
            ..._addOns.where((a) => _selectedAddOns.contains(a.label)).map((a) =>
              _priceRow(a.label, '', '₹${(a.price ~/ 1000)}K')),
          ],
          _priceRow(_locale.t('bk.gst'), '', _rupees(_taxes)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AtithyaColors.darkSurface, AtithyaColors.surfaceElevated],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_locale.t('bk.totalPayable'),
                    style: AtithyaTypography.labelMicro.copyWith(
                        color: AtithyaColors.imperialGold, letterSpacing: 3)),
                Text(_rupees(_total), style: AtithyaTypography.price.copyWith(fontSize: 28)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(_locale.t('bk.inclusive'),
                style: AtithyaTypography.caption),
          ),
        ],
      ),
    );
  }

  Widget _stepLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.imperialGold, letterSpacing: 4)),
        const SizedBox(height: 6),
        Text(subtitle, style: AtithyaTypography.displayMedium.copyWith(fontSize: 26)),
      ],
    );
  }

  Widget _dateCard(String label, DateTime date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AtithyaColors.imperialGold, size: 14),
              const SizedBox(width: 6),
              Text(label, style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.imperialGold, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 12),
          Text('${date.day}', style: AtithyaTypography.displayLarge.copyWith(fontSize: 40)),
          Text('${_monthName(date.month)} ${date.year}',
              style: AtithyaTypography.bodyElegant.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _guestCounter(String label, String sub, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AtithyaTypography.displaySmall.copyWith(fontSize: 16)),
              Text(sub, style: AtithyaTypography.caption),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              GestureDetector(
                onTap: value > 0 ? () => onChanged(value - 1) : null,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: value > 0 ? AtithyaColors.surfaceElevated : AtithyaColors.darkSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.remove,
                      color: value > 0 ? AtithyaColors.pearl : AtithyaColors.ashWhite.withValues(alpha: 0.3), size: 16),
                ),
              ),
              SizedBox(
                width: 40,
                child: Center(
                  child: Text('$value', style: AtithyaTypography.displaySmall.copyWith(fontSize: 22)),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.imperialGold]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: AtithyaColors.obsidian, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite, fontSize: 14)),
          Text(value, style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.cream, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String sub, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.cream, fontSize: 14)),
              if (sub.isNotEmpty)
                Text(sub, style: AtithyaTypography.caption.copyWith(fontSize: 10)),
            ],
          ),
          Text(amount, style: AtithyaTypography.labelSmall.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _datePickerTheme(Widget child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AtithyaColors.imperialGold,
          onPrimary: AtithyaColors.obsidian,
          surface: AtithyaColors.darkSurface,
          onSurface: AtithyaColors.pearl,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: AtithyaColors.deepMidnight),
      ),
      child: child,
    );
  }

  String _monthName(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m];
  }
}

import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notifications_provider.dart';
import '../admin/admin_panel_sheet.dart';
import '../auth/auth_foyer_screen.dart';
import '../concierge/concierge_modal.dart';
import '../staff/staff_qr_scanner_screen.dart';

class SanctumScreen extends ConsumerWidget {
  const SanctumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final locale = ref.watch(localeProvider);

    if (user == null) {
      return _buildGuestView(context, ref);
    }

    final role = user['role'] as String? ?? 'guest';

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AtithyaColors.obsidian,
            pinned: true,
            elevation: 0,
            toolbarHeight: 80,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Text(locale.t('san.theSanctum'),
                    style: AtithyaTypography.labelMicro.copyWith(
                        color: AtithyaColors.imperialGold, letterSpacing: 6)),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Column(
                children: [
                  // Profile hero card
                  _buildProfileCard(context, ref, user, role, locale),

                  const SizedBox(height: 28),

                  // Settings list
                  _SanctumMenuItem(
                    icon: Icons.notifications_outlined,
                    label: locale.t('san.notifications'),
                    subtitle: locale.t('san.notifSub'),
                    badge: ref.watch(notificationsProvider).unreadCount,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _NotificationsSheet(),
                    ),
                  ),
                  _SanctumMenuItem(
                    icon: Icons.language_outlined,
                    label: locale.t('san.lang'),
                    subtitle: '${locale.language} · ${locale.currency}',
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _LanguageRegionSheet(),
                    ),
                  ),
                  _SanctumMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: locale.t('san.privacy'),
                    subtitle: 'Manage your data',
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _PrivacySecuritySheet(),
                    ),
                  ),
                  _SanctumMenuItem(
                    icon: Icons.help_outline,
                    label: locale.t('san.concierge'),
                    subtitle: locale.t('san.concierge247'),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.transparent,
                      builder: (_) => const ConciergeModal(),
                    ),
                  ),

                  // Staff QR Scanner — for gate_staff, desk_staff, manager, admin
                  if (['gate_staff', 'desk_staff', 'manager', 'admin'].contains(role)) ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StaffQrScannerScreen(location: 'main_gate')),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AtithyaColors.imperialGold.withValues(alpha: 0.12),
                              AtithyaColors.burnishedGold.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AtithyaColors.obsidian,
                                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                              ),
                              child: const Icon(Icons.qr_code_scanner_rounded,
                                  color: AtithyaColors.imperialGold, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(locale.t('san.gateScanner'),
                                      style: AtithyaTypography.labelMicro.copyWith(
                                          color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 10)),
                                  Text(locale.t('san.gateScannerSub'),
                                      style: AtithyaTypography.caption.copyWith(color: AtithyaColors.parchment)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: AtithyaColors.imperialGold, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (role == 'admin') ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AdminPanelSheet(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AtithyaColors.deepMaroon, Color(0xFF1A0A10)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
                              ),
                              child: const Icon(Icons.shield_outlined, color: AtithyaColors.obsidian, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(locale.t('san.adminCentre'),
                                      style: AtithyaTypography.labelMicro.copyWith(
                                          color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 10)),
                                  Text(locale.t('san.adminCentreSub'),
                                      style: AtithyaTypography.caption.copyWith(color: AtithyaColors.parchment)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: AtithyaColors.imperialGold, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Logout
                  GestureDetector(
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthFoyerScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        border: Border.all(color: AtithyaColors.errorRed.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_outlined, color: AtithyaColors.errorRed, size: 18),
                          const SizedBox(width: 10),
                          Text(locale.t('san.depart'),
                              style: AtithyaTypography.labelSmall.copyWith(
                                  color: AtithyaColors.errorRed, letterSpacing: 4)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, Map<String, dynamic> user, String role, LocaleState locale) {
    final isAdmin = role == 'admin';
    final isElite = role == 'elite';
    final tierColor = isAdmin
        ? AtithyaColors.shimmerGold
        : isElite ? AtithyaColors.roseGlow : AtithyaColors.imperialGold;
    final tierLabel = isAdmin ? 'PALACE ADMINISTRATOR' : isElite ? 'ELITE PATRON' : 'ROYAL GUEST';
    final tierIcon = isAdmin ? Icons.shield_outlined : isElite ? Icons.star_border_rounded : Icons.person_outline;
    final displayName = (user['name'] as String?)?.isNotEmpty == true ? user['name'] as String : null;
    final email = (user['email'] as String?)?.isNotEmpty == true ? user['email'] as String : null;
    final loyaltyPoints = user['loyaltyPoints'] as int? ?? 0;
    final memberTier = user['memberTier'] as String? ?? 'Bronze';
    final foodPref = (user['foodPreference'] as String?)?.isNotEmpty == true
        ? user['foodPreference'] as String
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF111318),
            Color.lerp(const Color(0xFF111318), tierColor, 0.06)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tierColor.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(color: tierColor.withValues(alpha: 0.06), blurRadius: 32, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tierColor.withValues(alpha: 0.15), width: 8),
                ),
              ),
              Container(
                width: 86, height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 1),
                ),
              ),
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AtithyaColors.royalMaroon, const Color(0xFF0D0509)],
                  ),
                  border: Border.all(color: tierColor.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Icon(tierIcon, color: tierColor, size: 34),
              ),
              // Edit pencil
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: () => _showEditProfileSheet(context, ref, user),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AtithyaColors.surfaceElevated,
                      border: Border.all(color: tierColor.withValues(alpha: 0.6)),
                    ),
                    child: Icon(Icons.edit_outlined, color: tierColor, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name (large) or phone if no name
          if (displayName != null) ...[
            Text(displayName, style: AtithyaTypography.displayMedium.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(user['phoneNumber'] ?? '',
                style: AtithyaTypography.caption.copyWith(color: AtithyaColors.ashWhite)),
          ] else ...[
            Text(user['phoneNumber'] ?? '', style: AtithyaTypography.displayMedium.copyWith(fontSize: 21)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showEditProfileSheet(context, ref, user),
              child: Text(locale.t('san.addName'),
                  style: AtithyaTypography.caption.copyWith(
                      color: tierColor.withValues(alpha: 0.8), fontSize: 11)),
            ),
          ],
          if (email != null) ...[
            const SizedBox(height: 2),
            Text(email, style: AtithyaTypography.caption.copyWith(fontSize: 10, color: AtithyaColors.ashWhite.withValues(alpha: 0.5))),
          ],
          const SizedBox(height: 10),
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [tierColor.withValues(alpha: 0.18), tierColor.withValues(alpha: 0.06)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tierColor.withValues(alpha: 0.35)),
            ),
            child: Text('✦  $tierLabel  ✦',
                style: AtithyaTypography.labelSmall.copyWith(color: tierColor, letterSpacing: 3, fontSize: 10)),
          ),
          // Food preference badge
          if (foodPref != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AtithyaColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
              ),
              child: Text('🍽  $foodPref',
                  style: AtithyaTypography.caption.copyWith(
                      color: AtithyaColors.parchment.withValues(alpha: 0.7),
                      fontSize: 10)),
            ),
          ],
          const SizedBox(height: 20),
          Container(height: 1, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, tierColor.withValues(alpha: 0.25), Colors.transparent]))),
          const SizedBox(height: 18),
          // Stats row — real data
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem(memberTier, locale.t('san.tier'), tierColor),
              Container(width: 1, height: 36, color: tierColor.withValues(alpha: 0.15)),
              _statItem('$loyaltyPoints', locale.t('san.royalPts'), tierColor),
              Container(width: 1, height: 36, color: tierColor.withValues(alpha: 0.15)),
              _statItem(isAdmin ? 'All' : isElite ? 'Elite' : 'Open', locale.t('san.access'), tierColor),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.04, end: 0, duration: 500.ms);
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: AtithyaTypography.displaySmall.copyWith(color: color, fontSize: 18)),
        const SizedBox(height: 3),
        Text(label, style: AtithyaTypography.labelSmall.copyWith(color: Colors.white38, fontSize: 8, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildGuestView(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AtithyaColors.maroonGradient,
                ),
                child: const Icon(Icons.person_outline, color: AtithyaColors.imperialGold, size: 44),
              ),
              const SizedBox(height: 28),
              Text('You Are Exploring as Guest', style: AtithyaTypography.displayMedium),
              const SizedBox(height: 12),
              Text(
                'Login to unlock your personal sanctum, exclusive privileges, and reservation history.',
                style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.ashWhite),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              GoldButton(
                label: 'ENTER AS ELITE MEMBER',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AuthFoyerScreen())),
              ),
            ],
          ).animate().fadeIn(duration: 800.ms),
        ),
      ),
    );
  }
}

class _SanctumMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  const _SanctumMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AtithyaColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AtithyaColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AtithyaColors.imperialGold, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.cream, fontSize: 15)),
                  Text(subtitle, style: AtithyaTypography.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AtithyaColors.imperialGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badge',
                    style: const TextStyle(
                        color: AtithyaColors.obsidian,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            const Icon(Icons.arrow_forward_ios, color: AtithyaColors.ashWhite, size: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _EditProfileSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late String _foodPref;

  static const List<_FoodOption> _foodOptions = [
    _FoodOption(label: 'Non-Veg', icon: '🍖', value: 'Non-Vegetarian'),
    _FoodOption(label: 'Vegetarian', icon: '🥗', value: 'Vegetarian'),
    _FoodOption(label: 'Jain', icon: '🌱', value: 'Jain'),
    _FoodOption(label: 'Vegan', icon: '🌿', value: 'Vegan'),
    _FoodOption(label: 'Halal', icon: '☪️', value: 'Halal'),
    _FoodOption(label: 'Gluten-Free', icon: '🌾', value: 'Gluten-Free'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user['name'] as String? ?? '');
    _emailCtrl = TextEditingController(text: widget.user['email'] as String? ?? '');
    _foodPref = widget.user['foodPreference'] as String? ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(authProvider.notifier).updateProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      foodPreference: _foodPref,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final error = ref.watch(authProvider).error;
    final locale = ref.watch(localeProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF111318),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AtithyaColors.imperialGold, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AtithyaColors.imperialGold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(locale.t('san.editProfile'),
                style: AtithyaTypography.labelMicro.copyWith(
                    color: AtithyaColors.imperialGold, letterSpacing: 5)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(_nameCtrl, 'Your Name', Icons.person_outline),
                    const SizedBox(height: 16),
                    _field(_emailCtrl, 'Email Address', Icons.email_outlined,
                        type: TextInputType.emailAddress),
                    const SizedBox(height: 24),
                    // Food preference section
                    Row(
                      children: [
                        Icon(Icons.restaurant_outlined,
                            color: AtithyaColors.imperialGold.withValues(alpha: 0.7), size: 16),
                        const SizedBox(width: 8),
                        Text(locale.t('san.dietPref'),
                            style: AtithyaTypography.labelMicro.copyWith(
                                color: AtithyaColors.imperialGold.withValues(alpha: 0.8),
                                fontSize: 9, letterSpacing: 2.5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _foodOptions.map((opt) {
                        final isSelected = _foodPref == opt.value;
                        return GestureDetector(
                          onTap: () => setState(() =>
                              _foodPref = isSelected ? '' : opt.value),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AtithyaColors.imperialGold.withValues(alpha: 0.15)
                                  : AtithyaColors.darkSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AtithyaColors.imperialGold.withValues(alpha: 0.6)
                                    : AtithyaColors.imperialGold.withValues(alpha: 0.12),
                                width: isSelected ? 1.2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(opt.icon, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 6),
                                Text(opt.label,
                                    style: AtithyaTypography.caption.copyWith(
                                        color: isSelected
                                            ? AtithyaColors.imperialGold
                                            : AtithyaColors.parchment.withValues(alpha: 0.7),
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // Error + Save (pinned outside scroll)
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(error,
                    style: const TextStyle(color: Color(0xFFE53935), fontSize: 12),
                    textAlign: TextAlign.center),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
              child: GoldButton(label: locale.t('san.saveChanges'), isLoading: isLoading, onTap: _save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.4))),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: AtithyaTypography.displaySmall.copyWith(color: AtithyaColors.pearl),
        cursorColor: AtithyaColors.imperialGold,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AtithyaTypography.displaySmall
              .copyWith(color: AtithyaColors.ashWhite.withValues(alpha: 0.35)),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AtithyaColors.imperialGold, size: 18),
        ),
      ),
    );
  }
}

class _FoodOption {
  final String label;
  final String icon;
  final String value;
  const _FoodOption({required this.label, required this.icon, required this.value});
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared toggle row helper (top-level function)
// ─────────────────────────────────────────────────────────────────────────────
Widget _toggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AtithyaTypography.bodyElegant
                        .copyWith(color: AtithyaColors.cream, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AtithyaTypography.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AtithyaColors.imperialGold,
            activeTrackColor: AtithyaColors.imperialGold.withValues(alpha: 0.3),
            inactiveThumbColor: AtithyaColors.ashWhite,
            inactiveTrackColor: AtithyaColors.surfaceElevated,
          ),
        ],
      ),
    ),
  );
}

Widget _sheetHandle(String title) {
  return Column(
    children: [
      Center(
        child: Container(
          width: 36,
          height: 3,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AtithyaColors.imperialGold.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      Text(title,
          style: AtithyaTypography.labelMicro
              .copyWith(color: AtithyaColors.imperialGold, letterSpacing: 5)),
      const SizedBox(height: 20),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationsSheet extends ConsumerStatefulWidget {
  const _NotificationsSheet();
  @override
  ConsumerState<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<_NotificationsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _bookingConfirm = true;
  bool _checkinReminder = true;
  bool _offerAlerts = false;
  bool _conciergeMsg = true;
  bool _newProperties = false;
  bool _loyaltyUpdates = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
    final prefs = ref.read(authProvider).user?['notificationPrefs'] as Map? ?? {};
    _bookingConfirm = prefs['bookingConfirm'] as bool? ?? true;
    _checkinReminder = prefs['checkinReminder'] as bool? ?? true;
    _offerAlerts    = prefs['offerAlerts']    as bool? ?? false;
    _conciergeMsg   = prefs['conciergeMsg']   as bool? ?? true;
    _newProperties  = prefs['newProperties']  as bool? ?? false;
    _loyaltyUpdates = prefs['loyaltyUpdates'] as bool? ?? true;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _savePrefs() async {
    setState(() => _saving = true);
    await ref.read(authProvider.notifier).updatePreferences(
      notificationPrefs: {
        'bookingConfirm': _bookingConfirm,
        'checkinReminder': _checkinReminder,
        'offerAlerts': _offerAlerts,
        'conciergeMsg': _conciergeMsg,
        'newProperties': _newProperties,
        'loyaltyUpdates': _loyaltyUpdates,
      },
    );
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationsProvider);
    final unread = notifState.unreadCount;
    final locale = ref.watch(localeProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
        decoration: const BoxDecoration(
          color: Color(0xFF111318),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AtithyaColors.imperialGold, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle('NOTIFICATIONS'),
            // Tab bar
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: AtithyaColors.darkSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
              ),
              child: TabBar(
                controller: _tab,
                labelColor: AtithyaColors.obsidian,
                unselectedLabelColor: AtithyaColors.ashWhite,
                labelStyle: AtithyaTypography.labelMicro.copyWith(fontSize: 9, letterSpacing: 2.5),
                indicator: BoxDecoration(
                  color: AtithyaColors.imperialGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(locale.t('san.inbox')),
                        if (unread > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AtithyaColors.errorRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$unread',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(text: locale.t('san.prefs')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: TabBarView(
                controller: _tab,
                children: [
                  // ── INBOX TAB ─────────────────────────────────────────
                  _InboxTab(state: notifState),
                  // ── PREFERENCES TAB ──────────────────────────────────
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _toggleRow('Booking Confirmations', 'Instant receipts for every reservation', _bookingConfirm, (v) => setState(() => _bookingConfirm = v)),
                        _toggleRow('Check-in Reminders', '24h before your arrival', _checkinReminder, (v) => setState(() => _checkinReminder = v)),
                        _toggleRow('Exclusive Offers', 'Curated deals for your tier', _offerAlerts, (v) => setState(() => _offerAlerts = v)),
                        _toggleRow('Concierge Messages', 'AI & staff communication', _conciergeMsg, (v) => setState(() => _conciergeMsg = v)),
                        _toggleRow('New Properties', 'When estates join the collection', _newProperties, (v) => setState(() => _newProperties = v)),
                        _toggleRow('Loyalty Updates', 'Royal points & tier changes', _loyaltyUpdates, (v) => setState(() => _loyaltyUpdates = v)),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Context-aware bottom actions
            if (_tab.index == 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                child: GoldButton(
                  label: _saving ? '…' : locale.t('san.savePrefs'),
                  onTap: _saving ? null : _savePrefs,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ref.read(notificationsProvider.notifier).markAllRead(),
                        child: Container(
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.35)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(locale.t('san.markRead'),
                              style: AtithyaTypography.labelMicro.copyWith(
                                  color: AtithyaColors.imperialGold, fontSize: 9, letterSpacing: 2.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ref.read(notificationsProvider.notifier).clearAll(),
                        child: Container(
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: AtithyaColors.errorRed.withValues(alpha: 0.35)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(locale.t('san.clearAll'),
                              style: AtithyaTypography.labelMicro.copyWith(
                                  color: AtithyaColors.errorRed, fontSize: 9, letterSpacing: 2.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inbox Tab (notification list)
// ─────────────────────────────────────────────────────────────────────────────
class _InboxTab extends ConsumerWidget {
  final NotificationsState state;
  const _InboxTab({required this.state});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AtithyaColors.imperialGold),
      );
    }
    if (state.items.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              color: AtithyaColors.imperialGold.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: 12),
          Text('Your inbox is empty',
              style: AtithyaTypography.bodyElegant.copyWith(
                  color: AtithyaColors.ashWhite, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Booking confirmations & updates will appear here',
              style: AtithyaTypography.caption.copyWith(fontSize: 11)),
          const SizedBox(height: 40),
        ],
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: state.items.length,
      itemBuilder: (_, i) {
        final n = state.items[i];
        return GestureDetector(
          onTap: () => ref.read(notificationsProvider.notifier).markRead(n.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n.read
                  ? AtithyaColors.darkSurface
                  : AtithyaColors.imperialGold.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: n.read
                    ? AtithyaColors.imperialGold.withValues(alpha: 0.08)
                    : AtithyaColors.imperialGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!n.read)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AtithyaColors.imperialGold,
                    ),
                  )
                else
                  const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          style: AtithyaTypography.bodyElegant.copyWith(
                              color: n.read ? AtithyaColors.cream : AtithyaColors.imperialGold,
                              fontSize: 13,
                              fontWeight: n.read ? FontWeight.normal : FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(n.body,
                          style: AtithyaTypography.caption.copyWith(fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(_timeAgo(n.createdAt),
                    style: AtithyaTypography.caption.copyWith(
                        fontSize: 10, color: AtithyaColors.ashWhite)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language & Region Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageRegionSheet extends ConsumerStatefulWidget {
  const _LanguageRegionSheet();
  @override
  ConsumerState<_LanguageRegionSheet> createState() => _LanguageRegionSheetState();
}

class _LanguageRegionSheetState extends ConsumerState<_LanguageRegionSheet> {
  String _language = 'English';
  String _currency = 'INR';
  bool _saving = false;

  static const _languages = [
    ('English', 'English'),
    ('हिन्दी', 'Hindi'),
    ('தமிழ்', 'Tamil'),
    ('తెలుగు', 'Telugu'),
    ('বাংলা', 'Bengali'),
    ('मराठी', 'Marathi'),
  ];

  static const _currencies = [
    ('₹ INR', 'INR', 'Indian Rupee'),
    ('\$ USD', 'USD', 'US Dollar'),
    ('€ EUR', 'EUR', 'Euro'),
    ('د.إ AED', 'AED', 'UAE Dirham'),
    ('£ GBP', 'GBP', 'British Pound'),
  ];

  @override
  void initState() {
    super.initState();
    // Use localeProvider as source of truth (stores English codes: 'Hindi', 'Tamil', etc.)
    final locale = ref.read(localeProvider);
    _language = locale.language;
    _currency = locale.currency;
  }

  Future<void> _apply() async {
    setState(() => _saving = true);
    await ref.read(authProvider.notifier).updatePreferences(
      language: _language,
      currency: _currency,
    );
    // Propagate immediately to the locale provider so the whole app reflects changes
    await ref.read(localeProvider.notifier).setLanguage(_language);
    await ref.read(localeProvider.notifier).setCurrency(_currency);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Color(0xFF111318),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AtithyaColors.imperialGold, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle('LANGUAGE & REGION'),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locale.t('san.languageLabel'),
                        style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.imperialGold.withValues(alpha: 0.7),
                            fontSize: 9, letterSpacing: 3)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _languages.map((lang) {
                        final isActive = _language == lang.$2;
                        return GestureDetector(
                          onTap: () => setState(() => _language = lang.$2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AtithyaColors.imperialGold.withValues(alpha: 0.15)
                                  : AtithyaColors.darkSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive
                                    ? AtithyaColors.imperialGold.withValues(alpha: 0.6)
                                    : AtithyaColors.imperialGold.withValues(alpha: 0.1),
                                width: isActive ? 1.2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(lang.$1,
                                    style: AtithyaTypography.bodyElegant.copyWith(
                                        color: isActive
                                            ? AtithyaColors.imperialGold
                                            : AtithyaColors.cream,
                                        fontSize: 16,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.normal)),
                                Text(lang.$2,
                                    style: AtithyaTypography.caption.copyWith(fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Text(locale.t('san.currencyLabel'),
                        style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.imperialGold.withValues(alpha: 0.7),
                            fontSize: 9, letterSpacing: 3)),
                    const SizedBox(height: 12),
                    ...(_currencies.map((cur) {
                      final isActive = _currency == cur.$2;
                      return GestureDetector(
                        onTap: () => setState(() => _currency = cur.$2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AtithyaColors.imperialGold.withValues(alpha: 0.10)
                                : AtithyaColors.darkSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? AtithyaColors.imperialGold.withValues(alpha: 0.5)
                                  : AtithyaColors.imperialGold.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(cur.$1,
                                  style: AtithyaTypography.bodyElegant.copyWith(
                                      color: isActive
                                          ? AtithyaColors.imperialGold
                                          : AtithyaColors.cream,
                                      fontSize: 15)),
                              const SizedBox(width: 12),
                              Text(cur.$3,
                                  style: AtithyaTypography.caption.copyWith(fontSize: 11)),
                              const Spacer(),
                              if (isActive)
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AtithyaColors.imperialGold,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: AtithyaColors.obsidian, size: 12),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList()),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
              child: GoldButton(label: _saving ? '...' : locale.t('san.applyBtn'), onTap: _saving ? null : _apply),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy & Security Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _PrivacySecuritySheet extends ConsumerStatefulWidget {
  const _PrivacySecuritySheet();
  @override
  ConsumerState<_PrivacySecuritySheet> createState() => _PrivacySecuritySheetState();
}

class _PrivacySecuritySheetState extends ConsumerState<_PrivacySecuritySheet> {
  bool _dataAnalytics = true;
  bool _locationServices = true;
  bool _marketingEmails = false;
  bool _thirdPartySharing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(authProvider).user?['privacySettings'] as Map? ?? {};
    _dataAnalytics    = prefs['dataAnalytics']    as bool? ?? true;
    _locationServices = prefs['locationServices'] as bool? ?? true;
    _marketingEmails  = prefs['marketingEmails']  as bool? ?? false;
    _thirdPartySharing= prefs['thirdPartySharing']as bool? ?? false;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(authProvider.notifier).updatePreferences(
      privacySettings: {
        'dataAnalytics':     _dataAnalytics,
        'locationServices':  _locationServices,
        'marketingEmails':   _marketingEmails,
        'thirdPartySharing': _thirdPartySharing,
      },
    );
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: const BoxDecoration(
          color: Color(0xFF111318),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AtithyaColors.imperialGold, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle('PRIVACY & SECURITY'),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _toggleRow('Usage Analytics', 'Help us improve your experience', _dataAnalytics, (v) => setState(() => _dataAnalytics = v)),
                    _toggleRow('Location Services', 'For nearby estate recommendations', _locationServices, (v) => setState(() => _locationServices = v)),
                    _toggleRow('Marketing Emails', 'Curated offers & announcements', _marketingEmails, (v) => setState(() => _marketingEmails = v)),
                    _toggleRow('Third-Party Sharing', 'Share data with partner services', _thirdPartySharing, (v) => setState(() => _thirdPartySharing = v)),
                    const SizedBox(height: 20),
                    Container(
                        height: 1,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                          Colors.transparent,
                          AtithyaColors.imperialGold.withValues(alpha: 0.2),
                          Colors.transparent
                        ]))),
                    const SizedBox(height: 20),
                    // Export data
                    GestureDetector(
                      onTap: () {
                        final user = ref.read(authProvider).user ?? {};
                        final data = {
                          'exportedAt': DateTime.now().toIso8601String(),
                          'profile': {
                            'name': user['name'],
                            'phone': user['phoneNumber'],
                            'memberTier': user['memberTier'],
                            'loyaltyPoints': user['loyaltyPoints'],
                            'language': user['language'],
                            'currency': user['currency'],
                          },
                          'privacySettings': user['privacySettings'] ?? {},
                        };
                        final jsonStr =
                            const JsonEncoder.withIndent('  ').convert(data);
                        final bytes = jsonStr.codeUnits;
                        final blob = html.Blob([Uint8List.fromList(bytes)], 'application/json');
                        final url = html.Url.createObjectUrlFromBlob(blob);
                        html.AnchorElement(href: url)
                          ..setAttribute('download', 'atithya_data_export.json')
                          ..click();
                        html.Url.revokeObjectUrl(url);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AtithyaColors.darkSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.download_outlined,
                                color: AtithyaColors.imperialGold, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Export My Data',
                                      style: AtithyaTypography.bodyElegant
                                          .copyWith(color: AtithyaColors.cream, fontSize: 14)),
                                  Text('Download a copy of your account data',
                                      style: AtithyaTypography.caption.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: AtithyaColors.ashWhite, size: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Delete account
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF111318),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: Text('Delete Account?',
                              style: AtithyaTypography.displaySmall
                                  .copyWith(fontSize: 18)),
                          content: Text(
                            'This will permanently remove all your data, bookings, and loyalty points. This action cannot be undone.',
                            style: AtithyaTypography.bodyElegant
                                .copyWith(color: AtithyaColors.ashWhite),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel',
                                  style: TextStyle(color: AtithyaColors.imperialGold)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Delete',
                                  style: TextStyle(color: AtithyaColors.errorRed)),
                            ),
                          ],
                        ),
                      ),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AtithyaColors.errorRed.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AtithyaColors.errorRed.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                color: AtithyaColors.errorRed, size: 18),
                            const SizedBox(width: 12),
                            Text('Delete Account',
                                style: AtithyaTypography.bodyElegant.copyWith(
                                    color: AtithyaColors.errorRed, fontSize: 14)),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios,
                                color: AtithyaColors.errorRed, size: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
              child: GoldButton(
                  label: _saving ? '...' : locale.t('san.saveSettings'),
                  onTap: _saving ? null : _save),
            ),
          ],
        ),
      ),
    );
  }
}

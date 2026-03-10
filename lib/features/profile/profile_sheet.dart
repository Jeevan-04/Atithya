import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/colors.dart';
import '../../../core/typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../admin/admin_panel_sheet.dart';
import '../auth/auth_foyer_screen.dart';
import '../booking/booking_detail_screen.dart';

class ProfileSheet extends ConsumerStatefulWidget {
  const ProfileSheet({super.key});

  @override
  ConsumerState<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<ProfileSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bookingProvider.notifier).fetchMyBookings());
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AtithyaColors.imperialGold;
      case 'elite':
        return AtithyaColors.roseGlow;
      default:
        return AtithyaColors.ashWhite;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.shield_outlined;
      case 'elite':
        return Icons.star_border_rounded;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bookingState = ref.watch(bookingProvider);
    final user = authState.user;

    if (user == null) return const SizedBox();

    final role = user['role'] as String? ?? 'guest';

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AtithyaColors.deepMidnight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: AtithyaColors.deepMidnight.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                    color: AtithyaColors.imperialGold.withValues(alpha: 0.25), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile header
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AtithyaColors.darkSurface, AtithyaColors.surfaceElevated],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              // Avatar circle
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AtithyaColors.royalMaroon, AtithyaColors.deepMaroon],
                                  ),
                                  border: Border.all(
                                      color: _roleColor(role).withValues(alpha: 0.5),
                                      width: 1.5),
                                ),
                                child: Icon(_roleIcon(role),
                                    color: _roleColor(role), size: 24),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['phoneNumber'],
                                        style: AtithyaTypography.displaySmall),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _roleColor(role).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(2),
                                        border: Border.all(
                                            color: _roleColor(role).withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: AtithyaTypography.labelMicro.copyWith(
                                          color: _roleColor(role),
                                          fontSize: 9,
                                          letterSpacing: 2.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Secret Admin trigger
                              if (role == 'admin')
                                GestureDetector(
                                  onLongPress: () {
                                    Navigator.pop(context);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => const AdminPanelSheet(),
                                    );
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AtithyaColors.royalMaroon.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                                    ),
                                    child: const Icon(Icons.admin_panel_settings_outlined,
                                        color: AtithyaColors.imperialGold, size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms),

                        const SizedBox(height: 36),

                        // Bookings section header
                        Row(
                          children: [
                            Container(width: 3, height: 16, color: AtithyaColors.royalMaroon),
                            const SizedBox(width: 12),
                            Text('MY ITINERARIES',
                                style: AtithyaTypography.labelMicro.copyWith(
                                  color: AtithyaColors.imperialGold,
                                  letterSpacing: 4,
                                )),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Bookings list
                        if (bookingState.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                  color: AtithyaColors.imperialGold, strokeWidth: 0.8),
                            ),
                          )
                        else if (bookingState.bookings.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AtithyaColors.darkSurface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.bookmark_border_outlined,
                                      color: AtithyaColors.ashWhite.withValues(alpha: 0.4),
                                      size: 36),
                                  const SizedBox(height: 16),
                                  Text('No sanctuaries reserved yet.',
                                      style: AtithyaTypography.bodyElegant.copyWith(
                                          color: AtithyaColors.ashWhite)),
                                ],
                              ),
                            ),
                          )
                        else
                          ...bookingState.bookings
                              .asMap()
                              .entries
                              .map<Widget>((entry) {
                                final b = entry.value;
                                final dateStr = DateFormat('d MMM yyyy').format(
                                    DateTime.parse(b['checkInDate']));
                                return _buildBookingCard(b, dateStr, entry.key);
                              })
                              .toList(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Logout footer
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: GestureDetector(
                      onTap: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthFoyerScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AtithyaColors.errorRed.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_outlined,
                                color: AtithyaColors.errorRed, size: 16),
                            const SizedBox(width: 10),
                            Text('DEPART',
                                style: AtithyaTypography.labelSmall.copyWith(
                                  color: AtithyaColors.errorRed,
                                  letterSpacing: 4,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b, String dateStr, int i) {
    final statusColor = b['status'] == 'Confirmed'
        ? AtithyaColors.success
        : AtithyaColors.ashWhite;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(booking: b),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          // Top image strip
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              image: DecorationImage(
                image: NetworkImage(
                  (b['estate']['heroImage'] as String?) ??
                      ((b['estate']['images'] as List?)?.isNotEmpty == true
                          ? b['estate']['images'][0] as String
                          : ''),
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AtithyaColors.obsidian.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(b['status'] ?? '',
                        style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.obsidian,
                          fontSize: 8,
                          letterSpacing: 1.5,
                        )),
                  ),
                ),
              ],
            ),
          ),
          // Info area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (b['estate']['location'] ?? '').toUpperCase(),
                  style: AtithyaTypography.labelMicro.copyWith(
                      color: AtithyaColors.imperialGold, fontSize: 9),
                ),
                const SizedBox(height: 6),
                Text(b['estate']['title'] ?? '',
                    style: AtithyaTypography.displaySmall.copyWith(fontSize: 18)),
                const SizedBox(height: 12),
                Container(
                    height: 1,
                    color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AtithyaColors.ashWhite),
                    const SizedBox(width: 8),
                    Text(dateStr, style: AtithyaTypography.caption),
                    const Spacer(),
                    const Icon(Icons.people_outline,
                        size: 12, color: AtithyaColors.ashWhite),
                    const SizedBox(width: 8),
                    Text('${b['guests']} guest${b['guests'] != 1 ? 's' : ''}',
                        style: AtithyaTypography.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: Duration(milliseconds: 200 * i))
        .slideY(begin: 0.15, end: 0, duration: 600.ms, delay: Duration(milliseconds: 200 * i)),
    );
  }
}

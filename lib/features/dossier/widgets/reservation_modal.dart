import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';

class ReservationModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> estate;
  const ReservationModal({super.key, required this.estate});

  @override
  ConsumerState<ReservationModal> createState() => _ReservationModalState();
}

class _ReservationModalState extends ConsumerState<ReservationModal> {
  int _guests = 2;
  DateTime _checkIn = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGuest = authState.user == null || authState.user!['role'] == 'guest';
    final bookingState = ref.watch(bookingProvider);
    final price = widget.estate['basePrice'] ?? 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AtithyaColors.deepMidnight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: AtithyaColors.deepMidnight.withValues(alpha: 0.97),
              border: Border(
                top: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.3), width: 1),
                left: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.08)),
                right: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.08)),
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 18),
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text('RESERVATION',
                            style: AtithyaTypography.labelMicro.copyWith(
                              color: AtithyaColors.imperialGold,
                              letterSpacing: 5,
                            )),
                        const SizedBox(height: 10),
                        Text(
                          widget.estate['title'] ?? '',
                          style: AtithyaTypography.displayMedium.copyWith(height: 1.1),
                        ),

                        const SizedBox(height: 32),

                        // Three rich info rows
                        _buildInfoCard(
                          icon: Icons.calendar_today_outlined,
                          label: 'ARRIVAL',
                          value: '${_checkIn.day} ${_monthName(_checkIn.month)} ${_checkIn.year}',
                          onEdit: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _checkIn,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AtithyaColors.imperialGold,
                                    onPrimary: AtithyaColors.obsidian,
                                    surface: AtithyaColors.darkSurface,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (date != null) setState(() => _checkIn = date);
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildInfoCard(
                          icon: Icons.people_outline,
                          label: 'ROYAL GUESTS',
                          value: '$_guests person${_guests > 1 ? 's' : ''}',
                          onEdit: () {
                            setState(() => _guests = _guests >= 8 ? 1 : _guests + 1);
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildInfoCard(
                          icon: Icons.credit_card_outlined,
                          label: 'TENDER',
                          value: 'Centurion Black',
                          onEdit: null,
                        ),

                        const SizedBox(height: 32),

                        // Total
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AtithyaColors.darkSurface, AtithyaColors.surfaceElevated],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TOTAL TARIFF',
                                      style: AtithyaTypography.labelMicro.copyWith(
                                          color: AtithyaColors.ashWhite)),
                                  const SizedBox(height: 6),
                                  Text('\$$price',
                                      style: AtithyaTypography.price.copyWith(fontSize: 32)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('PER NIGHT',
                                      style: AtithyaTypography.caption),
                                  Text('· ${_guests} guest${_guests > 1 ? "s" : ""}',
                                      style: AtithyaTypography.caption),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),

                // ── Action Footer ──
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: isGuest
                        ? Column(
                            children: [
                              const Icon(Icons.lock_outline,
                                  color: AtithyaColors.royalMaroon, size: 28),
                              const SizedBox(height: 12),
                              Text(
                                'Reservations are exclusive to Elite Members.',
                                style: AtithyaTypography.bodyElegant.copyWith(
                                    color: AtithyaColors.ashWhite),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Login with your member number to proceed.',
                                style: AtithyaTypography.caption,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: bookingState.isLoading
                                ? null
                                : () async {
                                    final success = await ref
                                        .read(bookingProvider.notifier)
                                        .createBooking({
                                      'estateId': widget.estate['_id'],
                                      'checkInDate': _checkIn.toIso8601String(),
                                      'guests': _guests,
                                      'tenderDetails': 'Centurion Black',
                                      'totalAmount': price,
                                    });
                                    if (success != null && context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle_outline,
                                                  color: AtithyaColors.imperialGold, size: 18),
                                              const SizedBox(width: 12),
                                              Text('Sanctuary Reserved',
                                                  style: AtithyaTypography.bodyElegant.copyWith(
                                                      color: AtithyaColors.pearl)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: bookingState.isLoading
                                    ? null
                                    : const LinearGradient(
                                        colors: [
                                          AtithyaColors.burnishedGold,
                                          AtithyaColors.imperialGold,
                                          AtithyaColors.shimmerGold,
                                        ],
                                      ),
                                color: bookingState.isLoading
                                    ? AtithyaColors.surfaceElevated
                                    : null,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Center(
                                child: bookingState.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: AtithyaColors.obsidian,
                                          strokeWidth: 1.5,
                                        ),
                                      )
                                    : Text(
                                        'AUTHORIZE ✦ CONFIRM ARRIVAL',
                                        style: AtithyaTypography.labelSmall.copyWith(
                                          color: AtithyaColors.obsidian,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 3,
                                        ),
                                      ),
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
    ).animate().slideY(begin: 1.0, end: 0, duration: 700.ms, curve: Curves.fastOutSlowIn);
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AtithyaColors.imperialGold, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AtithyaTypography.labelMicro.copyWith(
                        color: AtithyaColors.ashWhite, fontSize: 9)),
                const SizedBox(height: 4),
                Text(value, style: AtithyaTypography.displaySmall.copyWith(fontSize: 16)),
              ],
            ),
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AtithyaColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                      color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: AtithyaColors.imperialGold, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

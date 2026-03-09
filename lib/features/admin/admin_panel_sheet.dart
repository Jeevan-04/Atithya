import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/colors.dart';
import '../../../core/typography.dart';
import '../../../core/network/api_client.dart';

class AdminNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() {
    return null;
  }

  Future<void> fetchStats() async {
    try {
      final data = await apiClient.get('/admin/system');
      state = data;
    } catch (_) {
      state = null;
    }
  }
}

final adminProvider = NotifierProvider<AdminNotifier, Map<String, dynamic>?>(AdminNotifier.new);

class AdminPanelSheet extends ConsumerStatefulWidget {
  const AdminPanelSheet({super.key});

  @override
  ConsumerState<AdminPanelSheet> createState() => _AdminPanelSheetState();
}

class _AdminPanelSheetState extends ConsumerState<AdminPanelSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchStats());
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(adminProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AtithyaColors.pureBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            color: AtithyaColors.pureBlack.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 2,
                    color: AtithyaColors.pureIvory.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 48),
                Text('SYSTEM OVERVIEW', style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.antiqueGold)),
                const SizedBox(height: 16),
                Text('Global Dashboard', style: AtithyaTypography.displayMedium),
                
                const SizedBox(height: 64),
                
                if (stats == null)
                  const Center(child: CircularProgressIndicator(color: AtithyaColors.antiqueGold))
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBlock('ACTIVE ESTATES', stats['stats']['activeEstates'].toString()),
                      _buildStatBlock('TOTAL BOOKINGS', stats['stats']['totalBookings'].toString()),
                      _buildStatBlock('CITIZENS', stats['stats']['totalUsers'].toString()),
                    ],
                  ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms),
                  
                  const SizedBox(height: 64),
                  Text('RECENT ACTIVITY', style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.antiqueGold)),
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: ListView.separated(
                      itemCount: (stats['recentBookings'] as List).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final booking = stats['recentBookings'][index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 4, height: 40, color: AtithyaColors.antiqueGold),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(booking['estate']['title'], style: AtithyaTypography.bodyElegant),
                                  Text(
                                    'By: ${booking['user']['phoneNumber']} • ${booking['status']}',
                                    style: AtithyaTypography.labelMicro,
                                  ),
                                ],
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AtithyaTypography.displayLarge.copyWith(height: 1.0)),
        const SizedBox(height: 8),
        Text(label, style: AtithyaTypography.labelMicro.copyWith(fontSize: 8)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/typography.dart';
import '../../../providers/access_provider.dart';
import '../../../providers/auth_provider.dart';
import '../access/gate_scanner_screen.dart';
import '../auth/auth_foyer_screen.dart';

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _rooms = [];
  bool _roomsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(accessProvider.notifier).fetchTodayArrivals();
      ref.read(accessProvider.notifier).fetchActiveGuests();
      _fetchRooms();
    });
  }

  Future<void> _fetchRooms() async {
    setState(() => _roomsLoading = true);
    try {
      final data = await ApiClient().get('/api/rooms/status');
      if (mounted) setState(() {
        _rooms = (data as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        _roomsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _roomsLoading = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'gate_staff': return '🚗 Gate';
      case 'desk_staff': return '🛎️ Desk';
      case 'manager': return '👑 Manager';
      case 'admin': return '⚙️ Admin';
      default: return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(accessProvider);
    final user = ref.watch(authProvider).user;
    final role = user?['role'] ?? 'gate_staff';
    final name = user?['name'] ?? 'Staff';

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_greeting(), style: AtithyaTypography.bodyText.copyWith(
                        color: AtithyaColors.parchment, fontSize: 12, letterSpacing: 1,
                      )),
                      const SizedBox(height: 4),
                      Text(name.split(' ').first, style: AtithyaTypography.heroTitle.copyWith(
                        color: AtithyaColors.shimmerGold, fontSize: 24,
                      )),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AtithyaColors.imperialGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.3)),
                    ),
                    child: Text(_roleLabel(role), style: TextStyle(
                      color: AtithyaColors.imperialGold, fontSize: 12,
                    )),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
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
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AtithyaColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.logout, color: AtithyaColors.pearl, size: 18),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // ── Quick Stats ───────────────────────────────────────────
                Row(children: [
                  Expanded(child: _StatCard(
                    label: "Today's Arrivals",
                    value: access.todayArrivals.length,
                    icon: Icons.flight_land_rounded,
                    color: AtithyaColors.imperialGold,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    label: 'Active Guests',
                    value: access.activeGuests.length,
                    icon: Icons.people_rounded,
                    color: AtithyaColors.success,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    label: 'Pending Drive-In',
                    value: access.todayArrivals.where((b) => !b.driveInApproved).length,
                    icon: Icons.directions_car_rounded,
                    color: const Color(0xFFFF8C00),
                  )),
                ]),

                const SizedBox(height: 20),

                // ── Scan Button ───────────────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GateScannerScreen())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AtithyaColors.goldGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: AtithyaColors.imperialGold.withOpacity(0.3), blurRadius: 20),
                      ],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.qr_code_scanner_rounded, color: AtithyaColors.obsidian, size: 22),
                      const SizedBox(width: 10),
                      Text('Scan Guest QR Code', style: AtithyaTypography.cardTitle.copyWith(
                        color: AtithyaColors.obsidian, fontSize: 15,
                      )),
                    ]),
                  ),
                ).animate().fadeIn(duration: 600.ms),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Tabs ──────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AtithyaColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabs,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AtithyaColors.imperialGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.4)),
                ),
                labelColor: AtithyaColors.imperialGold,
                unselectedLabelColor: AtithyaColors.parchment,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                tabs: const [Tab(text: "Today's Arrivals"), Tab(text: 'Active Guests'), Tab(text: 'Room Board')],
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab Content ───────────────────────────────────────────────
            Expanded(
              child: access.loading
                  ? const Center(child: CircularProgressIndicator(color: AtithyaColors.imperialGold))
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _BookingList(
                          bookings: access.todayArrivals,
                          emptyLabel: 'No arrivals today',
                          onRefresh: () => ref.read(accessProvider.notifier).fetchTodayArrivals(),
                        ),
                        _BookingList(
                          bookings: access.activeGuests,
                          emptyLabel: 'No active guests',
                          onRefresh: () => ref.read(accessProvider.notifier).fetchActiveGuests(),
                        ),                        _HousekeepingBoard(
                          rooms: _rooms,
                          loading: _roomsLoading,
                          onRefresh: _fetchRooms,
                          onStatusChanged: (id, status) async {
                            try {
                              await ApiClient().patch('/api/rooms/status/$id', {'status': status});
                              await _fetchRooms();
                            } catch (_) {}
                          },
                        ),                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text('$value', style: AtithyaTypography.heroTitle.copyWith(color: color, fontSize: 22)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AtithyaColors.parchment.withOpacity(0.7), fontSize: 10)),
      ]),
    );
  }
}

// ── Booking List ──────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final List<TodayBooking> bookings;
  final String emptyLabel;
  final VoidCallback onRefresh;

  const _BookingList({required this.bookings, required this.emptyLabel, required this.onRefresh});

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.hotel_rounded, color: AtithyaColors.imperialGold.withOpacity(0.3), size: 48),
          const SizedBox(height: 12),
          Text(emptyLabel, style: AtithyaTypography.bodyText.copyWith(color: AtithyaColors.parchment)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRefresh,
            child: Text('Refresh', style: TextStyle(color: AtithyaColors.imperialGold)),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      color: AtithyaColors.imperialGold,
      backgroundColor: AtithyaColors.darkSurface,
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookings.length,
        itemBuilder: (_, i) {
          final b = bookings[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AtithyaColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.12)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(b.guestName, style: AtithyaTypography.cardTitle.copyWith(
                  color: AtithyaColors.pearl, fontSize: 14,
                ))),
                _TierBadge(tier: b.memberTier),
                const SizedBox(width: 8),
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: b.status == 'Checked-In' ? AtithyaColors.success
                        : b.status == 'Confirmed' ? const Color(0xFFFF8C00)
                        : AtithyaColors.parchment.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text(b.guestPhone, style: TextStyle(color: AtithyaColors.parchment.withOpacity(0.6), fontSize: 11)),
              const SizedBox(height: 10),
              Row(children: [
                _infoChip(Icons.room_outlined, 'Room ${b.roomNumber}'),
                const SizedBox(width: 8),
                _infoChip(Icons.elevator_outlined, 'Floor ${b.floorNumber}'),
                const SizedBox(width: 8),
                _infoChip(Icons.calendar_today_outlined, _formatDate(b.checkIn)),
              ]),
              if (b.driveInApproved || b.vehicleNumber != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.directions_car, color: AtithyaColors.success, size: 14),
                  const SizedBox(width: 4),
                  Text(b.vehicleNumber ?? 'Drive-In Approved', style: TextStyle(
                    color: AtithyaColors.success, fontSize: 11,
                  )),
                ]),
              ],
              if (b.addOns.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, children: b.addOns.map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AtithyaColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(a, style: TextStyle(color: AtithyaColors.parchment.withOpacity(0.7), fontSize: 9)),
                )).toList()),
              ],
            ]),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
        },
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: AtithyaColors.imperialGold.withOpacity(0.7), size: 12),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: AtithyaColors.parchment, fontSize: 11)),
  ]);
}

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  Color get _color {
    switch (tier) {
      case 'Silver': return const Color(0xFFC0C0C0);
      case 'Gold': return const Color(0xFFFFD700);
      case 'Platinum': return const Color(0xFFE5E4E2);
      case 'Royal': return const Color(0xFFD4AF6A);
      default: return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _color, width: 0.8),
    ),
    child: Text(tier, style: TextStyle(color: _color, fontSize: 9, fontWeight: FontWeight.w600)),
  );
}

// ── Housekeeping/Room Status Board ───────────────────────────────────────────

class _HousekeepingBoard extends StatelessWidget {
  final List<Map<String, dynamic>> rooms;
  final bool loading;
  final VoidCallback onRefresh;
  final Future<void> Function(String id, String status) onStatusChanged;

  const _HousekeepingBoard({
    required this.rooms,
    required this.loading,
    required this.onRefresh,
    required this.onStatusChanged,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Vacant':      return const Color(0xFF4CAF50);
      case 'Occupied':    return const Color(0xFFFF5252);
      case 'Cleaning':    return const Color(0xFFFFB300);
      case 'Ready':       return const Color(0xFF40C4FF);
      case 'Maintenance': return const Color(0xFFFF6D00);
      case 'Blocked':     return const Color(0xFF9E9E9E);
      default:            return AtithyaColors.imperialGold;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Vacant':      return Icons.check_circle_outline;
      case 'Occupied':    return Icons.person_rounded;
      case 'Cleaning':    return Icons.cleaning_services_outlined;
      case 'Ready':       return Icons.hotel_outlined;
      case 'Maintenance': return Icons.build_outlined;
      case 'Blocked':     return Icons.block_outlined;
      default:            return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AtithyaColors.imperialGold));
    }
    if (rooms.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.hotel_outlined, color: AtithyaColors.imperialGold, size: 48),
        const SizedBox(height: 16),
        Text('No rooms configured', style: AtithyaTypography.bodyElegant.copyWith(color: AtithyaColors.parchment)),
        const SizedBox(height: 8),
        Text('Add rooms via the admin panel', style: AtithyaTypography.caption.copyWith(color: AtithyaColors.ashWhite)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onRefresh,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Refresh', style: AtithyaTypography.labelSmall.copyWith(color: AtithyaColors.imperialGold, letterSpacing: 2)),
          ),
        ),
      ]));
    }

    const statuses = ['Vacant', 'Cleaning', 'Ready', 'Occupied', 'Maintenance', 'Blocked'];

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AtithyaColors.imperialGold,
      backgroundColor: AtithyaColors.darkSurface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // ── Summary legend ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Wrap(spacing: 8, runSpacing: 6, children: statuses.map((s) {
                final count = rooms.where((r) => (r['status'] as String? ?? '') == s).length;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(s).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(s).withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_statusIcon(s), size: 11, color: _statusColor(s)),
                    const SizedBox(width: 5),
                    Text('$s ($count)', style: TextStyle(
                      color: _statusColor(s), fontSize: 9, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    )),
                  ]),
                );
              }).toList()),
            ),
          ),
          // ── Room grid ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 40),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final room = rooms[i];
                  final status = room['status'] as String? ?? 'Vacant';
                  final color = _statusColor(status);
                  final roomNum = room['roomNumber']?.toString() ?? '?';
                  final floor = room['floor']?.toString() ?? '';
                  final wing = room['wing']?.toString() ?? '';

                  return GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: ctx,
                      backgroundColor: AtithyaColors.darkSurface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('Room $roomNum ${wing.isNotEmpty ? '· $wing' : ''}',
                            style: AtithyaTypography.displaySmall.copyWith(fontSize: 18)),
                          const SizedBox(height: 6),
                          if (floor.isNotEmpty)
                            Text('Floor $floor', style: AtithyaTypography.caption.copyWith(color: AtithyaColors.ashWhite)),
                          const SizedBox(height: 20),
                          Text('UPDATE STATUS', style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 9)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: statuses.map((s) =>
                            GestureDetector(
                              onTap: () async {
                                Navigator.pop(ctx);
                                await onStatusChanged(room['_id'].toString(), s);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: s == status
                                    ? _statusColor(s).withOpacity(0.2)
                                    : const Color(0xFF1A1C22),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: s == status
                                      ? _statusColor(s)
                                      : AtithyaColors.imperialGold.withOpacity(0.2)),
                                ),
                                child: Text(s, style: TextStyle(
                                  color: _statusColor(s), fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ).toList()),
                        ]),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.35)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_statusIcon(status), color: color, size: 22),
                          const SizedBox(height: 6),
                          Text(roomNum, style: AtithyaTypography.displaySmall.copyWith(
                            color: color, fontSize: 18)),
                          if (wing.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(wing, style: AtithyaTypography.caption.copyWith(
                              color: color.withOpacity(0.7), fontSize: 9)),
                          ],
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(status, style: TextStyle(
                              color: color, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: Duration(milliseconds: 300 + i * 40)),
                  );
                },
                childCount: rooms.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

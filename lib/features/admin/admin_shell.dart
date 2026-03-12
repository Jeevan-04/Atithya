// =============================================================================
// आतिथ्य — Admin Shell
// Full dedicated screen for admin / phantom users.
// Nav tabs: DASHBOARD · BOOKINGS · ESTATES · STAFF
// =============================================================================
// ignore: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';
import '../auth/auth_foyer_screen.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

class _AdminSystemNotifier extends Notifier<AsyncValue<Map<String, dynamic>>> {
  @override
  AsyncValue<Map<String, dynamic>> build() => const AsyncValue.loading();

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final raw = await apiClient.get('/admin/system');
      if (raw is! Map) throw Exception('Invalid system stats response');
      final data = Map<String, dynamic>.from(raw);
      state = AsyncValue.data(data);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final _adminSystemProvider =
    NotifierProvider<_AdminSystemNotifier, AsyncValue<Map<String, dynamic>>>(
        _AdminSystemNotifier.new);

class _AdminBookingsNotifier
    extends Notifier<AsyncValue<List<Map<String, dynamic>>>> {
  int _page = 1;
  bool _hasMore = true;
  String? _statusFilter;

  @override
  AsyncValue<List<Map<String, dynamic>>> build() => const AsyncValue.data([]);

  Future<void> fetch({String? status, bool reset = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      _statusFilter = status;
      state = const AsyncValue.loading();
    }
    if (!_hasMore) return;
    try {
      final q = _statusFilter != null ? '&status=$_statusFilter' : '';
      final raw = await apiClient.get('/admin/bookings?page=$_page&limit=30$q');
      if (raw is! Map) {
        throw Exception('Unexpected response format from bookings API');
      }
      final res = raw as Map<String, dynamic>;
      if (res['success'] == false) {
        throw Exception(res['message'] as String? ?? 'Server error');
      }
      final rows =
          List<Map<String, dynamic>>.from(res['bookings'] as List? ?? []);
      final total = (res['total'] as num?)?.toInt() ?? 0;
      final current = state.asData?.value ?? [];
      final merged = reset ? rows : [...current, ...rows];
      _hasMore = merged.length < total;
      _page++;
      state = AsyncValue.data(merged);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final _adminBookingsProvider = NotifierProvider<_AdminBookingsNotifier,
    AsyncValue<List<Map<String, dynamic>>>>(_AdminBookingsNotifier.new);

class _AdminEstatesNotifier
    extends Notifier<AsyncValue<List<Map<String, dynamic>>>> {
  @override
  AsyncValue<List<Map<String, dynamic>>> build() => const AsyncValue.loading();

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final res =
          await apiClient.get('/admin/estates?limit=100') as Map<String, dynamic>;
      final list = List<Map<String, dynamic>>.from(res['estates'] as List? ?? []);
      state = AsyncValue.data(list);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final _adminEstatesProvider = NotifierProvider<_AdminEstatesNotifier,
    AsyncValue<List<Map<String, dynamic>>>>(_AdminEstatesNotifier.new);

// ── Shell ─────────────────────────────────────────────────────────────────────

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell>
    with TickerProviderStateMixin {
  int _tab = 0;
  late final AnimationController _fadeCtrl;

  static const _tabs = [
    (icon: Icons.dashboard_outlined,    active: Icons.dashboard,            label: 'DASHBOARD'),
    (icon: Icons.receipt_long_outlined, active: Icons.receipt_long,         label: 'BOOKINGS'),
    (icon: Icons.villa_outlined,        active: Icons.villa,                label: 'ESTATES'),
    (icon: Icons.badge_outlined,        active: Icons.badge,                label: 'STAFF'),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeCtrl.forward();
    Future.microtask(() {
      ref.read(_adminSystemProvider.notifier).fetch();
      ref.read(_adminBookingsProvider.notifier).fetch(reset: true);
      ref.read(_adminEstatesProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (i == _tab) return;
    _fadeCtrl.forward(from: 0);
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtithyaColors.pureBlack,
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildNav(context),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0:
        return const _DashboardTab();
      case 1:
        return const _BookingsTab();
      case 2:
        return const _EstatesTab();
      case 3:
        return const _StaffTab();
      default:
        return const _DashboardTab();
    }
  }

  Widget _buildNav(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 64 + bottom,
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xDD0A0B10), Color(0xF50A0B10)],
            ),
            border: Border(
                top: BorderSide(
                    color: AtithyaColors.imperialGold.withValues(alpha: 0.18), width: 0.8)),
          ),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final item = _tabs[i];
              final active = i == _tab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 5),
                        decoration: BoxDecoration(
                          color: active
                              ? AtithyaColors.imperialGold.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: active
                                ? AtithyaColors.imperialGold.withValues(alpha: 0.45)
                                : Colors.transparent,
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          active ? item.active : item.icon,
                          size: 20,
                          color: active
                              ? AtithyaColors.shimmerGold
                              : AtithyaColors.ashWhite.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          fontSize: 7.5,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? AtithyaColors.imperialGold
                              : AtithyaColors.ashWhite.withValues(alpha: 0.28),
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD TAB
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(_adminSystemProvider);
    return RefreshIndicator(
      color: AtithyaColors.imperialGold,
      backgroundColor: const Color(0xFF0F1117),
      onRefresh: () => ref.read(_adminSystemProvider.notifier).fetch(),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Header
          SliverToBoxAdapter(child: _AdminHeader(
            title: 'COMMAND CENTRE',
            subtitle: 'आतिथ्य Platform',
            trailing: user?['name'] as String? ?? 'Admin',
            action: const _LogoutButton(),
          )),

          statsAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                    color: AtithyaColors.imperialGold, strokeWidth: 1.5),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: _ErrorRetry(
                message: e.toString(),
                onRetry: () => ref.read(_adminSystemProvider.notifier).fetch(),
              ),
            ),
            data: (stats) => SliverList(
              delegate: SliverChildListDelegate([
                // KPI grid
                _SectionLabel('KEY METRICS'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 0.95,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      _KpiCard(label: 'ESTATES',    value: '${stats['estates']  ?? 0}', icon: Icons.villa_outlined),
                      _KpiCard(label: 'BOOKINGS',   value: '${stats['bookings'] ?? 0}', icon: Icons.receipt_long_outlined),
                      _KpiCard(label: 'MEMBERS',    value: '${stats['users']    ?? 0}', icon: Icons.people_outline),
                      _KpiCard(label: 'FOOD ORDERS',value: '${stats['orders']   ?? 0}', icon: Icons.restaurant_outlined),
                      _KpiCard(label: 'REVENUE',    value: _fmt(stats['revenue'] ?? 0),
                          icon: Icons.currency_rupee_outlined, highlight: true),
                      _KpiCard(label: 'FOOD REV.',  value: _fmt(stats['foodRevenue'] ?? 0),
                          icon: Icons.dining_outlined, highlight: true),
                    ],
                  ).animate().fadeIn(duration: 500.ms),
                ),

                // Revenue breakdown with refunds
                _SectionLabel('REVENUE BREAKDOWN'),
                _RevenueBreakdown(stats: stats),

                // Top hotels this month
                _SectionLabel('TOP ESTATES THIS MONTH'),
                _TopEstates(stats: stats),

                // Export
                _SectionLabel('EXPORT DATA'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _ExportButton(
                    label: 'Export Bookings  ·  CSV',
                    icon: Icons.table_chart_outlined,
                    url: '/api/admin/export/bookings.csv',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _ExportButton(
                    label: 'Export Users  ·  CSV',
                    icon: Icons.people_outline,
                    url: '/api/admin/export/users.csv',
                  ),
                ),
                // Bottom spacer — clears the navbar
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(0)}K';
    return '₹${n.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKINGS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _BookingsTab extends ConsumerStatefulWidget {
  const _BookingsTab();

  @override
  ConsumerState<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<_BookingsTab> {
  String? _filter;
  final _scrollCtrl = ScrollController();

  static const _statuses = ['All', 'Confirmed', 'Pending', 'Checked In', 'Checked Out', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(_adminBookingsProvider.notifier).fetch(status: _filter);
    }
  }

  void _applyFilter(String? status) {
    setState(() => _filter = status == 'All' ? null : status);
    ref.read(_adminBookingsProvider.notifier).fetch(
        status: _filter, reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(_adminBookingsProvider);
    return CustomScrollView(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _AdminHeader(
          title: 'ALL BOOKINGS',
          subtitle: 'Platform reservation log',
        )),
        // Filter chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _statuses[i];
                final active = (s == 'All' && _filter == null) ||
                    s == _filter;
                return GestureDetector(
                  onTap: () => _applyFilter(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? AtithyaColors.imperialGold.withValues(alpha: 0.18)
                          : AtithyaColors.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? AtithyaColors.imperialGold
                            : AtithyaColors.imperialGold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(s,
                        style: AtithyaTypography.labelMicro.copyWith(
                            fontSize: 9.5,
                            letterSpacing: 0.8,
                            color: active
                                ? AtithyaColors.shimmerGold
                                : AtithyaColors.ashWhite.withValues(alpha: 0.5))),
                  ),
                );
              },
            ),
          ),
        ),
        bookingsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(
                color: AtithyaColors.imperialGold, strokeWidth: 1.5)),
          ),
          error: (e, _) => SliverFillRemaining(
            child: _ErrorRetry(message: e.toString(), onRetry: () =>
                ref.read(_adminBookingsProvider.notifier).fetch(reset: true)),
          ),
          data: (bookings) => bookings.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: _EmptyHint(
                      icon: Icons.receipt_long_outlined,
                      label: 'No bookings found')))
              : SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20,
                      MediaQuery.of(context).padding.bottom + 80),
                  sliver: SliverList.builder(
                    itemCount: bookings.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AdminBookingCard(
                          booking: bookings[i], index: i),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ESTATES TAB
// ─────────────────────────────────────────────────────────────────────────────

class _EstatesTab extends ConsumerWidget {
  const _EstatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estatesAsync = ref.watch(_adminEstatesProvider);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _AdminHeader(
          title: 'ESTATES',
          subtitle: 'Property portfolio',
          action: GestureDetector(
            onTap: () => _openForm(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, color: AtithyaColors.imperialGold, size: 14),
                const SizedBox(width: 6),
                Text('ADD', style: AtithyaTypography.labelMicro.copyWith(
                    color: AtithyaColors.imperialGold, fontSize: 9)),
              ]),
            ),
          ),
        )),
        estatesAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(
                color: AtithyaColors.imperialGold, strokeWidth: 1.5)),
          ),
          error: (e, _) => SliverFillRemaining(
            child: _ErrorRetry(message: e.toString(), onRetry: () =>
                ref.read(_adminEstatesProvider.notifier).fetch()),
          ),
          data: (estates) => estates.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: _EmptyHint(
                      icon: Icons.villa_outlined,
                      label: 'No estates yet')))
              : SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20,
                      MediaQuery.of(context).padding.bottom + 80),
                  sliver: SliverList.builder(
                    itemCount: estates.length,
                    itemBuilder: (_, i) => _EstateRow(
                      estate: estates[i],
                      onEdit: () => _openForm(context, ref, estate: estates[i]),
                      onDelete: () => _delete(context, ref, estates[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _openForm(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? estate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EstateFormSheet(
        existing: estate,
        onSaved: () {
          Navigator.pop(context);
          ref.read(_adminEstatesProvider.notifier).fetch();
        },
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, WidgetRef ref,
      Map<String, dynamic> e) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AtithyaColors.obsidian,
        title: Text('Delete Estate', style: AtithyaTypography.bodyElegant),
        content: Text('Remove "${e['title']}"? This cannot be undone.',
            style: AtithyaTypography.caption),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('DELETE',
                  style: TextStyle(color: Colors.red.shade400))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await apiClient.delete('/admin/estates/${e['_id']}');
      ref.read(_adminEstatesProvider.notifier).fetch();
    } catch (err) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('$err'),
            backgroundColor: Colors.red.shade900));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAFF TAB
// ─────────────────────────────────────────────────────────────────────────────

class _StaffTab extends ConsumerWidget {
  const _StaffTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_adminSystemProvider);
    return RefreshIndicator(
      color: AtithyaColors.imperialGold,
      backgroundColor: const Color(0xFF0F1117),
      onRefresh: () => ref.read(_adminSystemProvider.notifier).fetch(),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _AdminHeader(
            title: 'STAFF ROSTER',
            subtitle: 'Team & access management',
            action: GestureDetector(
              onTap: () => _showAddStaff(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.person_add_outlined,
                      color: AtithyaColors.imperialGold, size: 14),
                  const SizedBox(width: 6),
                  Text('ADD STAFF', style: AtithyaTypography.labelMicro.copyWith(
                      color: AtithyaColors.imperialGold, fontSize: 9)),
                ]),
              ),
            ),
          )),
          statsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(
                  color: AtithyaColors.imperialGold, strokeWidth: 1.5)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: _ErrorRetry(message: e.toString(), onRetry: () =>
                  ref.read(_adminSystemProvider.notifier).fetch()),
            ),
            data: (stats) {
              final staff =
                  List<Map<String, dynamic>>.from(stats['staffList'] ?? []);
              return staff.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: _EmptyHint(
                          icon: Icons.badge_outlined,
                          label: 'No staff members yet')))
                  : SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20,
                          MediaQuery.of(context).padding.bottom + 80),
                      sliver: SliverList.builder(
                        itemCount: staff.length,
                        itemBuilder: (_, i) => _StaffCard(
                            member: staff[i], index: i),
                      ),
                    );
            },
          ),
        ],
      ),
    );
  }

  void _showAddStaff(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStaffSheet(
          onSaved: () => ref.read(_adminSystemProvider.notifier).fetch()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI Components
// ─────────────────────────────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final String? trailing;

  const _AdminHeader({
    required this.title,
    required this.subtitle,
    this.action,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C0E13), Color(0xFF130F1C), Color(0xFF0E100A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 3, height: 12,
                    color: AtithyaColors.imperialGold),
                  const SizedBox(width: 8),
                  Text('आतिथ्य  ·  ADMIN',
                      style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.imperialGold,
                          letterSpacing: 3, fontSize: 9)),
                ]),
                const SizedBox(height: 8),
                Text(title, style: AtithyaTypography.heroTitle.copyWith(
                    fontSize: 26, color: AtithyaColors.pearl)),
                const SizedBox(height: 4),
                Text(subtitle, style: AtithyaTypography.bodyElegant.copyWith(
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.45),
                    fontSize: 12)),
                if (trailing != null) ...[
                  const SizedBox(height: 6),
                  Text('Logged in as $trailing',
                      style: AtithyaTypography.labelMicro.copyWith(
                          fontSize: 9, color: AtithyaColors.imperialGold.withValues(alpha: 0.6))),
                ],
              ]),
            ),
            if (action != null) action!,
          ]),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(children: [
        Container(width: 3, height: 14, color: AtithyaColors.royalMaroon),
        const SizedBox(width: 10),
        Text(text, style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 9)),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = highlight ? AtithyaColors.shimmerGold : AtithyaColors.pearl;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AtithyaColors.imperialGold.withValues(alpha: 0.35)
              : AtithyaColors.imperialGold.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
        Icon(icon, size: 16,
            color: highlight
                ? AtithyaColors.imperialGold
                : AtithyaColors.ashWhite.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AtithyaTypography.displaySmall.copyWith(
              fontSize: 17, color: c, height: 1.0)),
        ),
        const SizedBox(height: 3),
        Text(label, style: AtithyaTypography.labelMicro.copyWith(
            fontSize: 7, letterSpacing: 1.2,
            color: AtithyaColors.ashWhite.withValues(alpha: 0.35))),
      ]),
    );
  }
}

class _RevenueBreakdown extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _RevenueBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    final gross        = (stats['revenue'] as num?)?.toDouble() ?? 0;
    final cancelled    = (stats['cancelledRevenue'] as num?)?.toDouble() ?? 0;
    final refunded     = (stats['refundedAmount'] as num?)?.toDouble() ?? cancelled * 0.8;
    final feeRetained  = cancelled - refunded; // 20% kept
    final food         = (stats['foodRevenue'] as num?)?.toDouble() ?? 0;
    final net          = gross + feeRetained + food;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1117),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.14)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Net revenue headline
          Text('NET PLATFORM REVENUE',
              style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.imperialGold, fontSize: 9)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_shortFmt(net),
                style: AtithyaTypography.heroTitle.copyWith(
                    fontSize: 32, color: AtithyaColors.shimmerGold)),
          ),
          const SizedBox(height: 18),
          // Breakdown grid
          Row(children: [
            Expanded(child: _revRow(Icons.receipt_long_outlined, 'BOOKING REVENUE', _shortFmt(gross), AtithyaColors.shimmerGold)),
            const SizedBox(width: 12),
            Expanded(child: _revRow(Icons.dining_outlined, 'FOOD & DINING', _shortFmt(food), const Color(0xFF7B5CBF))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _revRow(Icons.currency_exchange_outlined, 'REFUNDS PAID', '-${_shortFmt(refunded)}', const Color(0xFF80CBC4))),
            const SizedBox(width: 12),
            Expanded(child: _revRow(Icons.account_balance_outlined, 'CANCEL FEE (20%)', '+${_shortFmt(feeRetained)}', const Color(0xFF4CAF50))),
          ]),
          if (cancelled > 0) ...[  
            const SizedBox(height: 14),
            Container(height: 0.5, color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF80CBC4)),
              const SizedBox(width: 6),
              Flexible(child: Text(
                '${_shortFmt(cancelled)} from ${(stats['bookings'] as int? ?? 0)} cancelled bookings — ${_shortFmt(refunded)} refunded (80%) · ${_shortFmt(feeRetained)} retained',
                style: AtithyaTypography.caption.copyWith(
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.3),
                    fontSize: 9.5, height: 1.4),
              )),
            ]),
          ],
        ]),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _revRow(IconData icon, String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AtithyaTypography.labelMicro.copyWith(
              fontSize: 6.5, letterSpacing: 1.2,
              color: AtithyaColors.ashWhite.withValues(alpha: 0.35))),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(val, style: AtithyaTypography.bodyElegant.copyWith(
                fontSize: 14, color: color)),
          ),
        ])),
      ]),
    );
  }

  String _shortFmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

class _RecentBookingRow extends StatelessWidget {
  final Map booking;
  final int index;
  const _RecentBookingRow({required this.booking, required this.index});

  @override
  Widget build(BuildContext context) {
    final estate = booking['estate'] as Map? ??
        booking['estateId'] as Map? ?? {};
    final user = booking['user'] as Map? ??
        booking['userId'] as Map? ?? {};
    final status = booking['status'] as String? ?? 'Pending';
    final amt = (booking['totalAmount'] as num?)?.toInt() ?? 0;
    final statusColor = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1117),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
        ),
        child: Row(children: [
          Container(
            width: 3, height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(estate['title'] as String? ?? '—',
                  style: AtithyaTypography.bodyElegant.copyWith(
                      fontSize: 13, color: AtithyaColors.pearl)),
              const SizedBox(height: 2),
              Text(
                '${user['name'] ?? user['phoneNumber'] ?? '?'}',
                style: AtithyaTypography.labelMicro.copyWith(
                    fontSize: 9,
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.5)),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(status.toUpperCase(),
                  style: AtithyaTypography.labelMicro.copyWith(
                      fontSize: 7.5, color: statusColor, letterSpacing: 0.8)),
            ),
            const SizedBox(height: 4),
            Text('₹${NumberFormat('#,##,###').format(amt)}',
                style: AtithyaTypography.price.copyWith(
                    fontSize: 13, color: AtithyaColors.shimmerGold)),
          ]),
        ]),
      ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn(duration: 400.ms),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Confirmed': return const Color(0xFF4CAF50);
      case 'Checked In': return AtithyaColors.imperialGold;
      case 'Checked Out': return AtithyaColors.ashWhite;
      case 'Cancelled': return AtithyaColors.errorRed;
      default: return const Color(0xFF9B7DEC);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout button for admin header
// ─────────────────────────────────────────────────────────────────────────────
class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F1117),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: AtithyaColors.imperialGold.withValues(alpha: 0.25))),
            title: Text('Sign Out',
                style: AtithyaTypography.displaySmall
                    .copyWith(color: AtithyaColors.pearl)),
            content: Text('Log out of the admin panel?',
                style: AtithyaTypography.bodyElegant.copyWith(
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.55),
                    fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('CANCEL',
                    style: AtithyaTypography.labelMicro
                        .copyWith(color: AtithyaColors.ashWhite.withValues(alpha: 0.4))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('SIGN OUT',
                    style: AtithyaTypography.labelMicro
                        .copyWith(color: AtithyaColors.errorRed)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => const AuthFoyerScreen()),
              (_) => false,
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AtithyaColors.errorRed.withValues(alpha: 0.35), width: 0.8),
          color: AtithyaColors.errorRed.withValues(alpha: 0.07),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.logout_rounded, size: 13,
              color: AtithyaColors.errorRed.withValues(alpha: 0.75)),
          const SizedBox(width: 5),
          Text('LOGOUT',
              style: AtithyaTypography.labelMicro.copyWith(
                  fontSize: 8.5, color: AtithyaColors.errorRed.withValues(alpha: 0.75))),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Estates This Month
// ─────────────────────────────────────────────────────────────────────────────
class _TopEstates extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _TopEstates({required this.stats});

  @override
  Widget build(BuildContext context) {
    final list = (stats['topEstatesMonth'] as List?) ?? [];
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1117),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Text('No booking data for this month',
                style: AtithyaTypography.caption.copyWith(
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.3))),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: List.generate(list.length, (i) {
          final e = list[i] as Map;
          final title = e['title'] as String? ?? '—';
          final city  = e['city']  as String? ?? '';
          final count = (e['count']   as num?)?.toInt() ?? 0;
          final rev   = (e['revenue'] as num?)?.toDouble() ?? 0;
          final rankColors = [
            const Color(0xFFFFD700), // gold
            const Color(0xFFC0C0C0), // silver
            const Color(0xFFCD7F32), // bronze
          ];
          final rc = i < 3 ? rankColors[i] : AtithyaColors.ashWhite.withValues(alpha: 0.25);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: i == 0
                  ? AtithyaColors.imperialGold.withValues(alpha: 0.3)
                  : AtithyaColors.imperialGold.withValues(alpha: 0.08)),
            ),
            child: Row(children: [
              // Rank badge
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: rc.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: rc.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text('${i + 1}',
                      style: AtithyaTypography.labelMicro.copyWith(
                          fontSize: 10, color: rc, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              // Estate info
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtithyaTypography.bodyElegant.copyWith(
                          fontSize: 13, color: AtithyaColors.pearl)),
                  if (city.isNotEmpty) ...[  
                    const SizedBox(height: 1),
                    Text(city,
                        style: AtithyaTypography.caption.copyWith(
                            fontSize: 9.5,
                            color: AtithyaColors.ashWhite.withValues(alpha: 0.35))),
                  ],
                ]),
              ),
              // Stats
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_shortFmt(rev),
                      style: AtithyaTypography.price.copyWith(
                          fontSize: 13, color: AtithyaColors.shimmerGold)),
                ),
                const SizedBox(height: 3),
                Text('$count booking${count != 1 ? 's' : ''}',
                    style: AtithyaTypography.labelMicro.copyWith(
                        fontSize: 8, color: AtithyaColors.ashWhite.withValues(alpha: 0.35))),
              ]),
            ]),
          ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 400.ms);
        }),
      ),
    );
  }

  String _shortFmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _AdminBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final int index;
  const _AdminBookingCard({required this.booking, required this.index});

  @override
  Widget build(BuildContext context) {
    final estate = booking['estate'] as Map? ?? {};
    final user = booking['user'] as Map? ?? {};
    final status = booking['status'] as String? ?? 'Pending';
    final amt = (booking['totalAmount'] as num?)?.toInt() ?? 0;
    final checkIn = booking['checkInDate'] as String? ?? '';
    final checkOut = booking['checkOutDate'] as String? ?? '';
    String dateRange = '';
    try {
      final ci = DateTime.parse(checkIn);
      final co = DateTime.parse(checkOut);
      dateRange = '${DateFormat('d MMM').format(ci)} – ${DateFormat('d MMM yy').format(co)}';
    } catch (_) {}
    final statusColor = _statusColor(status);
    final heroUrl = estate['heroImage'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        if (heroUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: heroUrl, width: 52, height: 52, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _thumb(),
            ),
          )
        else
          _thumb(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(estate['title'] as String? ?? '—',
                style: AtithyaTypography.bodyElegant.copyWith(
                    fontSize: 13, color: AtithyaColors.pearl),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${user['name'] ?? user['phoneNumber'] ?? '?'}  ·  $dateRange',
              style: AtithyaTypography.labelMicro.copyWith(
                  fontSize: 9,
                  color: AtithyaColors.ashWhite.withValues(alpha: 0.45)),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text('₹${NumberFormat('#,##,###').format(amt)}',
                style: AtithyaTypography.price.copyWith(
                    fontSize: 14, color: AtithyaColors.shimmerGold)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(status.toUpperCase(),
              style: AtithyaTypography.labelMicro.copyWith(
                  fontSize: 7, color: statusColor, letterSpacing: 0.8)),
        ),
      ]),
    ).animate(delay: Duration(milliseconds: 40 * index)).fadeIn(duration: 350.ms);
  }

  Widget _thumb() => Container(
    width: 52, height: 52,
    decoration: BoxDecoration(
      color: AtithyaColors.darkSurface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.castle_outlined,
        size: 22, color: AtithyaColors.imperialGold),
  );

  Color _statusColor(String s) {
    switch (s) {
      case 'Confirmed': return const Color(0xFF4CAF50);
      case 'Checked In': return AtithyaColors.imperialGold;
      case 'Checked Out': return AtithyaColors.ashWhite;
      case 'Cancelled': return AtithyaColors.errorRed;
      default: return const Color(0xFF9B7DEC);
    }
  }
}

class _EstateRow extends StatelessWidget {
  final Map<String, dynamic> estate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _EstateRow({required this.estate, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final heroUrl = estate['heroImage'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AtithyaColors.imperialGold.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        if (heroUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: heroUrl, width: 56, height: 56, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _thumb(),
            ),
          )
        else
          _thumb(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(estate['title'] as String? ?? '—',
                style: AtithyaTypography.bodyElegant.copyWith(fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              '${estate['city'] ?? ''}  ·  ${estate['category'] ?? ''}',
              style: AtithyaTypography.labelMicro.copyWith(
                  fontSize: 9,
                  color: AtithyaColors.ashWhite.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 4),
            Text('₹${NumberFormat('#,##,###').format((estate['basePrice'] as num?)?.toInt() ?? 0)}/night',
                style: AtithyaTypography.price.copyWith(
                    fontSize: 12, color: AtithyaColors.shimmerGold)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined,
              size: 18, color: AtithyaColors.imperialGold),
          onPressed: onEdit,
        ),
        IconButton(
          icon: Icon(Icons.delete_outline,
              size: 18, color: Colors.red.shade400),
          onPressed: onDelete,
        ),
      ]),
    );
  }

  Widget _thumb() => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(
      color: AtithyaColors.darkSurface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.villa_outlined,
        size: 24, color: AtithyaColors.imperialGold),
  );
}

class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final int index;
  const _StaffCard({required this.member, required this.index});

  @override
  Widget build(BuildContext context) {
    final isPhantom = member['_isPhantom'] == true;
    final role = isPhantom
        ? 'PHANTOM'
        : (member['role'] as String? ?? '').toUpperCase().replaceAll('_', ' ');
    final estate = member['estateId'] is Map
        ? member['estateId']['title'] as String?
        : null;
    final roleColor = isPhantom
        ? Colors.deepPurple.shade300
        : AtithyaColors.imperialGold;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPhantom
              ? Colors.deepPurple.withValues(alpha: 0.25)
              : AtithyaColors.imperialGold.withValues(alpha: 0.1),
        ),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
              isPhantom ? Icons.visibility_off_outlined : Icons.badge_outlined,
              color: roleColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(member['name'] as String? ?? member['phoneNumber'] as String? ?? '—',
                style: AtithyaTypography.bodyElegant.copyWith(fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              [member['phoneNumber'], if (estate != null) estate].join('  ·  '),
              style: AtithyaTypography.labelMicro.copyWith(
                  fontSize: 9,
                  color: AtithyaColors.ashWhite.withValues(alpha: 0.45)),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: roleColor.withValues(alpha: 0.35)),
          ),
          child: Text(role,
              style: AtithyaTypography.labelMicro.copyWith(
                  fontSize: 7.5, color: roleColor)),
        ),
      ]),
    ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn(duration: 400.ms);
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String url;
  const _ExportButton({required this.label, required this.icon, required this.url});

  Future<void> _export() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    const base = ApiClient.baseUrl;
    final apiBase = base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
    final fullUrl = '$apiBase$url?token=${Uri.encodeComponent(token)}';
    html.window.open(fullUrl, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _export,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AtithyaColors.imperialGold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: AtithyaColors.imperialGold, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AtithyaTypography.bodyElegant.copyWith(
              color: AtithyaColors.pearl, fontSize: 13))),
          const Icon(Icons.download_outlined,
              color: AtithyaColors.imperialGold, size: 18),
        ]),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline,
            color: AtithyaColors.errorRed.withValues(alpha: 0.7), size: 40),
        const SizedBox(height: 12),
        Text('Failed to load', style: AtithyaTypography.displaySmall.copyWith(fontSize: 16)),
        const SizedBox(height: 4),
        Text(message, style: AtithyaTypography.caption.copyWith(
            color: AtithyaColors.ashWhite), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('RETRY', style: AtithyaTypography.labelMicro.copyWith(
                color: AtithyaColors.imperialGold)),
          ),
        ),
      ]),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon,
          color: AtithyaColors.imperialGold.withValues(alpha: 0.3), size: 48),
      const SizedBox(height: 14),
      Text(label, style: AtithyaTypography.bodyElegant.copyWith(
          color: AtithyaColors.ashWhite)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estate Form Sheet (inline)
// ─────────────────────────────────────────────────────────────────────────────

class _EstateFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _EstateFormSheet({this.existing, required this.onSaved});

  @override
  State<_EstateFormSheet> createState() => _EstateFormSheetState();
}

class _EstateFormSheetState extends State<_EstateFormSheet> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  String _category = 'Palace';
  bool _loading = false;

  static const _cats = [
    'Palace', 'Sanctuary', 'Fortress', 'Private Island',
    'Heritage Estate', 'Beach', 'Mountain', 'Desert', 'Forest', 'Heritage',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing ?? {};
    _c = {
      'title':        TextEditingController(text: e['title']        ?? ''),
      'location':     TextEditingController(text: e['location']     ?? ''),
      'city':         TextEditingController(text: e['city']         ?? ''),
      'state':        TextEditingController(text: e['state']        ?? ''),
      'heroImage':    TextEditingController(text: e['heroImage']    ?? ''),
      'story':        TextEditingController(text: e['story']        ?? ''),
      'basePrice':    TextEditingController(text: e['basePrice']?.toString() ?? ''),
      'phone':        TextEditingController(text: e['phone']        ?? ''),
      'checkInTime':  TextEditingController(text: e['checkInTime']  ?? '14:00'),
      'checkOutTime': TextEditingController(text: e['checkOutTime'] ?? '12:00'),
    };
    _category = e['category'] ?? 'Palace';
  }

  @override
  void dispose() {
    for (final c in _c.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final body = {
        'title':       _c['title']!.text.trim(),
        'location':    _c['location']!.text.trim(),
        'city':        _c['city']!.text.trim(),
        'state':       _c['state']!.text.trim(),
        'heroImage':   _c['heroImage']!.text.trim(),
        'story':       _c['story']!.text.trim(),
        'basePrice':   num.tryParse(_c['basePrice']!.text.trim()) ?? 0,
        'category':    _category,
        'phone':       _c['phone']!.text.trim(),
        'checkInTime': _c['checkInTime']!.text.trim(),
        'checkOutTime':_c['checkOutTime']!.text.trim(),
      };
      if (widget.existing != null) {
        await apiClient.put('/admin/estates/${widget.existing!['_id']}', body);
      } else {
        await apiClient.post('/admin/estates', body);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade900));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 2,
              color: AtithyaColors.ashWhite.withValues(alpha: 0.15))),
          const SizedBox(height: 16),
          Text(isEdit ? 'EDIT ESTATE' : 'NEW ESTATE',
              style: AtithyaTypography.labelMicro.copyWith(
                  color: AtithyaColors.imperialGold)),
          const SizedBox(height: 4),
          Text(isEdit ? (widget.existing!['title'] ?? '') : 'Add a new property',
              style: AtithyaTypography.displayMedium.copyWith(fontSize: 20)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                _field(_c['title']!,    'Property Name *'),
                _field(_c['location']!, 'Full Address *'),
                Row(children: [
                  Expanded(child: _field(_c['city']!,  'City *')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_c['state']!, 'State')),
                ]),
                _field(_c['heroImage']!, 'Hero Image URL *'),
                _field(_c['story']!, 'Story *', maxLines: 3),
                _field(_c['basePrice']!, 'Base Price (₹/night) *',
                    keyboardType: TextInputType.number),
                _field(_c['phone']!, 'Contact Phone'),
                Row(children: [
                  Expanded(child: _field(_c['checkInTime']!, 'Check-In')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_c['checkOutTime']!, 'Check-Out')),
                ]),
                const SizedBox(height: 8),
                Text('CATEGORY', style: AtithyaTypography.labelMicro.copyWith(fontSize: 9)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _cats.map((cat) {
                    final sel = cat == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? AtithyaColors.imperialGold.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: sel
                                ? AtithyaColors.imperialGold
                                : AtithyaColors.ashWhite.withValues(alpha: 0.15),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(cat,
                            style: AtithyaTypography.labelMicro.copyWith(
                              color: sel
                                  ? AtithyaColors.imperialGold
                                  : AtithyaColors.ashWhite.withValues(alpha: 0.5),
                              fontSize: 10,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _loading ? null : _save,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AtithyaColors.imperialGold.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : Text(isEdit ? 'SAVE CHANGES' : 'CREATE ESTATE',
                            style: AtithyaTypography.labelMicro.copyWith(
                                color: Colors.black, fontSize: 12, letterSpacing: 2)),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AtithyaTypography.bodyElegant.copyWith(
            fontSize: 13, color: AtithyaColors.pearl),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AtithyaTypography.labelMicro.copyWith(
              fontSize: 9,
              color: AtithyaColors.ashWhite.withValues(alpha: 0.5)),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: AtithyaColors.ashWhite.withValues(alpha: 0.15))),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AtithyaColors.imperialGold)),
        ),
        validator: label.contains('*')
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Staff Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddStaffSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddStaffSheet({required this.onSaved});

  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _pinCtrl   = TextEditingController();
  String _role = 'desk_staff';
  bool _isPhantom = false;
  bool _loading = false;

  static const _roles = ['desk_staff', 'gate_staff', 'manager'];

  @override
  void dispose() {
    _phoneCtrl.dispose(); _nameCtrl.dispose(); _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_phoneCtrl.text.trim().isEmpty || _pinCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final endpoint = _isPhantom ? '/admin/phantom' : '/admin/staff';
      final body = {
        'phoneNumber': _phoneCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'pin': _pinCtrl.text.trim(),
        if (!_isPhantom) 'role': _role,
      };
      await apiClient.post(endpoint, body);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade900));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 40, height: 2,
            color: AtithyaColors.ashWhite.withValues(alpha: 0.15))),
        const SizedBox(height: 16),
        Text('ADD STAFF MEMBER', style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.imperialGold)),
        const SizedBox(height: 18),
        // Phantom toggle
        GestureDetector(
          onTap: () => setState(() => _isPhantom = !_isPhantom),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isPhantom
                  ? Colors.deepPurple.withValues(alpha: 0.15)
                  : AtithyaColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isPhantom
                    ? Colors.deepPurple.shade300
                    : AtithyaColors.ashWhite.withValues(alpha: 0.1),
              ),
            ),
            child: Row(children: [
              Icon(Icons.visibility_off_outlined,
                  size: 18,
                  color: _isPhantom
                      ? Colors.deepPurple.shade300
                      : AtithyaColors.ashWhite.withValues(alpha: 0.4)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Phantom Account',
                    style: AtithyaTypography.bodyElegant.copyWith(fontSize: 13)),
                Text('Disguised super-admin with role: desk_staff',
                    style: AtithyaTypography.caption.copyWith(
                        fontSize: 10,
                        color: AtithyaColors.ashWhite.withValues(alpha: 0.4))),
              ])),
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPhantom
                      ? Colors.deepPurple.shade300
                      : Colors.transparent,
                  border: Border.all(
                    color: _isPhantom
                        ? Colors.deepPurple.shade300
                        : AtithyaColors.ashWhite.withValues(alpha: 0.3),
                  ),
                ),
                child: _isPhantom
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        // Role selector (only if not phantom)
        if (!_isPhantom)
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _roles.map((r) {
              final sel = r == _role;
              return GestureDetector(
                onTap: () => setState(() => _role = r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? AtithyaColors.imperialGold.withValues(alpha: 0.12)
                        : Colors.transparent,
                    border: Border.all(
                      color: sel
                          ? AtithyaColors.imperialGold
                          : AtithyaColors.ashWhite.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(r.replaceAll('_', ' ').toUpperCase(),
                      style: AtithyaTypography.labelMicro.copyWith(
                          fontSize: 9,
                          color: sel
                              ? AtithyaColors.imperialGold
                              : AtithyaColors.ashWhite.withValues(alpha: 0.5))),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 14),
        // Fields
        _field(_phoneCtrl, 'Phone Number *', keyboardType: TextInputType.phone),
        _field(_nameCtrl,  'Name'),
        _field(_pinCtrl,   'PIN *', obscure: true, keyboardType: TextInputType.number),
        const Spacer(),
        GestureDetector(
          onTap: _loading ? null : _save,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2))
                : Text('CREATE ACCOUNT',
                    style: AtithyaTypography.labelMicro.copyWith(
                        color: Colors.black, fontSize: 12, letterSpacing: 2)),
          ),
        ),
      ]),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool obscure = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: AtithyaTypography.bodyElegant.copyWith(
            fontSize: 13, color: AtithyaColors.pearl),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AtithyaTypography.labelMicro.copyWith(
              fontSize: 9,
              color: AtithyaColors.ashWhite.withValues(alpha: 0.5)),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: AtithyaColors.ashWhite.withValues(alpha: 0.15))),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AtithyaColors.imperialGold)),
        ),
      ),
    );
  }
}

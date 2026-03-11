// =============================================================================
// आतिथ्य — Royal Hospitality Platform
// Author : Jeevan Naidu <jeevannaidu04@gmail.com>
// License: Proprietary © 2025-2026 Jeevan Naidu. All rights reserved.
// -----------------------------------------------------------------------------
// AdminPanelSheet — bottom-sheet control centre accessible only to admin /
// phantom roles. Tabs: System Overview | Estate Management | Staff Roster.
// =============================================================================
import 'dart:ui';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/colors.dart';
import '../../../core/typography.dart';
import '../../../core/network/api_client.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

class AdminNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  Future<void> fetchStats() async {
    try { state = await apiClient.get('/admin/system'); }
    catch (_) { state = null; }
  }
}
final adminProvider = NotifierProvider<AdminNotifier, Map<String, dynamic>?>(AdminNotifier.new);

// ── Admin Panel Sheet ─────────────────────────────────────────────────────────

class AdminPanelSheet extends ConsumerStatefulWidget {
  const AdminPanelSheet({super.key});
  @override
  ConsumerState<AdminPanelSheet> createState() => _AdminPanelSheetState();
}

class _AdminPanelSheetState extends ConsumerState<AdminPanelSheet> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _estates = [];
  bool _estatesLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(adminProvider.notifier).fetchStats();
      _loadEstates();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadEstates() async {
    setState(() => _estatesLoading = true);
    try {
      final res = await apiClient.get('/admin/estates?limit=50');
      setState(() => _estates = List<Map<String, dynamic>>.from(res['estates'] ?? []));
    } catch (_) {}
    setState(() => _estatesLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AtithyaColors.pureBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            color: AtithyaColors.pureBlack.withValues(alpha: 0.85),
            child: Column(
              children: [
                // Handle bar
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40, height: 2,
                    decoration: BoxDecoration(
                      color: AtithyaColors.pureIvory.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Text('COMMAND CENTRE',
                          style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.antiqueGold)),
                      const Spacer(),
                      Text('आतिथ्य', style: AtithyaTypography.bodyElegant.copyWith(
                          color: AtithyaColors.antiqueGold, fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TabBar(
                    controller: _tabs,
                    labelColor: AtithyaColors.antiqueGold,
                    unselectedLabelColor: AtithyaColors.pureIvory.withValues(alpha: 0.4),
                    indicatorColor: AtithyaColors.antiqueGold,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: AtithyaTypography.labelMicro.copyWith(fontSize: 10),
                    tabs: const [
                      Tab(text: 'OVERVIEW'),
                      Tab(text: 'ESTATES'),
                      Tab(text: 'STAFF'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _OverviewTab(onRefresh: () => ref.read(adminProvider.notifier).fetchStats()),
                      _EstatesTab(
                        estates: _estates,
                        loading: _estatesLoading,
                        onRefresh: _loadEstates,
                      ),
                      _StaffTab(stats: ref.watch(adminProvider)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── OVERVIEW TAB ──────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _OverviewTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminProvider);
    return RefreshIndicator(
      color: AtithyaColors.antiqueGold,
      backgroundColor: AtithyaColors.pureBlack,
      onRefresh: () async => onRefresh(),
      child: stats == null
          ? const Center(child: CircularProgressIndicator(color: AtithyaColors.antiqueGold))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              children: [
                // Stat grid
                Row(
                  children: [
                    _Stat(label: 'ESTATES',   value: '${stats['estates']  ?? 0}'),
                    _Stat(label: 'BOOKINGS',  value: '${stats['bookings'] ?? 0}'),
                    _Stat(label: 'CITIZENS',  value: '${stats['users']    ?? 0}'),
                  ],
                ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Stat(label: 'FOOD ORDERS', value: '${stats['orders']   ?? 0}'),
                    _Stat(label: 'REVENUE ₹',   value: _fmt(stats['revenue'] ?? 0)),
                    _Stat(label: 'FOOD REV ₹',  value: _fmt(stats['foodRevenue'] ?? 0)),
                  ],
                ).animate().slideY(begin: 0.2, end: 0, duration: 700.ms),
                const SizedBox(height: 32),
                Text('RECENT BOOKINGS',
                    style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.antiqueGold)),
                const SizedBox(height: 16),
                ...List.generate((stats['recentBookings'] as List).length, (i) {
                  final b = stats['recentBookings'][i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 3, height: 36,
                            color: AtithyaColors.antiqueGold.withValues(alpha: 0.8)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(b['estate']?['title'] ?? '—',
                                style: AtithyaTypography.bodyElegant.copyWith(fontSize: 13)),
                            Text(
                              '${b['user']?['phoneNumber'] ?? '?'} · ${b['status'] ?? ''}',
                              style: AtithyaTypography.labelMicro.copyWith(fontSize: 9),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
                Text('EXPORT DATA', style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.antiqueGold)),
                const SizedBox(height: 14),
                _CsvExportButton(
                  label: 'Export Bookings (CSV)',
                  icon: Icons.table_chart_outlined,
                  url: '/api/admin/export/bookings.csv',
                ),
                const SizedBox(height: 10),
                _CsvExportButton(
                  label: 'Export Users (CSV)',
                  icon: Icons.people_outline,
                  url: '/api/admin/export/users.csv',
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(0)}K';
    return '₹$n';
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: AtithyaTypography.displayMedium.copyWith(
            fontSize: 28, height: 1.0, color: AtithyaColors.pureIvory)),
        const SizedBox(height: 4),
        Text(label, style: AtithyaTypography.labelMicro.copyWith(fontSize: 8)),
      ]),
    );
  }
}

// ── ESTATES TAB ───────────────────────────────────────────────────────────────

class _EstatesTab extends StatefulWidget {
  final List<Map<String, dynamic>> estates;
  final bool loading;
  final VoidCallback onRefresh;
  const _EstatesTab({required this.estates, required this.loading, required this.onRefresh});

  @override
  State<_EstatesTab> createState() => _EstatesTabState();
}

class _EstatesTabState extends State<_EstatesTab> {

  void _openAddEdit([Map<String, dynamic>? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EstateFormSheet(
        existing: existing,
        onSaved: () {
          Navigator.pop(context);
          widget.onRefresh();
        },
      ),
    );
  }

  Future<void> _delete(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AtithyaColors.obsidian,
        title: Text('Delete Estate', style: AtithyaTypography.bodyElegant),
        content: Text('Remove "$title"?\nActive bookings will prevent deletion.',
            style: AtithyaTypography.labelMicro),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('DELETE', style: TextStyle(color: Colors.red.shade400))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await apiClient.delete('/admin/estates/$id');
      widget.onRefresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade900));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Row(
            children: [
              Text('${widget.estates.length} PROPERTIES',
                  style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.antiqueGold)),
              const Spacer(),
              GestureDetector(
                onTap: () => _openAddEdit(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AtithyaColors.antiqueGold.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: AtithyaColors.antiqueGold, size: 14),
                      const SizedBox(width: 6),
                      Text('ADD ESTATE', style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.antiqueGold, fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.loading
              ? const Center(child: CircularProgressIndicator(color: AtithyaColors.antiqueGold))
              : RefreshIndicator(
                  color: AtithyaColors.antiqueGold,
                  backgroundColor: AtithyaColors.pureBlack,
                  onRefresh: () async => widget.onRefresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    itemCount: widget.estates.length,
                    separatorBuilder: (_, __) => Divider(
                        color: AtithyaColors.pureIvory.withValues(alpha: 0.06), height: 1),
                    itemBuilder: (_, i) {
                      final e = widget.estates[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: e['heroImage'] != null
                              ? Image.network(e['heroImage'], width: 52, height: 52,
                                  fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                                      _estateIcon())
                              : _estateIcon(),
                        ),
                        title: Text(e['title'] ?? '—', style: AtithyaTypography.bodyElegant
                            .copyWith(fontSize: 13)),
                        subtitle: Text(
                          '${e['city'] ?? ''} · ${e['category'] ?? ''} · ₹${e['basePrice'] ?? 0}',
                          style: AtithyaTypography.labelMicro.copyWith(fontSize: 9),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18,
                                  color: AtithyaColors.antiqueGold),
                              onPressed: () => _openAddEdit(e),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 18,
                                  color: Colors.red.shade400),
                              onPressed: () => _delete(e['_id'], e['title'] ?? ''),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _estateIcon() => Container(
    width: 52, height: 52,
    decoration: BoxDecoration(
      color: AtithyaColors.antiqueGold.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Icon(Icons.villa_outlined, color: AtithyaColors.antiqueGold, size: 22),
  );
}

// ── ESTATE FORM SHEET ─────────────────────────────────────────────────────────

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

  static const _categories = [
    'Palace', 'Sanctuary', 'Fortress', 'Private Island',
    'Heritage Estate', 'Beach', 'Mountain', 'Desert', 'Forest', 'Heritage',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing ?? {};
    _c = {
      'title':     TextEditingController(text: e['title']     ?? ''),
      'location':  TextEditingController(text: e['location']  ?? ''),
      'city':      TextEditingController(text: e['city']      ?? ''),
      'state':     TextEditingController(text: e['state']     ?? ''),
      'heroImage': TextEditingController(text: e['heroImage'] ?? ''),
      'story':     TextEditingController(text: e['story']     ?? ''),
      'basePrice': TextEditingController(text: e['basePrice']?.toString() ?? ''),
      'phone':     TextEditingController(text: e['phone']     ?? ''),
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
        'title':        _c['title']!.text.trim(),
        'location':     _c['location']!.text.trim(),
        'city':         _c['city']!.text.trim(),
        'state':        _c['state']!.text.trim(),
        'heroImage':    _c['heroImage']!.text.trim(),
        'story':        _c['story']!.text.trim(),
        'basePrice':    num.tryParse(_c['basePrice']!.text.trim()) ?? 0,
        'category':     _category,
        'phone':        _c['phone']!.text.trim(),
        'checkInTime':  _c['checkInTime']!.text.trim(),
        'checkOutTime': _c['checkOutTime']!.text.trim(),
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
        left: 28, right: 28, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 2,
                color: AtithyaColors.pureIvory.withValues(alpha: 0.15))),
            const SizedBox(height: 20),
            Text(isEdit ? 'EDIT ESTATE' : 'NEW ESTATE',
                style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.antiqueGold)),
            const SizedBox(height: 6),
            Text(isEdit ? (widget.existing!['title'] ?? '') : 'Add a new property',
                style: AtithyaTypography.displayMedium.copyWith(fontSize: 22)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _field(_c['title']!,    'Property Name *'),
                  _field(_c['location']!, 'Full Address *'),
                  Row(children: [
                    Expanded(child: _field(_c['city']!,  'City *')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_c['state']!, 'State')),
                  ]),
                  _field(_c['heroImage']!, 'Hero Image URL *'),
                  _field(_c['story']!, 'Property Story *', maxLines: 3),
                  _field(_c['basePrice']!, 'Base Price (₹/night) *',
                      keyboardType: TextInputType.number),
                  _field(_c['phone']!,    'Contact Phone'),
                  Row(children: [
                    Expanded(child: _field(_c['checkInTime']!,  'Check-In Time')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_c['checkOutTime']!, 'Check-Out Time')),
                  ]),
                  const SizedBox(height: 8),
                  Text('CATEGORY', style: AtithyaTypography.labelMicro.copyWith(fontSize: 9)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _categories.map((cat) {
                      final sel = cat == _category;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? AtithyaColors.antiqueGold.withValues(alpha: 0.15) : Colors.transparent,
                            border: Border.all(color: sel
                                ? AtithyaColors.antiqueGold
                                : AtithyaColors.pureIvory.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(cat, style: AtithyaTypography.labelMicro.copyWith(
                              color: sel ? AtithyaColors.antiqueGold : AtithyaColors.pureIvory.withValues(alpha: 0.6),
                              fontSize: 10)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _loading ? null : _save,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AtithyaColors.antiqueGold.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Text(isEdit ? 'SAVE CHANGES' : 'CREATE ESTATE',
                              style: AtithyaTypography.labelMicro.copyWith(
                                  color: Colors.black, fontSize: 12, letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AtithyaTypography.bodyElegant.copyWith(fontSize: 13, color: AtithyaColors.pureIvory),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AtithyaTypography.labelMicro.copyWith(fontSize: 9, color: AtithyaColors.pureIvory.withValues(alpha: 0.5)),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AtithyaColors.pureIvory.withValues(alpha: 0.15))),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AtithyaColors.antiqueGold)),
        ),
        validator: label.contains('*') ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }
}

// ── STAFF TAB ─────────────────────────────────────────────────────────────────

class _StaffTab extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _StaffTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rawList = stats?['staffList'] as List? ?? [];
    final staff = rawList.cast<Map<String, dynamic>>();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      children: [
        Text('${staff.length} STAFF MEMBERS',
            style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.antiqueGold)),
        const SizedBox(height: 16),
        if (staff.isEmpty)
          Text('No staff accounts yet.',
              style: AtithyaTypography.labelMicro.copyWith(color: AtithyaColors.pureIvory.withValues(alpha: 0.3)))
        else
          ...staff.map((s) {
            final isPhantom = s['_isPhantom'] == true;
            final roleLabel = isPhantom ? 'PHANTOM' : (s['role'] as String? ?? '').toUpperCase().replaceAll('_', ' ');
            final estateTitle = s['estateId'] is Map ? s['estateId']['title'] : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isPhantom
                          ? Colors.deepPurple.withValues(alpha: 0.2)
                          : AtithyaColors.antiqueGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPhantom ? Icons.visibility_off_outlined : Icons.badge_outlined,
                      color: isPhantom ? Colors.deepPurple.shade300 : AtithyaColors.antiqueGold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(s['name'] ?? s['phoneNumber'] ?? '—',
                            style: AtithyaTypography.bodyElegant.copyWith(fontSize: 13))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isPhantom ? Colors.deepPurple : AtithyaColors.antiqueGold).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(roleLabel, style: AtithyaTypography.labelMicro.copyWith(
                              fontSize: 8,
                              color: isPhantom ? Colors.deepPurple.shade300 : AtithyaColors.antiqueGold)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        [s['phoneNumber'], if (estateTitle != null) estateTitle].join(' · '),
                        style: AtithyaTypography.labelMicro.copyWith(fontSize: 9),
                      ),
                    ]),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 8),
        Divider(color: AtithyaColors.pureIvory.withValues(alpha: 0.06)),
        const SizedBox(height: 8),
        Text('TIP — To add staff or create a Phantom account, use:\n'
            'POST /api/admin/staff  (role: gate_staff | desk_staff | manager)\n'
            'POST /api/admin/phantom  (body: { phoneNumber, pin, name })',
            style: AtithyaTypography.labelMicro.copyWith(
                fontSize: 9, color: AtithyaColors.pureIvory.withValues(alpha: 0.25), height: 1.8)),
      ],
    );
  }
}

// ── CSV Export Button ─────────────────────────────────────────────────────────


class _CsvExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String url; // e.g. /api/admin/export/bookings.csv

  const _CsvExportButton({required this.label, required this.icon, required this.url});

  Future<void> _export() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    const base = ApiClient.baseUrl; // 'https://atithya-nzqy.onrender.com/api'
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
          color: AtithyaColors.antiqueGold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AtithyaColors.antiqueGold.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: AtithyaColors.antiqueGold, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AtithyaTypography.bodyElegant.copyWith(
            color: AtithyaColors.pureIvory, fontSize: 13))),
          const Icon(Icons.download_outlined, color: AtithyaColors.antiqueGold, size: 18),
        ]),
      ),
    );
  }
}


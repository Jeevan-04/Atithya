// pre_arrival_form_screen.dart — Pre-Arrival Check-In Form
// आतिथ्य · Luxury Hospitality · Author: Jeevan Naidu

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/network/api_client.dart';

class PreArrivalFormScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const PreArrivalFormScreen({super.key, required this.booking});

  @override
  State<PreArrivalFormScreen> createState() => _PreArrivalFormScreenState();
}

class _PreArrivalFormScreenState extends State<PreArrivalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  // Controllers
  final _etaCtrl = TextEditingController();
  final _flightCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _dietaryCtrl = TextEditingController();
  final _celebrationCtrl = TextEditingController();
  final _additionalCtrl = TextEditingController();

  // Guest names / IDs (dynamic rows)
  final List<TextEditingController> _guestNames = [TextEditingController()];
  final List<TextEditingController> _guestIds = [TextEditingController()];

  Map<String, dynamic> get _b => widget.booking;
  Map<String, dynamic>? _pre;

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing data if already submitted
    final pre = _b['preArrivalForm'] as Map<String, dynamic>?;
    if (pre != null) {
      _pre = pre;
      _etaCtrl.text = pre['estimatedETA'] ?? '';
      _flightCtrl.text = pre['flightOrTrain'] ?? '';
      _vehicleCtrl.text = pre['vehicleNumber'] ?? '';
      _dietaryCtrl.text = pre['dietaryNotes'] ?? '';
      _celebrationCtrl.text = pre['celebrationNote'] ?? '';
      _additionalCtrl.text = pre['additionalRequests'] ?? '';

      final names = (pre['guestNames'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final ids = (pre['idNumbers'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (names.isNotEmpty) {
        _guestNames.clear();
        for (final n in names) _guestNames.add(TextEditingController(text: n));
      }
      if (ids.isNotEmpty) {
        _guestIds.clear();
        for (final id in ids) _guestIds.add(TextEditingController(text: id));
      }
      while (_guestIds.length < _guestNames.length) _guestIds.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _etaCtrl.dispose(); _flightCtrl.dispose(); _vehicleCtrl.dispose();
    _dietaryCtrl.dispose(); _celebrationCtrl.dispose(); _additionalCtrl.dispose();
    for (final c in _guestNames) c.dispose();
    for (final c in _guestIds) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await ApiClient().put('/api/bookings/${_b['_id']}/pre-arrival', {
        'guestNames': _guestNames.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
        'idNumbers': _guestIds.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
        'estimatedETA': _etaCtrl.text.trim(),
        'flightOrTrain': _flightCtrl.text.trim(),
        'vehicleNumber': _vehicleCtrl.text.trim(),
        'dietaryNotes': _dietaryCtrl.text.trim(),
        'celebrationNote': _celebrationCtrl.text.trim(),
        'additionalRequests': _additionalCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF1A1C22),
          content: Text(e.toString(),
            style: AtithyaTypography.caption.copyWith(color: AtithyaColors.errorRed)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estate = (_b['estate'] as Map<String, dynamic>?) ?? {};
    final isSubmitted = _pre?['submitted'] == true;

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      appBar: AppBar(
        backgroundColor: AtithyaColors.obsidian,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 15),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PRE-ARRIVAL CHECK-IN', style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.imperialGold, fontSize: 8, letterSpacing: 3)),
          Text(estate['title'] ?? 'Estate', style: AtithyaTypography.displaySmall.copyWith(fontSize: 18)),
        ]),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(delegate: SliverChildListDelegate([
                if (isSubmitted) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 16),
                      const SizedBox(width: 8),
                      Text('Form submitted — you can update it below',
                        style: AtithyaTypography.caption.copyWith(color: const Color(0xFF4CAF50))),
                    ]),
                  ),
                ],

                _sectionLabel('GUEST INFORMATION'),
                const SizedBox(height: 12),
                ...List.generate(_guestNames.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Expanded(flex: 5, child: _field(
                      controller: _guestNames[i],
                      label: 'Guest ${i + 1} Name',
                      required: i == 0,
                    )),
                    const SizedBox(width: 10),
                    Expanded(flex: 4, child: _field(
                      controller: _guestIds[i],
                      label: 'ID / Passport No.',
                    )),
                    if (i > 0) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() {
                          _guestNames[i].dispose(); _guestNames.removeAt(i);
                          _guestIds[i].dispose(); _guestIds.removeAt(i);
                        }),
                        child: Icon(Icons.remove_circle_outline,
                          color: AtithyaColors.errorRed.withValues(alpha: 0.7), size: 20),
                      ),
                    ],
                  ]),
                )),
                if (_guestNames.length < 10)
                  GestureDetector(
                    onTap: () => setState(() {
                      _guestNames.add(TextEditingController());
                      _guestIds.add(TextEditingController());
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        const Icon(Icons.add_circle_outline, color: AtithyaColors.imperialGold, size: 16),
                        const SizedBox(width: 6),
                        Text('ADD GUEST', style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.imperialGold, letterSpacing: 2, fontSize: 9)),
                      ]),
                    ),
                  ),
                const SizedBox(height: 20),

                _sectionLabel('ARRIVAL DETAILS'),
                const SizedBox(height: 12),
                _field(controller: _etaCtrl, label: 'Estimated Arrival Time (e.g., 3:30 PM)'),
                const SizedBox(height: 12),
                _field(controller: _flightCtrl, label: 'Flight / Train Number (if applicable)'),
                const SizedBox(height: 12),
                _field(controller: _vehicleCtrl, label: 'Vehicle Number (for valet / parking)'),
                const SizedBox(height: 20),

                _sectionLabel('PREFERENCES & NOTES'),
                const SizedBox(height: 12),
                _field(controller: _dietaryCtrl, label: 'Dietary Requirements / Allergies', maxLines: 3),
                const SizedBox(height: 12),
                _field(controller: _celebrationCtrl, label: 'Celebration / Special Occasion (optional)', maxLines: 2),
                const SizedBox(height: 12),
                _field(controller: _additionalCtrl, label: 'Additional Requests', maxLines: 3),
                const SizedBox(height: 32),
              ])),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: AtithyaColors.obsidian,
          border: Border(top: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.1))),
        ),
        child: GestureDetector(
          onTap: _submitting ? null : _submit,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: [AtithyaColors.imperialGold, AtithyaColors.shimmerGold],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
            ),
            child: Center(child: _submitting
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text('SUBMIT CHECK-IN DETAILS', style: AtithyaTypography.labelSmall.copyWith(
                  color: Colors.black, letterSpacing: 2.5, fontWeight: FontWeight.w700))),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(t, style: AtithyaTypography.labelMicro.copyWith(
    color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 9));

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
  }) =>
    TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: AtithyaTypography.bodyElegant.copyWith(fontSize: 14),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AtithyaTypography.caption.copyWith(
          color: AtithyaColors.ashWhite.withValues(alpha: 0.4), fontSize: 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.18))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.5))),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AtithyaColors.errorRed.withValues(alpha: 0.5))),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AtithyaColors.errorRed)),
        filled: true,
        fillColor: const Color(0xFF111318),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
}

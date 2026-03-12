// pre_arrival_form_screen.dart — Pre-Arrival Check-In Form
// आतिथ्य · Luxury Hospitality · Author: Jeevan Naidu

// ignore: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:html' as html;
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

  // Arrival / preference controllers
  final _etaCtrl        = TextEditingController();
  final _flightCtrl     = TextEditingController();
  final _vehicleCtrl    = TextEditingController();
  final _dietaryCtrl    = TextEditingController();
  final _celebrationCtrl= TextEditingController();
  final _additionalCtrl = TextEditingController();

  // Per-guest rows — count is fixed to booking.guests
  final List<TextEditingController> _guestNames = [];
  final List<TextEditingController> _guestIds   = [];
  final List<String?> _guestDocNames = [];  // uploaded file name
  final List<String?> _guestDocData  = [];  // base64 data-URL for preview

  Map<String, dynamic> get _b => widget.booking;
  Map<String, dynamic>? _pre;

  @override
  void initState() {
    super.initState();
    final guestCount = ((_b['guests'] as num?) ?? 1).toInt().clamp(1, 20);

    // Create exactly guestCount rows
    for (int i = 0; i < guestCount; i++) {
      _guestNames.add(TextEditingController());
      _guestIds.add(TextEditingController());
      _guestDocNames.add(null);
      _guestDocData.add(null);
    }

    // Pre-fill from existing data if already submitted
    final pre = _b['preArrivalForm'] as Map<String, dynamic>?;
    if (pre != null) {
      _pre = pre;
      _etaCtrl.text         = pre['estimatedETA']      ?? '';
      _flightCtrl.text      = pre['flightOrTrain']     ?? '';
      _vehicleCtrl.text     = pre['vehicleNumber']     ?? '';
      _dietaryCtrl.text     = pre['dietaryNotes']      ?? '';
      _celebrationCtrl.text = pre['celebrationNote']   ?? '';
      _additionalCtrl.text  = pre['additionalRequests'] ?? '';

      final names = (pre['guestNames'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final ids   = (pre['idNumbers']  as List?)?.map((e) => e.toString()).toList() ?? [];
      for (int i = 0; i < _guestNames.length; i++) {
        if (i < names.length) _guestNames[i].text = names[i];
        if (i < ids.length) _guestIds[i].text = ids[i];
      }
    }
  }

  @override
  void dispose() {
    _etaCtrl.dispose(); _flightCtrl.dispose(); _vehicleCtrl.dispose();
    _dietaryCtrl.dispose(); _celebrationCtrl.dispose(); _additionalCtrl.dispose();
    for (final c in _guestNames) { c.dispose(); }
    for (final c in _guestIds)   { c.dispose(); }
    super.dispose();
  }

  // ── Document picker (web) ─────────────────────────────────────────────────

  void _pickDoc(int index) {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*,.pdf'
      ..click();
    input.onChange.listen((_) {
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoad.listen((_) {
        if (mounted) {
          setState(() {
            _guestDocNames[index] = file.name;
            _guestDocData[index]  = reader.result as String?;
          });
        }
      });
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await ApiClient().put('/api/bookings/${_b['_id']}/pre-arrival', {
        'guestNames':         _guestNames.map((c) => c.text.trim()).toList(),
        'idNumbers':          _guestIds.map((c) => c.text.trim()).toList(),
        'estimatedETA':       _etaCtrl.text.trim(),
        'flightOrTrain':      _flightCtrl.text.trim(),
        'vehicleNumber':      _vehicleCtrl.text.trim(),
        'dietaryNotes':       _dietaryCtrl.text.trim(),
        'celebrationNote':    _celebrationCtrl.text.trim(),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final estate      = (_b['estate'] as Map<String, dynamic>?) ?? {};
    final isSubmitted = _pre?['submitted'] == true;
    final guestCount  = _guestNames.length;

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

                // ── Already submitted banner ────────────────────────────────
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

                // ── Guest Information ───────────────────────────────────────
                _sectionLabel('GUEST INFORMATION'),
                const SizedBox(height: 4),
                Text('$guestCount guest${guestCount != 1 ? 's' : ''} · fill in all names & IDs',
                  style: AtithyaTypography.caption.copyWith(
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.4), fontSize: 11)),
                const SizedBox(height: 16),

                ...List.generate(guestCount, (i) => _GuestRow(
                  index: i,
                  nameCtrl:    _guestNames[i],
                  idCtrl:      _guestIds[i],
                  docName:     _guestDocNames[i],
                  docData:     _guestDocData[i],
                  isRequired:  i == 0,
                  onPickDoc:   () => _pickDoc(i),
                ).animate().fadeIn(duration: 500.ms, delay: Duration(milliseconds: 80 * i))),

                const SizedBox(height: 24),

                // ── Arrival Details ─────────────────────────────────────────
                _sectionLabel('ARRIVAL DETAILS'),
                const SizedBox(height: 12),
                _field(controller: _etaCtrl,    label: 'Estimated Arrival Time (e.g., 3:30 PM)'),
                const SizedBox(height: 12),
                _field(controller: _flightCtrl, label: 'Flight / Train Number (if applicable)'),
                const SizedBox(height: 12),
                _field(controller: _vehicleCtrl, label: 'Vehicle Number (for valet / parking)'),
                const SizedBox(height: 24),

                // ── Preferences & Notes ─────────────────────────────────────
                _sectionLabel('PREFERENCES & NOTES'),
                const SizedBox(height: 12),
                _field(controller: _dietaryCtrl,    label: 'Dietary Requirements / Allergies', maxLines: 3),
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
              gradient: const LinearGradient(
                colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold],
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

// ─────────────────────────────────────────────────────────────────────────────
// _GuestRow — one card per guest: name + ID + document upload
// ─────────────────────────────────────────────────────────────────────────────

class _GuestRow extends StatelessWidget {
  final int index;
  final TextEditingController nameCtrl;
  final TextEditingController idCtrl;
  final String? docName;
  final String? docData;
  final bool isRequired;
  final VoidCallback onPickDoc;

  const _GuestRow({
    required this.index,
    required this.nameCtrl,
    required this.idCtrl,
    required this.isRequired,
    required this.onPickDoc,
    this.docName,
    this.docData,
  });

  @override
  Widget build(BuildContext context) {
    final hasDoc  = docData != null;
    final isImage = hasDoc && !docData!.contains('application/pdf');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111318),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDoc
            ? AtithyaColors.imperialGold.withValues(alpha: 0.35)
            : AtithyaColors.imperialGold.withValues(alpha: 0.14)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Guest label ─────────────────────────────────────────────────────
        Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
            ),
            child: Center(child: Text('${index + 1}',
              style: AtithyaTypography.labelMicro.copyWith(
                color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Text('GUEST ${index + 1}', style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 9)),
          if (isRequired) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AtithyaColors.imperialGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('PRIMARY', style: AtithyaTypography.labelMicro.copyWith(
                color: AtithyaColors.imperialGold, fontSize: 7, letterSpacing: 1.5)),
            ),
          ],
        ]),
        const SizedBox(height: 14),

        // ── Name field ──────────────────────────────────────────────────────
        TextFormField(
          controller: nameCtrl,
          style: AtithyaTypography.bodyElegant.copyWith(fontSize: 14),
          validator: isRequired
            ? (v) => (v == null || v.trim().isEmpty) ? 'Guest name is required' : null
            : null,
          decoration: _inputDeco('Full Name${isRequired ? '' : ' (optional)'}'),
        ),
        const SizedBox(height: 10),

        // ── ID / Passport field ─────────────────────────────────────────────
        TextFormField(
          controller: idCtrl,
          style: AtithyaTypography.bodyElegant.copyWith(fontSize: 14),
          decoration: _inputDeco('Passport / Aadhaar No.'),
        ),
        const SizedBox(height: 14),

        // ── Document upload ─────────────────────────────────────────────────
        Row(children: [
          // Upload button
          GestureDetector(
            onTap: onPickDoc,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: hasDoc
                  ? AtithyaColors.imperialGold.withValues(alpha: 0.12)
                  : const Color(0xFF0D0F14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasDoc
                    ? AtithyaColors.imperialGold.withValues(alpha: 0.5)
                    : AtithyaColors.imperialGold.withValues(alpha: 0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  hasDoc ? Icons.check_circle_outline : Icons.camera_alt_outlined,
                  color: AtithyaColors.imperialGold, size: 15),
                const SizedBox(width: 8),
                Text(
                  hasDoc ? 'CHANGE DOCUMENT' : 'UPLOAD / SCAN ID',
                  style: AtithyaTypography.labelMicro.copyWith(
                    color: AtithyaColors.imperialGold, letterSpacing: 1.5, fontSize: 8)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          if (hasDoc) Expanded(child: Text(
            docName ?? 'Document attached',
            style: AtithyaTypography.caption.copyWith(
              color: AtithyaColors.ashWhite.withValues(alpha: 0.5), fontSize: 10),
            overflow: TextOverflow.ellipsis,
          )),
        ]),

        // ── Image preview ───────────────────────────────────────────────────
        if (isImage && docData != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              docData!,
              height: 90,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ] else if (hasDoc && docData != null && docData!.contains('application/pdf')) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.picture_as_pdf_outlined, color: AtithyaColors.imperialGold, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(docName ?? 'PDF document',
                style: AtithyaTypography.caption.copyWith(
                  color: AtithyaColors.pearl, fontSize: 11),
                overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ],
      ]),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
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
    fillColor: const Color(0xFF0D0F14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}


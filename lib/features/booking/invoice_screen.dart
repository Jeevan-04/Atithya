// invoice_screen.dart — Royal Booking Folio / Invoice
// आतिथ्य · Luxury Hospitality
// ignore: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';

class InvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  const InvoiceScreen({super.key, required this.booking});

  Map<String, dynamic> get _estate =>
      (booking['estate'] as Map<String, dynamic>?) ?? {};

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  int _nights() {
    try {
      final ci = DateTime.parse(booking['checkInDate'].toString());
      final co = DateTime.parse(booking['checkOutDate'].toString());
      return co.difference(ci).inDays.abs().clamp(1, 999);
    } catch (_) {
      return 1;
    }
  }

  String get _bookingRef {

    final id = booking['_id']?.toString() ?? '';
    return 'ATH-${id.substring(id.length > 6 ? id.length - 6 : 0).toUpperCase()}';
  }

  void _downloadInvoice() {
    final nights  = _nights();
    final amt     = (booking['totalAmount'] as num?) ?? 0;
    final room    = (amt * 0.85).round();
    final tax     = (amt * 0.15).round();
    final status  = booking['status'] as String? ?? '';
    final addOns  = (booking['addOns'] as List?)?.cast<String>() ?? [];
    final today   = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final estTitle = _estate['title'] ?? 'Royal Estate';
    final location = '${_estate['location'] ?? ''}${_estate['city'] != null ? '  ·  ${_estate['city']}' : ''}';
    final fmt = NumberFormat('#,##,###');

    final htmlStr = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Atithya Invoice — $_bookingRef</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: #0A0B0E; color: #E8DCC8; font-family: Georgia, "Times New Roman", serif;
           padding: 32px 16px; }
    .wrapper { max-width: 620px; margin: 0 auto; background: #0C0D11;
               border: 1.5px solid rgba(201,168,76,0.25); border-radius: 16px; }
    .header { background: linear-gradient(135deg,#110E07,#0C0D11,#110E07);
              text-align: center; padding: 36px 28px 28px; border-radius:14px 14px 0 0; }
    .monogram { width:56px; height:56px; border-radius:50%;
                border:1.5px solid rgba(201,168,76,0.5); display:inline-flex;
                align-items:center; justify-content:center;
                font-size:22px; color:#C9A84C; margin-bottom:10px; }
    .brand { letter-spacing:7px; font-size:12px; color:#D4AF6A; }
    .tagline { color:rgba(232,220,200,0.4); font-style:italic; font-size:11px; margin-top:3px; }
    .inv-title { letter-spacing:5px; font-size:14px; color:#F0E8D8; margin-top:20px; }
    .estate-name { font-size:22px; color:#F0E8D8; margin-top:16px; line-height:1.2; }
    .estate-loc { color:rgba(201,168,76,0.7); font-size:12px; margin-top:6px; }
    hr.thick { border:none; border-top:1px solid rgba(201,168,76,0.2); }
    hr.thin  { border:none; border-top:0.5px solid rgba(201,168,76,0.1); margin:0 28px; }
    .meta { display:flex; gap:12px; padding:20px 28px 0; }
    .meta-col { flex:1; min-width:0; }
    .lbl { font-size:8px; letter-spacing:2px; color:rgba(232,220,200,0.35); text-transform:uppercase; }
    .val { font-size:13px; color:#F0E8D8; font-weight:600; margin-top:5px; word-break:break-word; }
    .spc { height:16px; } .spc-sm { height:8px; }
    .sec { padding:20px 28px 0; }
    .sec-head { display:flex; align-items:center; gap:8px;
                font-size:9px; letter-spacing:3px; color:#C9A84C; text-transform:uppercase; }
    .sec-head::before { content:""; display:inline-block; width:2.5px; height:12px;
                         background:#C9A84C; flex-shrink:0; }
    .blocks { display:flex; gap:20px; margin-top:14px; }
    .block { flex:1; }
    .dr-l { font-size:8px; letter-spacing:1.5px; color:rgba(232,220,200,0.3); text-transform:uppercase; }
    .dr-v { font-size:13px; color:#F0E8D8; margin:3px 0 8px; }
    .li { display:flex; align-items:flex-start; margin-bottom:10px; }
    .li-d { flex:1; }
    .li-n { font-size:13px; color:#F0E8D8; }
    .li-s { font-size:10px; color:rgba(232,220,200,0.35); margin-top:2px; }
    .li-a { font-size:14px; color:#D4AF6A; font-weight:600; white-space:nowrap; padding-left:12px; }
    .total-row { display:flex; justify-content:space-between; align-items:flex-start;
                  padding:16px 28px 0; }
    .total-lbl { font-size:9px; letter-spacing:3px; color:#C9A84C; text-transform:uppercase; }
    .total-sub { font-size:10px; color:rgba(232,220,200,0.35); margin-top:2px; }
    .total-amt { font-size:26px; color:#D4AF6A; font-weight:700; }
    .pay-row { display:flex; gap:8px; padding:14px 28px 0; font-size:11px; }
    .pay-l { color:rgba(232,220,200,0.4); } .pay-v { color:rgba(232,220,200,0.6); word-break:break-all; }
    .footer { background:#080A0D; border-radius:0 0 14px 14px;
               padding:20px 28px 28px; text-align:center; }
    .f-thank { font-size:15px; color:rgba(201,168,76,0.8); font-style:italic; }
    .f-sub { font-size:11px; color:rgba(232,220,200,0.35); font-style:italic; margin-top:6px; }
    .f-contact { font-size:9.5px; color:rgba(232,220,200,0.2); margin-top:10px; letter-spacing:0.5px; }
  </style>
</head>
<body>
<div class="wrapper">
  <div class="header">
    <div class="monogram">आ</div>
    <div class="brand">ATITHYA</div>
    <div class="tagline">Luxury Sanctuaries of India</div>
    <div class="inv-title">BOOKING INVOICE</div>
    <div class="estate-name">$estTitle</div>
    ${location.trim().isNotEmpty ? '<div class="estate-loc">$location</div>' : ''}
  </div>
  <hr class="thick">
  <div class="meta">
    <div class="meta-col"><div class="lbl">BOOKING REF</div><div class="val">$_bookingRef</div></div>
    <div class="meta-col"><div class="lbl">DATE OF ISSUE</div><div class="val">$today</div></div>
    <div class="meta-col"><div class="lbl">STATUS</div><div class="val">${status.toUpperCase()}</div></div>
  </div>
  <div class="spc"></div>
  <hr class="thin">
  <div class="sec">
    <div class="sec-head">STAY DETAILS</div>
    <div class="blocks">
      <div class="block">
        <div class="dr-l">CHECK-IN</div><div class="dr-v">${_fmt(booking['checkInDate']?.toString())}</div>
        <div class="dr-l">CHECK-OUT</div><div class="dr-v">${_fmt(booking['checkOutDate']?.toString())}</div>
        <div class="dr-l">DURATION</div><div class="dr-v">$nights night${nights != 1 ? 's' : ''}</div>
      </div>
      <div class="block">
        <div class="dr-l">GUESTS</div><div class="dr-v">${booking['guests'] ?? '—'}</div>
        <div class="dr-l">ROOM TYPE</div><div class="dr-v">${booking['roomType']?.toString() ?? '—'}</div>
        <div class="dr-l">ROOM NO.</div><div class="dr-v">${booking['roomNumber']?.toString() ?? '—'}</div>
      </div>
    </div>
    ${addOns.isNotEmpty ? '<div style="margin-top:12px"><div class="dr-l">ADD-ONS</div><div class="dr-v">${addOns.join(' · ')}</div></div>' : ''}
  </div>
  <div class="spc"></div>
  <hr class="thin">
  <div class="sec">
    <div class="sec-head">CHARGES</div>
    <div class="spc-sm"></div>
    <div class="li"><div class="li-d"><div class="li-n">Room Charges</div><div class="li-s">${_estate['roomType'] ?? booking['roomType'] ?? 'Deluxe'} × $nights nights</div></div><div class="li-a">₹${fmt.format(room)}</div></div>
    <div class="li"><div class="li-d"><div class="li-n">GST &amp; Levies (18%)</div></div><div class="li-a">₹${fmt.format(tax)}</div></div>
    ${addOns.isNotEmpty ? '<div class="li"><div class="li-d"><div class="li-n">Add-On Services</div></div><div class="li-a">Included</div></div>' : ''}
  </div>
  <div class="spc"></div>
  <hr class="thick">
  <div class="total-row">
    <div><div class="total-lbl">TOTAL AMOUNT</div><div class="total-sub">Inclusive of all taxes</div></div>
    <div class="total-amt">₹${fmt.format(amt.toInt())}</div>
  </div>
  ${booking['paymentId'] != null ? '<div class="spc-sm"></div><hr class="thin"><div class="pay-row"><span class="pay-l">Transaction:</span><span class="pay-v">${booking['paymentId']}</span></div>' : ''}
  <div class="spc"></div>
  <div class="footer">
    <div class="f-thank">Thank you for choosing Atithya</div>
    <div class="f-sub">We hope your stay was nothing short of extraordinary.</div>
    <div class="f-contact">atithya.in  ·  concierge@atithya.in</div>
    <div class="f-contact">1800-ATITHYA</div>
  </div>
</div>
</body>
</html>''';

    final bytes = utf8.encode(htmlStr);
    final blob = html.Blob([bytes], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'Atithya_Invoice_$_bookingRef.html')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final nights  = _nights();
    final amt     = (booking['totalAmount'] as num?) ?? 0;
    final room    = (amt * 0.85).round();
    final tax     = (amt * 0.15).round();
    final status  = booking['status'] as String? ?? '';
    final addOns  = (booking['addOns'] as List?)?.cast<String>() ?? [];
    final today   = DateFormat('dd MMMM yyyy').format(DateTime.now());

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
        title: Text('BOOKING FOLIO', style: AtithyaTypography.labelMicro.copyWith(
          color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 10)),
        centerTitle: false,
        actions: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _downloadInvoice();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AtithyaColors.burnishedGold, AtithyaColors.shimmerGold]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.download_outlined, color: Colors.black, size: 14),
                const SizedBox(width: 6),
                Text('DOWNLOAD', style: AtithyaTypography.labelMicro.copyWith(
                  color: Colors.black, letterSpacing: 1.5, fontSize: 9,
                  fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [

              // ── Invoice Card ─────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0D11),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AtithyaColors.imperialGold.withValues(alpha: 0.25),
                    width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AtithyaColors.imperialGold.withValues(alpha: 0.06),
                      blurRadius: 40, spreadRadius: 0),
                  ],
                ),
                child: Column(children: [

                  // ── Letterhead ─────────────────────────────────────────
                  _InvoiceHeader(estate: _estate, today: today),

                  // ── Divider ornament ────────────────────────────────────
                  _OrnamentDivider(),

                  // ── Booking meta ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _MetaCol('BOOKING REF', _bookingRef)),
                        const SizedBox(width: 12),
                        Expanded(child: _MetaCol('DATE OF ISSUE', today)),
                        const SizedBox(width: 12),
                        Expanded(child: _MetaCol('STATUS', status.toUpperCase(),
                          valueColor: _statusColor(status))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _OrnamentDivider(thin: true),

                  // ── Guest & stay details ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      _InvoiceSection('STAY DETAILS'),
                      const SizedBox(height: 14),

                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: _DetailBlock([
                          _DR('Check-In',   _fmt(booking['checkInDate']?.toString())),
                          _DR('Check-Out',  _fmt(booking['checkOutDate']?.toString())),
                          _DR('Duration',   '$nights night${nights != 1 ? 's' : ''}'),
                        ])),
                        const SizedBox(width: 20),
                        Expanded(child: _DetailBlock([
                          _DR('Guests',     '${booking['guests'] ?? '—'}'),
                          _DR('Room Type',  booking['roomType']?.toString() ?? '—'),
                          _DR('Room No.',   booking['roomNumber']?.toString() ?? '—'),
                        ])),
                      ]),

                      if (addOns.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DetailBlock([_DR('Add-Ons', addOns.join(' · '))]),
                      ],
                    ]),
                  ),

                  const SizedBox(height: 20),
                  _OrnamentDivider(thin: true),

                  // ── Line items ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _InvoiceSection('CHARGES'),
                      const SizedBox(height: 14),
                      _LineItem('Room Charges', nights,
                        '₹${NumberFormat('#,##,###').format(room)}',
                        subtitle: '${_estate['roomType'] ?? booking['roomType'] ?? 'Deluxe'} × $nights nights'),
                      const SizedBox(height: 10),
                      _LineItem('GST & Levies (18%)', null,
                        '₹${NumberFormat('#,##,###').format(tax)}'),
                      if (addOns.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _LineItem('Add-On Services', null, 'Included'),
                      ],
                    ]),
                  ),

                  const SizedBox(height: 16),
                  _OrnamentDivider(),

                  // ── Total ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('TOTAL AMOUNT', style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 9)),
                        const SizedBox(height: 2),
                        Text('Inclusive of all taxes',
                          style: AtithyaTypography.caption.copyWith(
                            color: AtithyaColors.ashWhite.withValues(alpha: 0.35), fontSize: 10)),
                      ])),
                      const SizedBox(width: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₹${NumberFormat('#,##,###').format(amt.toInt())}',
                          style: AtithyaTypography.price.copyWith(
                            fontSize: 28, color: AtithyaColors.shimmerGold),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 16),
                  _OrnamentDivider(thin: true),

                  // ── Payment ID ──────────────────────────────────────────
                  if (booking['paymentId'] != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
                      child: Row(children: [
                        const Icon(Icons.receipt_long_outlined,
                          color: AtithyaColors.imperialGold, size: 13),
                        const SizedBox(width: 8),
                        Text('Transaction: ', style: AtithyaTypography.caption.copyWith(
                          color: AtithyaColors.ashWhite.withValues(alpha: 0.4), fontSize: 11)),
                        Expanded(child: Text(booking['paymentId'].toString(),
                          style: AtithyaTypography.caption.copyWith(
                            color: AtithyaColors.ashWhite.withValues(alpha: 0.6),
                            letterSpacing: 0.5, fontSize: 11),
                          overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Footer flourish ─────────────────────────────────────
                  _InvoiceFooter(),
                ]),
              ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.04, end: 0),

              // ── Download note ─────────────────────────────────────────────
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.download_done_outlined,
                  color: AtithyaColors.ashWhite.withValues(alpha: 0.25), size: 13),
                const SizedBox(width: 6),
                Flexible(child: Text('Tap DOWNLOAD to save invoice as an HTML file',
                  style: AtithyaTypography.caption.copyWith(
                    color: AtithyaColors.ashWhite.withValues(alpha: 0.3), fontSize: 11),
                  textAlign: TextAlign.center)),
              ]).animate().fadeIn(duration: 800.ms, delay: 400.ms),
            ]),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    const map = {
      'Confirmed':    Color(0xFF4CAF50),
      'Checked In':   AtithyaColors.imperialGold,
      'Checked Out':  AtithyaColors.ashWhite,
      'Cancelled':    AtithyaColors.errorRed,
    };
    return map[s] ?? AtithyaColors.ashWhite;
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _InvoiceHeader extends StatelessWidget {
  final Map<String, dynamic> estate;
  final String today;
  const _InvoiceHeader({required this.estate, required this.today});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF110E07),
            const Color(0xFF0C0D11),
            const Color(0xFF110E07),
          ],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Brand monogram
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Center(child: Text('आ',
            style: AtithyaTypography.heroTitle.copyWith(
              color: AtithyaColors.imperialGold, fontSize: 22))),
        ),
        const SizedBox(height: 10),
        Text('ATITHYA', style: AtithyaTypography.labelMicro.copyWith(
          color: AtithyaColors.shimmerGold, letterSpacing: 7, fontSize: 12)),
        const SizedBox(height: 3),
        Text('Luxury Sanctuaries of India', style: AtithyaTypography.caption.copyWith(
          color: AtithyaColors.ashWhite.withValues(alpha: 0.4),
          fontStyle: FontStyle.italic, fontSize: 11)),
        const SizedBox(height: 22),
        Text('BOOKING INVOICE', style: AtithyaTypography.labelMicro.copyWith(
          color: AtithyaColors.pearl, letterSpacing: 5, fontSize: 14)),
        const SizedBox(height: 18),
        Text(estate['title'] ?? 'Royal Estate',
          style: AtithyaTypography.displayMedium.copyWith(
            color: AtithyaColors.pearl, fontSize: 22, height: 1.1),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
        if ((estate['city'] ?? estate['location']) != null) ...[
          const SizedBox(height: 6),
          Text(
            '${estate['location'] ?? ''}${estate['city'] != null ? '  ·  ${estate['city']}' : ''}',
            style: AtithyaTypography.bodyElegant.copyWith(
              color: AtithyaColors.imperialGold.withValues(alpha: 0.7), fontSize: 12),
            textAlign: TextAlign.center),
        ],
      ]),
    );
  }
}

class _OrnamentDivider extends StatelessWidget {
  final bool thin;
  const _OrnamentDivider({this.thin = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: thin ? 28 : 0, vertical: 0),
      child: Row(children: [
        Expanded(child: Container(
          height: thin ? 0.5 : 1,
          color: AtithyaColors.imperialGold.withValues(alpha: thin ? 0.1 : 0.2))),
        if (!thin) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.brightness_1,
              color: AtithyaColors.imperialGold.withValues(alpha: 0.4), size: 5)),
          Expanded(child: Container(height: 1,
            color: AtithyaColors.imperialGold.withValues(alpha: 0.2))),
        ],
      ]),
    );
  }
}

class _MetaCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MetaCol(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AtithyaTypography.labelMicro.copyWith(
        color: AtithyaColors.ashWhite.withValues(alpha: 0.35), fontSize: 8, letterSpacing: 2)),
      const SizedBox(height: 5),
      Text(value, style: AtithyaTypography.bodyElegant.copyWith(
        color: valueColor ?? AtithyaColors.pearl, fontSize: 13,
        fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
        maxLines: 2),
    ]);
  }
}

class _InvoiceSection extends StatelessWidget {
  final String title;
  const _InvoiceSection(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 2.5, height: 12, color: AtithyaColors.imperialGold),
      const SizedBox(width: 8),
      Text(title, style: AtithyaTypography.labelMicro.copyWith(
        color: AtithyaColors.imperialGold, letterSpacing: 3, fontSize: 9)),
    ]);
  }
}

// A row of detail key→value pairs for a block
typedef _DR = _DetailRow;

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
}

class _DetailBlock extends StatelessWidget {
  final List<_DetailRow> rows;
  const _DetailBlock(this.rows);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.label.toUpperCase(), style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.ashWhite.withValues(alpha: 0.3), fontSize: 8, letterSpacing: 1.5)),
          const SizedBox(height: 3),
          Text(r.value, style: AtithyaTypography.bodyElegant.copyWith(
            color: AtithyaColors.pearl, fontSize: 13)),
        ]),
      )).toList());
  }
}

class _LineItem extends StatelessWidget {
  final String description;
  final int? nights;
  final String amount;
  final String? subtitle;

  const _LineItem(this.description, this.nights, this.amount, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(description, style: AtithyaTypography.bodyElegant.copyWith(
          color: AtithyaColors.pearl, fontSize: 13)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AtithyaTypography.caption.copyWith(
            color: AtithyaColors.ashWhite.withValues(alpha: 0.35), fontSize: 10)),
        ],
      ])),
      Text(amount, style: AtithyaTypography.bodyElegant.copyWith(
        color: AtithyaColors.shimmerGold, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _InvoiceFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        color: const Color(0xFF080A0D),
      ),
      child: Column(children: [
        // Decorative line with diamond
        Row(children: [
          Expanded(child: Container(height: 0.5,
            color: AtithyaColors.imperialGold.withValues(alpha: 0.2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.diamond_outlined,
              color: AtithyaColors.imperialGold.withValues(alpha: 0.4), size: 12)),
          Expanded(child: Container(height: 0.5,
            color: AtithyaColors.imperialGold.withValues(alpha: 0.2))),
        ]),
        const SizedBox(height: 16),
        Text(
          'Thank you for choosing Atithya',
          style: AtithyaTypography.displaySmall.copyWith(
            color: AtithyaColors.imperialGold.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic, fontSize: 15),
          textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          'We hope your stay was nothing short of extraordinary.',
          style: AtithyaTypography.bodyElegant.copyWith(
            color: AtithyaColors.ashWhite.withValues(alpha: 0.35),
            fontStyle: FontStyle.italic, fontSize: 11),
          textAlign: TextAlign.center),
        const SizedBox(height: 14),
        Text('atithya.in  ·  concierge@atithya.in',
          style: AtithyaTypography.caption.copyWith(
            color: AtithyaColors.ashWhite.withValues(alpha: 0.2), fontSize: 9.5,
            letterSpacing: 0.5),
          textAlign: TextAlign.center),
        const SizedBox(height: 3),
        Text('1800-ATITHYA',
          style: AtithyaTypography.caption.copyWith(
            color: AtithyaColors.ashWhite.withValues(alpha: 0.2), fontSize: 9.5,
            letterSpacing: 1),
          textAlign: TextAlign.center),
      ]),
    );
  }
}

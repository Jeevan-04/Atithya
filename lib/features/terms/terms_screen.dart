// terms_screen.dart — Terms of Service & Privacy Policy
// आतिथ्य · Luxury Hospitality · Author: Jeevan Naidu

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            Text('LEGAL', style: AtithyaTypography.labelMicro.copyWith(
              color: AtithyaColors.imperialGold, fontSize: 8, letterSpacing: 3)),
            Text('Terms & Privacy', style: AtithyaTypography.displaySmall.copyWith(fontSize: 18)),
          ]),
          centerTitle: false,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'TERMS OF SERVICE'),
              Tab(text: 'PRIVACY POLICY'),
            ],
            labelStyle: AtithyaTypography.labelMicro.copyWith(fontSize: 9, letterSpacing: 2),
            unselectedLabelStyle: AtithyaTypography.caption.copyWith(fontSize: 9, letterSpacing: 1),
            labelColor: AtithyaColors.imperialGold,
            unselectedLabelColor: AtithyaColors.ashWhite,
            indicatorColor: AtithyaColors.imperialGold,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        body: TabBarView(
          children: [
            _TermsTab(),
            _PrivacyTab(),
          ],
        ),
      ),
    );
  }
}

class _TermsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _LegalContent(sections: [
      _Section('1. Acceptance of Terms',
        'By accessing and using the आतिथ्य application ("Service"), you accept and agree to be bound by the terms and provisions of this agreement. If you do not agree to abide by the above, please do not use this service.'),
      _Section('2. Booking & Reservations',
        'All bookings made through आतिथ्य are subject to availability and confirmation. A booking is considered confirmed only upon receipt of a booking confirmation email/notification and successful payment processing.\n\nReservation prices are quoted in Indian Rupees (INR) and are inclusive of applicable taxes unless stated otherwise.'),
      _Section('3. Cancellation Policy',
        'Cancellations made more than 7 days before check-in: Full refund minus payment gateway fees.\n\nCancellations made 3–7 days before check-in: 50% refund.\n\nCancellations made less than 48 hours before check-in: No refund.\n\nIn-app cancellations deduct a 20% service fee from the refundable amount. Refunds are processed within 5–7 business days.'),
      _Section('4. Check-In & Check-Out',
        'Standard check-in time is 2:00 PM and check-out time is 11:00 AM. Early check-in or late check-out may be arranged subject to availability and may incur additional charges. A valid government-issued photo ID is required at check-in.'),
      _Section('5. Guest Conduct',
        'Guests are expected to respect the estate, its surroundings, and all staff. आतिथ्य reserves the right to terminate a stay without refund if guests engage in disruptive, illegal, or destructive behaviour. Smoking is prohibited inside all estate rooms. Pets are permitted only at designated pet-friendly estates.'),
      _Section('6. Limitation of Liability',
        'आतिथ्य acts as an intermediary platform between guests and estate properties. We are not liable for any injury, loss, or damage to personal belongings during a stay. Guests are advised to obtain travel insurance. Our liability, in any event, is limited to the total booking amount paid.'),
      _Section('7. Royal Loyalty Programme',
        'Points are issued per our published earn rate and are not transferable, have no cash value, and expire after 24 months of account inactivity. आतिथ्य reserves the right to modify the Loyalty Programme terms with 30 days written notice.'),
      _Section('8. Modifications to Terms',
        'आतिथ्य reserves the right to change these terms at any time. Continued use of the Service after changes constitutes your acceptance of the new terms.'),
      _Section('9. Governing Law',
        'These terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts located in Bengaluru, Karnataka.'),
      _Section('10. Contact',
        'For any queries regarding these terms, contact us at legal@atithya.in or write to: आतिथ्य Hospitality Pvt. Ltd., 100 MG Road, Bengaluru – 560001, Karnataka, India.'),
    ]);
  }
}

class _PrivacyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _LegalContent(sections: [
      _Section('1. Information We Collect',
        'We collect information you provide directly (name, phone number, email, ID documents for check-in), information generated through your use of our platform (booking history, preferences, device information), and optional profile information (food preferences, language preference).'),
      _Section('2. How We Use Your Information',
        'To process bookings and payments.\nTo personalise your experience and recommendations.\nTo send booking confirmations, reminders, and service updates.\nTo operate our Royal Loyalty Programme.\nTo comply with legal obligations and prevent fraud.\nTo improve our platform and services.'),
      _Section('3. Data Sharing',
        'We share your information only with:\n• Estate partners — to facilitate your stay (name, contact, check-in details).\n• Payment processors — Razorpay, for secure payment handling.\n• Service providers — hosting, analytics, communications (under strict confidentiality).\n\nWe do not sell your personal data to third parties for marketing purposes.'),
      _Section('4. Data Retention',
        'We retain your personal data for as long as your account is active or as needed to provide our services. Booking records are retained for 7 years for tax and legal compliance. You may request deletion of your account data at any time.'),
      _Section('5. Security',
        'We implement industry-standard security measures including TLS encryption for all data in transit, bcrypt hashing for passwords, and regular security audits. However, no internet transmission is 100% secure and we cannot guarantee absolute security.'),
      _Section('6. Your Rights',
        'You have the right to: access the personal data we hold about you, correct inaccurate data, request deletion of your data, withdraw consent for non-essential processing, and lodge a complaint with the supervisory authority.\n\nTo exercise these rights, contact privacy@atithya.in.'),
      _Section('7. Cookies & Analytics',
        'Our web application uses session cookies for authentication. We use anonymised analytics to understand usage patterns and improve the Service. No cross-site tracking or advertising cookies are used.'),
      _Section('8. Children\'s Privacy',
        'Our Service is not directed at children under 18. We do not knowingly collect personal data from minors. If you believe a child has provided us with personal information, please contact us immediately.'),
      _Section('9. Changes to This Policy',
        'We may update this Privacy Policy periodically. We will notify you of significant changes via in-app notification and by updating the "last revised" date below.'),
      _Section('Last Revised', 'January 2025 · Version 1.2'),
    ]);
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────
class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}

class _LegalContent extends StatelessWidget {
  final List<_Section> sections;
  const _LegalContent({required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
      itemCount: sections.length,
      separatorBuilder: (_, __) => Container(
        height: 1, margin: const EdgeInsets.symmetric(vertical: 16),
        color: AtithyaColors.imperialGold.withValues(alpha: 0.08)),
      itemBuilder: (_, i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sections[i].title, style: AtithyaTypography.labelMicro.copyWith(
            color: AtithyaColors.imperialGold, letterSpacing: 1.5, fontSize: 10)),
          const SizedBox(height: 10),
          Text(sections[i].body, style: AtithyaTypography.bodyElegant.copyWith(
            color: AtithyaColors.parchment, fontSize: 13, height: 1.6)),
        ],
      ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: i * 40)),
    );
  }
}

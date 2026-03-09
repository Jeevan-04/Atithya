import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROYAL AI CONCIERGE MODAL
// ─────────────────────────────────────────────────────────────────────────────

class ConciergeModal extends StatefulWidget {
  const ConciergeModal({super.key});

  @override
  State<ConciergeModal> createState() => _ConciergeModalState();
}

class _ConciergeModalState extends State<ConciergeModal> with TickerProviderStateMixin {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late AnimationController _orbController;
  late AnimationController _ringController;
  bool _isTyping = false;

  final List<_Message> _messages = [
    _Message(
      text: 'Namaste. I am your Royal Concierge — at your service around the clock. How may I curate your stay today?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  static const List<_Suggestion> _suggestions = [
    _Suggestion(icon: '🏰', label: 'Plan my royal stay'),
    _Suggestion(icon: '🚁', label: 'Arrange helicopter transfer'),
    _Suggestion(icon: '🍽️', label: 'Book private dining'),
    _Suggestion(icon: '🧖', label: 'Reserve Ayurvedic spa'),
    _Suggestion(icon: '✦', label: 'Suggest experiences'),
    _Suggestion(icon: '🌙', label: 'Stargazing tonight'),
  ];

  // History list for context window
  List<Map<String, dynamic>> get _chatHistory => _messages
      .map((m) => {'text': m.text, 'isUser': m.isUser})
      .toList();

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _ringController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _ringController.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userText = text.trim();
    setState(() {
      _messages.add(_Message(text: userText, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    _input.clear();
    _scrollBottom();

    String reply;
    try {
      final data = await apiClient.post('/concierge/chat', {
        'message': userText,
        'history': _chatHistory.take(_chatHistory.length - 1).toList(),
      });
      reply = (data['reply'] as String?) ??
          'Your request has been thoughtfully received. I shall attend to it personally.';
    } catch (_) {
      reply = 'My deepest apologies — the royal line is momentarily engaged. Please allow me a moment to reconnect.';
    }

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_Message(text: reply, isUser: false, timestamp: DateTime.now()));
    });
    _scrollBottom();
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: 400.ms, curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      height: h * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildOrbSection(),
          _buildSuggestions(),
          const Divider(color: Color(0x22D4AF6A), height: 1),
          Expanded(child: _buildMessages()),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    ).animate().slideY(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
     .fadeIn(duration: 400.ms);
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 36, height: 4,
        decoration: BoxDecoration(
          color: const Color(0x44D4AF6A),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AtithyaColors.shimmerGold, AtithyaColors.burnishedGold],
              ),
            ),
            child: const Center(
              child: Text('≈', style: TextStyle(color: AtithyaColors.obsidian, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Royal Concierge', style: AtithyaTypography.labelSmall.copyWith(
                color: AtithyaColors.imperialGold, letterSpacing: 2.5, fontSize: 11)),
              Text('AI-Powered · Always Available', style: AtithyaTypography.labelSmall.copyWith(
                color: Colors.white38, letterSpacing: 0.5, fontSize: 10)),
            ],
          ),
          const Spacer(),
          Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50))),
          const SizedBox(width: 4),
          Text('Online', style: AtithyaTypography.labelSmall.copyWith(color: const Color(0xFF4CAF50), fontSize: 10)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.white38, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbSection() {
    return SizedBox(
      height: 100,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_orbController, _ringController]),
          builder: (_, __) => SizedBox(
            width: 100, height: 100,
            child: CustomPaint(painter: _ConciergeOrbPainter(_orbController.value, _ringController.value)),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _suggestions[i];
          return GestureDetector(
            onTap: () => _sendMessage(s.label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x33D4AF6A)),
                color: const Color(0x0AD4AF6A),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(s.label, style: AtithyaTypography.labelSmall.copyWith(
                    color: const Color(0xCCF7F2E8), fontSize: 11, letterSpacing: 0.3)),
                ],
              ),
            ),
          ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(_Message msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 10, left: isUser ? 48 : 0, right: isUser ? 0 : 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          gradient: isUser ? const LinearGradient(
            colors: [Color(0xFFC09040), Color(0xFF8B6520)],
            begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
          color: isUser ? null : const Color(0xFF1A1C22),
          border: isUser ? null : Border.all(color: const Color(0x22D4AF6A)),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('Royal Concierge', style: AtithyaTypography.labelSmall.copyWith(
                  color: AtithyaColors.imperialGold, fontSize: 9, letterSpacing: 1.5)),
              ),
            Text(msg.text, style: AtithyaTypography.bodyElegant.copyWith(
              color: isUser ? AtithyaColors.obsidian : const Color(0xEEF7F2E8),
              fontSize: 13.5, height: 1.55,
              fontWeight: isUser ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    ).animate(delay: 50.ms).fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x22D4AF6A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              width: 6, height: 6,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xAAD4AF6A)),
            ).animate(onPlay: (c) => c.repeat(reverse: true), delay: (i * 200).ms)
             .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeInOut)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x22D4AF6A)))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF1A1C22),
                border: Border.all(color: const Color(0x33D4AF6A)),
              ),
              child: TextField(
                controller: _input,
                style: AtithyaTypography.bodyElegant.copyWith(color: const Color(0xEEF7F2E8), fontSize: 14),
                cursorColor: AtithyaColors.imperialGold,
                decoration: InputDecoration(
                  hintText: 'Ask the Royal Concierge…',
                  hintStyle: AtithyaTypography.bodyElegant.copyWith(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_input.text),
            child: Container(
              width: 46, height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AtithyaColors.shimmerGold, AtithyaColors.burnishedGold],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: AtithyaColors.obsidian, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  _Message({required this.text, required this.isUser, required this.timestamp});
}

class _Suggestion {
  final String icon;
  final String label;
  const _Suggestion({required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// ORB PAINTER — animated concentric rings + radial gradient core
// ─────────────────────────────────────────────────────────────────────────────

class _ConciergeOrbPainter extends CustomPainter {
  final double pulseValue;
  final double rotValue;
  _ConciergeOrbPainter(this.pulseValue, this.rotValue);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(c, r * (0.9 + 0.1 * pulseValue), Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28)
      ..color = AtithyaColors.imperialGold.withValues(alpha: 0.12));

    // Rotating ring 1
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotValue * 2 * math.pi);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.78), 0, math.pi * 1.4, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AtithyaColors.imperialGold.withValues(alpha: 0.4));
    canvas.restore();

    // Rotating ring 2 (opposite)
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-rotValue * 2 * math.pi * 0.7);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.62), 0, math.pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AtithyaColors.burnishedGold.withValues(alpha: 0.3));
    canvas.restore();

    // Core gradient orb
    final scale = 0.42 + 0.06 * pulseValue;
    canvas.drawCircle(c, r * scale, Paint()
      ..shader = RadialGradient(colors: [
        AtithyaColors.shimmerGold.withValues(alpha: 0.9),
        AtithyaColors.burnishedGold.withValues(alpha: 0.5),
        AtithyaColors.imperialGold.withValues(alpha: 0.0),
      ], stops: const [0, 0.5, 1]).createShader(Rect.fromCircle(center: c, radius: r * scale)));

    final tp = TextPainter(
      text: const TextSpan(text: '≈', style: TextStyle(color: Color(0xFFD4AF6A), fontSize: 16, fontWeight: FontWeight.w300)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ConciergeOrbPainter old) => pulseValue != old.pulseValue || rotValue != old.rotValue;
}

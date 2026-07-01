import 'package:flutter/material.dart';

/// Help & Support — searchable FAQ list. Opens from the Account page's
/// "Support" row.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const Color _blue = Color(0xFF2F80ED);
  static const Color _border = Color(0xFFECECEC);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _idleIcon = Color(0xFF9AA0A6);

  // Same placeholder copy for every question for now.
  static const String _defaultAnswer =
      'We take your privacy seriously. Your personal information is protected '
      'through security measures and data encryption. You can control your '
      'privacy settings to determine who can view your content and interact '
      'with you.';

  static const List<_Faq> _faqs = [
    _Faq(question: 'What is the You2Art?', answer: _defaultAnswer),
    _Faq(question: 'How do I create an account on the You2Art?', answer: _defaultAnswer),
    _Faq(question: 'What types of content can I share on the app?', answer: _defaultAnswer),
    _Faq(question: 'How can I interact with other users?', answer: _defaultAnswer),
    _Faq(question: 'Is my personal information safe on the app?', answer: _defaultAnswer),
    _Faq(question: 'How can I discover actors and directors?', answer: _defaultAnswer),
    _Faq(question: 'Can I customize my feed to see specific types of art?', answer: _defaultAnswer),
    _Faq(question: 'How can I provide feedback or report inappropriate content?', answer: _defaultAnswer),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(
                'Help & Support',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border, width: 1.4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: _idleIcon, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Search',
                      style: TextStyle(color: _textSecondary, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
            ),
            const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
            for (final f in _faqs) ...[
              Builder(
                builder: (ctx) => _faqRow(
                  f,
                  onTap: () => _showAnswer(ctx, f),
                ),
              ),
              const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _faqRow(_Faq f, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                f.question,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Image.asset(
              'assets/images/arrow_icon.png',
              width: 18,
              height: 18,
              color: _blue,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.arrow_forward, color: _blue, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnswer(BuildContext context, _Faq f) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FaqAnswerSheet(faq: f),
    );
  }
}

class _Faq {
  const _Faq({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _FaqAnswerSheet extends StatelessWidget {
  const _FaqAnswerSheet({required this.faq});
  final _Faq faq;

  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 10, 20, 56 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle.
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  faq.question,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(Icons.close, size: 18, color: _textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Full-bleed divider — breaks out of the sheet's 24/20 horizontal
          // padding so it spans the entire screen width.
          SizedBox(
            height: 1,
            child: OverflowBox(
              maxWidth: MediaQuery.sizeOf(context).width,
              child: Container(height: 1, color: const Color(0xFFEFEFEF)),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              faq.answer,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

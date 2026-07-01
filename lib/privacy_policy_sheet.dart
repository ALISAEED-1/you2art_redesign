import 'package:flutter/material.dart';

/// Bottom sheet displaying the Privacy Policy document.
///
/// Opens from the Account page's "Privacy Policy" row.
Future<void> showPrivacyPolicySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PrivacyPolicySheet(),
  );
}

class _PrivacyPolicySheet extends StatelessWidget {
  const _PrivacyPolicySheet();

  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 18),
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header: title + close + effective date ──────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 4),
                    const Text(
                      'Effective Date: 25 Nov, 2022',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Full-bleed divider ──────────────────────────────────
              SizedBox(
                height: 1,
                child: OverflowBox(
                  maxWidth: MediaQuery.sizeOf(context).width,
                  child: Container(height: 1, color: const Color(0xFFEFEFEF)),
                ),
              ),

              // ── Scrollable body ─────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                  children: const [
                    _SectionHeading('1. Introduction'),
                    SizedBox(height: 8),
                    _Paragraph(
                      'Welcome to the You2Art App ("App", "We", "Us", or '
                      '"Our"). This Privacy Policy outlines how we collect, '
                      'use, disclose, and protect your personal information '
                      'when you use the App. By using the App, you agree to '
                      'the terms and practices described in this Privacy '
                      'Policy.',
                    ),
                    SizedBox(height: 18),
                    _SectionHeading('2. Information We Collect'),
                    SizedBox(height: 8),
                    _Paragraph(
                      '2.1 Personal Information: When you create an account, '
                      'we may collect personal information such as your '
                      'name, email address, profile picture, and location.',
                    ),
                    SizedBox(height: 10),
                    _Paragraph(
                      '2.2 User Content: The App allows you to post and '
                      'share User Content. This content may contain '
                      'personal information that you choose to share with '
                      'others.',
                    ),
                    SizedBox(height: 10),
                    _Paragraph(
                      '2.3 Usage Data: We collect information about your '
                      'interactions with the App, including log data, '
                      'device information, and usage patterns.',
                    ),
                    SizedBox(height: 18),
                    _SectionHeading('3. How We Use Your Information'),
                    SizedBox(height: 8),
                    _Paragraph(
                      '3.1 Providing Services: We use your information to '
                      'provide and improve the services offered by the App, '
                      'including personalized content and recommendations.',
                    ),
                    SizedBox(height: 10),
                    _Paragraph(
                      '3.2 Communication: We may use your email address to '
                      'send you notifications, updates, and marketing '
                      'materials related to the App. You can opt out of '
                      'these communications at any time.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _PrivacyPolicySheet._textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _PrivacyPolicySheet._textPrimary,
        fontSize: 13.5,
        height: 1.55,
      ),
    );
  }
}

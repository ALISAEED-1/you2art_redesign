import 'package:flutter/material.dart';

/// Bottom sheet displaying the Terms & Conditions document.
///
/// Opens from the Account page's "Terms & Conditions" row.
Future<void> showTermsAndConditionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TermsAndConditionsSheet(),
  );
}

class _TermsAndConditionsSheet extends StatelessWidget {
  const _TermsAndConditionsSheet();

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
                            'Terms & Conditions',
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
                    Text(
                      'Welcome to You2Art ("App", "We", "Us", or "Our"). By '
                      'using or accessing the You2Art App, you agree to '
                      'comply with and be bound by the following Terms and '
                      'Conditions ("Terms"). If you do not agree to these '
                      'Terms, please do not use the App.',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    SizedBox(height: 18),
                    _SectionHeading('1. Acceptance of Terms'),
                    SizedBox(height: 8),
                    _Paragraph(
                      'By using the You2Art App, you confirm that you are at '
                      'least 18 years of age or have obtained consent from a '
                      'legal guardian. These Terms constitute a legally '
                      'binding agreement between you and You2Art.',
                    ),
                    SizedBox(height: 18),
                    _SectionHeading('2. User Accounts'),
                    SizedBox(height: 8),
                    _Paragraph(
                      '2.1 You may need to create a user account to access '
                      'certain features of the App. You are responsible for '
                      'maintaining the confidentiality of your account '
                      'credentials.',
                    ),
                    SizedBox(height: 10),
                    _Paragraph(
                      '2.2 You agree to provide accurate and complete '
                      'information during the registration process and to '
                      'update such information to keep it accurate and '
                      'current.',
                    ),
                    SizedBox(height: 18),
                    _SectionHeading('3. Content'),
                    SizedBox(height: 8),
                    _Paragraph(
                      '3.1 The App allows users to post, upload, share, and '
                      'access various types of content, including text, '
                      'images, audio, and videos ("User Content").',
                    ),
                    SizedBox(height: 10),
                    _Paragraph(
                      '3.2 You retain ownership of your User Content. '
                      'However, by submitting User Content, you grant '
                      'You2Art a non-exclusive, worldwide, royalty-free, '
                      'sublicensable, and transferable license to use, '
                      'reproduce, modify, adapt, publish, and display the '
                      'User Content for the purpose of providing the App.',
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
        color: _TermsAndConditionsSheet._textPrimary,
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
        color: _TermsAndConditionsSheet._textPrimary,
        fontSize: 13.5,
        height: 1.55,
      ),
    );
  }
}

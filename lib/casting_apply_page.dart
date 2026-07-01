import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/models/casting_call.dart';
import 'providers/casting_provider.dart';
import 'providers/profile_provider.dart';

/// Application form opened when the user taps "Apply Now" on a casting call.
class CastingApplyPage extends StatefulWidget {
  const CastingApplyPage({super.key, required this.call});

  final CastingCall call;

  @override
  State<CastingApplyPage> createState() => _CastingApplyPageState();
}

class _CastingApplyPageState extends State<CastingApplyPage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _summaryBg = Color(0xFFF4F5F7);
  static const Color _cancelBg = Color(0xFFFFE4E4);
  static const Color _cancelText = Color(0xFFE53935);
  static const Color _border = Color(0xFFECECEC);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _genderController = TextEditingController();
  final _experienceController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _genderController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final profile = context.read<ProfileProvider>().profile;
    final casting = context.read<CastingProvider>();
    final ok = await casting.apply(
      callId: widget.call.id,
      name: (profile?.fullName.isNotEmpty ?? false)
          ? profile!.fullName
          : 'You2Art User',
      photo: profile?.avatarUrl ?? 'assets/images/profile_pic.png',
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      note: _noteController.text.trim(),
      age: _ageController.text.trim(),
      height: _heightController.text.trim(),
      gender: _genderController.text.trim(),
      experience: _experienceController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted!')),
      );
      Navigator.of(context).maybePop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(casting.error ?? 'Could not submit application.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<CastingProvider>().busy;
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  const Text(
                    'Applying to',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _summaryCard(),
                  const SizedBox(height: 20),
                  _field(
                    label: 'Contact Number',
                    hint: 'Contact Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  _field(
                    label: 'Contact Email',
                    hint: 'Contact Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          label: 'Age',
                          hint: '23',
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _field(
                          label: 'Height',
                          hint: '5.9 Feet',
                          controller: _heightController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          label: 'Gender',
                          hint: 'Male',
                          controller: _genderController,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _field(
                          label: 'Experience',
                          hint: '5 Years',
                          controller: _experienceController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _field(
                    label: 'Note to Makers',
                    hint: 'Write your note',
                    controller: _noteController,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            // ── Bottom action bar ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            busy ? null : () => Navigator.of(context).maybePop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cancelBg,
                          foregroundColor: _cancelText,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: busy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.black54,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary card: title + author + stats row ─────────────────────────
  Widget _summaryCard() {
    final call = widget.call;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _summaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEDEDED),
                backgroundImage: call.ownerPhoto.startsWith('http')
                    ? NetworkImage(call.ownerPhoto)
                    : AssetImage(call.ownerPhoto) as ImageProvider,
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.projectTitle,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                        children: [
                          const TextSpan(text: 'by '),
                          TextSpan(
                            text: call.ownerName,
                            style: const TextStyle(
                              color: _blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Row(
              children: [
                Expanded(child: _stat('Location', call.locationLabel)),
                Expanded(child: _stat('Type', call.typeLabel)),
                Expanded(child: _stat('Shoot', call.shootLabel)),
                Expanded(child: _stat('Budget', call.budgetLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          cursorColor: Colors.black,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border, width: 1.4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _textSecondary, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/casting_provider.dart';
import 'providers/profile_provider.dart';

/// "Create Casting Call" form — opens from the "+ Create Casting Call" button
/// on the My Casting Calls tab.
class CastingCreatePage extends StatefulWidget {
  const CastingCreatePage({super.key});

  @override
  State<CastingCreatePage> createState() => _CastingCreatePageState();
}

class _CastingCreatePageState extends State<CastingCreatePage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _cancelBg = Color(0xFFFFE4E4);
  static const Color _cancelText = Color(0xFFE53935);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _required = Color(0xFFE53935);

  // ── Controllers ─────────────────────────────────────────────────────
  final _title = TextEditingController();
  final _shortDescription = TextEditingController();
  final _city = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _roleTitle = TextEditingController();
  final _roleDescription = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _shootDetails = TextEditingController();
  final _budget = TextEditingController();

  String? _crewType;
  String? _gender;

  static const List<String> _crewTypes = ['Crew Type 1', 'Crew Type 2', 'Crew Type 3'];
  static const List<String> _genders = ['Male', 'Female', 'Either'];

  @override
  void dispose() {
    _title.dispose();
    _shortDescription.dispose();
    _city.dispose();
    _email.dispose();
    _phone.dispose();
    _roleTitle.dispose();
    _roleDescription.dispose();
    _age.dispose();
    _height.dispose();
    _shootDetails.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project title.')),
      );
      return;
    }
    final profile = context.read<ProfileProvider>().profile;
    final casting = context.read<CastingProvider>();
    final ok = await casting.createCall({
      'owner_name': (profile?.fullName.isNotEmpty ?? false)
          ? profile!.fullName
          : 'You2Art User',
      'owner_photo': profile?.avatarUrl ?? 'assets/images/profile_pic.png',
      'project_title': _title.text.trim(),
      'short_description': _shortDescription.text.trim(),
      'location': _city.text.trim(),
      'location_full': _city.text.trim(),
      'type': _crewType,
      'shoot_details': _shootDetails.text.trim(),
      'budget': _budget.text.trim(),
      'budget_full': _budget.text.trim(),
      'position': _roleTitle.text.trim(),
      'age': _age.text.trim(),
      'height': _height.text.trim(),
      'gender': _gender,
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
    });
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(casting.error ?? 'Could not publish casting call.'),
        ),
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
                    'Create Casting Call',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    label: 'Project Title',
                    required: true,
                    hint: 'Enter Project Title',
                    controller: _title,
                  ),
                  _textField(
                    label: 'Short Description',
                    required: true,
                    hint: 'Enter short description',
                    controller: _shortDescription,
                    maxLines: 6,
                  ),
                  _dropdownField(
                    label: 'Crew Required',
                    required: true,
                    hint: 'Crew Type',
                    value: _crewType,
                    items: _crewTypes,
                    onChanged: (v) => setState(() => _crewType = v),
                  ),
                  _textField(
                    label: 'City Name',
                    required: true,
                    hint: 'Enter City Name',
                    controller: _city,
                  ),
                  _textField(
                    label: 'Contact Email',
                    hint: 'Enter Contact Email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _textField(
                    label: 'Contact Number',
                    hint: 'Enter Contact Number',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _textField(
                    label: 'Role Title',
                    hint: 'Role Title',
                    controller: _roleTitle,
                  ),
                  _textField(
                    label: 'Role Description',
                    hint: 'Role Description',
                    controller: _roleDescription,
                    maxLines: 6,
                  ),
                  _textField(
                    label: 'Age Required',
                    hint: '23',
                    controller: _age,
                    keyboardType: TextInputType.number,
                  ),
                  _textField(
                    label: 'Height Required (in Feet)',
                    hint: '5.9',
                    controller: _height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  _dropdownField(
                    label: 'Gender',
                    required: true,
                    hint: 'Male Only',
                    value: _gender,
                    items: _genders,
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  _textField(
                    label: 'Shoot Details',
                    hint: 'Enter Shoot Details',
                    controller: _shootDetails,
                    maxLines: 6,
                  ),
                  _textField(
                    label: 'Budget / Remuneration',
                    hint: 'Enter Your Budget',
                    controller: _budget,
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

  // ── Helpers ──────────────────────────────────────────────────────────
  static const Color _fieldBorder = Color(0xFFE6E9EE);

  Widget _fieldShell({required Widget label, required Widget input}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 10),
          input,
        ],
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: _required,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return _fieldShell(
      label: _label(label, required: required),
      input: TextField(
        controller: controller,
        cursorColor: Colors.black,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: _textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _fieldBorder, width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _textSecondary, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    return _fieldShell(
      label: _label(label, required: required),
      input: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        hint: Text(
          hint,
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: _textSecondary),
        style: const TextStyle(color: _textPrimary, fontSize: 14),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _fieldBorder, width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _textSecondary, width: 1.4),
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

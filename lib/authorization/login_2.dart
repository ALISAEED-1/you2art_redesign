import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home_page.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'account_created_dialog.dart';
import 'widgets/dial_keypad.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _otpDigits = ['', '', '', '', '', ''];
  int _focusedIndex = 0; // Cursor starts on the first (empty) box.

  bool _showKeypad = true;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  // -- Exact Design Theme Colors --
  static const Color _bgWhite = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF000000);
  static const Color _textSecondary = Color(0xFF7A7A7A);
  static const Color _borderColor = Color(0xFFE8E8E8);
  static const Color _linkBlue = Color(0xFF3399FF);

  @override
  void initState() {
    super.initState();
    // Pre-filling 5, 3, 5 as displayed in reference image

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onBoxTap(int index) {
    setState(() {
      _focusedIndex = index;
      if (!_showKeypad) {
        _showKeypad = true;
        _animController.forward();
      }
    });
  }

  void _onKeyTap(String value) {
    if (value == 'back') {
      setState(() {
        if (_otpDigits[_focusedIndex].isNotEmpty) {
          _otpDigits[_focusedIndex] = '';
        } else if (_focusedIndex > 0) {
          _focusedIndex--;
          _otpDigits[_focusedIndex] = '';
        }
      });
    } else if (value == '+*#' || value == '') {
      // Non-functional background keys
    } else {
      setState(() {
        _otpDigits[_focusedIndex] = value;
        if (_focusedIndex < 5) {
          _focusedIndex++;
        }
      });
    }
  }

  void _dismissKeypad() {
    if (_showKeypad) {
      _animController.reverse().then((_) {
        setState(() => _showKeypad = false);
      });
    }
  }

  Future<void> _onVerify() async {
    final code = _otpDigits.join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(code);
    if (!mounted) return;

    if (ok) {
      // Returning users (profile already complete) skip onboarding.
      await context.read<ProfileProvider>().loadMyProfile();
      if (!mounted) return;
      final profile = context.read<ProfileProvider>().profile;
      final complete = (profile?.firstName ?? '').trim().isNotEmpty;
      if (complete) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        showAccountCreatedSheet(context);
      }
    } else {
      // Clear the boxes so the user can re-enter cleanly.
      setState(() {
        for (var i = 0; i < _otpDigits.length; i++) {
          _otpDigits[i] = '';
        }
        _focusedIndex = 0;
      });
      final raw = (auth.errorMessage ?? '').toLowerCase();
      final friendly = raw.contains('expired')
          ? 'This code has expired. Please tap Resend to get a new one.'
          : (raw.contains('invalid') || raw.contains('token') || raw.isEmpty)
              ? 'The code you entered is incorrect. Please check it and try again.'
              : (auth.errorMessage ?? 'The code you entered is incorrect.');
      await _showOtpErrorDialog(friendly);
    }
  }

  /// A centered popup shown when OTP verification fails.
  Future<void> _showOtpErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFFE53935), size: 36),
              ),
              const SizedBox(height: 18),
              const Text(
                'Incorrect Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A7A7A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onResend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'A new code has been sent.' : (auth.errorMessage ?? 'Could not resend.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width * 0.06;
    final auth = context.watch<AuthProvider>();
    final verifying = auth.status == AuthStatus.verifying;

    return Scaffold(
      backgroundColor: _bgWhite,
      body: GestureDetector(
        onTap: _dismissKeypad,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Back Button Navigation Arrow --------------------
              Padding(
                padding: EdgeInsets.fromLTRB(hPad * 0.7, size.height * 0.015, hPad, 0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: _textPrimary, size: 26),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),

              // -- Main Header and Input Area ----------------------
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, size.height * 0.02, hPad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Header
                    Text(
                      'Verify Your Account',
                      style: TextStyle(
                        fontSize: size.width * 0.082,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),

                    // Label Input
                    Text(
                      'Enter OTP',
                      style: TextStyle(
                        fontSize: size.width * 0.038,
                        color: _textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: size.height * 0.012),

                    // 6-Digit OTP Boxes Row Layout Container
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final isFocused = _focusedIndex == index && _showKeypad;
                        return GestureDetector(
                          onTap: () => _onBoxTap(index),
                          child: Container(
                            width: size.width * 0.125,
                            height: size.width * 0.125,
                            decoration: BoxDecoration(
                              color: _bgWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFocused ? Colors.black38 : _borderColor,
                                width: isFocused ? 1.5 : 1.2,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  _otpDigits[index],
                                  style: TextStyle(
                                    fontSize: size.width * 0.048,
                                    fontWeight: FontWeight.w500,
                                    color: _textPrimary,
                                  ),
                                ),
                                if (isFocused && _otpDigits[index].isEmpty)
                                  const BlinkingCursor(
                                    color: Colors.black45,
                                    height: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: size.height * 0.025),

                    // Descriptive Subtitle Info Layout Text
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: size.width * 0.032,
                          color: _textSecondary,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Please enter '),
                          const TextSpan(
                            text: '6 digits OTP',
                            style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' you received on your registered\nphone '),
                          TextSpan(
                            text: auth.maskedPhone,
                            style: const TextStyle(
                              color: _linkBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.018),

                    // Resend code link
                    GestureDetector(
                      onTap: verifying ? null : _onResend,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        "Didn't get the code? Resend",
                        style: TextStyle(
                          fontSize: size.width * 0.032,
                          color: _linkBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // -- Bottom Persistent Section Containing Verify Button --
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Verification Execution Button Block
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: SizedBox(
                      width: double.infinity,
                      height: size.height * 0.062,
                      child: ElevatedButton(
                        onPressed: verifying ? null : _onVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.black54,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: verifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Verify',
                                style: TextStyle(
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.018),

                  // Terms & Conditions Reference Text
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: RichText(
                        textAlign: TextAlign.left,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: size.width * 0.028,
                            color: _textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'by Signing In, you agree with the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                color: _linkBlue,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const TextSpan(text: ' of\n'),
                            const TextSpan(
                              text: 'You2Art',
                              style: TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.02),

                  // Native Styled Keypad Engine Output
                  SizeTransition(
                    sizeFactor: _slideAnimation,
                    axisAlignment: -1,
                    child: DialKeypad(onKeyTap: _onKeyTap),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

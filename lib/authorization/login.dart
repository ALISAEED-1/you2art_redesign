import 'package:country_flags/country_flags.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_2.dart';
import 'widgets/dial_keypad.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();

  // Selected country — defaults to India (+91), matching the original design.
  String _countryCode = 'IN';
  String _phoneCode = '91';

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
     // Pre-filled cursor state text matching typical Pakistan provider codes
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
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onFieldTap() {
    if (!_showKeypad) {
      setState(() => _showKeypad = true);
      _animController.forward();
    }
  }

  void _onKeyTap(String value) {
    if (value == 'back') {
      if (_phoneController.text.isNotEmpty) {
        setState(() {
          _phoneController.text =
              _phoneController.text.substring(0, _phoneController.text.length - 1);
        });
      }
    } else if (value == '+*#' || value == '') {
      // Non-functional background key action handles
    } else {
      // E.164 numbers are at most 15 digits incl. the country code.
      if (_phoneController.text.length < 15) {
        setState(() {
          _phoneController.text += value;
        });
      }
    }
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const ['IN', 'PK', 'US', 'GB', 'AE'],
      customFlagBuilder: (country) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: CountryFlag.fromCountryCode(
          country.countryCode,
          theme: const ImageTheme(
            height: 22,
            width: 30,
            shape: RoundedRectangle(3),
          ),
        ),
      ),
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9AA0A6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3399FF)),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _countryCode = country.countryCode;
          _phoneCode = country.phoneCode;
        });
      },
    );
  }

  Future<void> _onSendOtp() async {
    final national = _phoneController.text.trim();
    if (national.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.setPhone(phoneCode: _phoneCode, national: national);
    final ok = await auth.sendOtp();
    if (!mounted) return;

    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VerifyScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Could not send the code.')),
      );
    }
  }

  void _dismissKeypad() {
    if (_showKeypad) {
      _animController.reverse().then((_) {
        setState(() => _showKeypad = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width * 0.06;
    final sending =
        context.watch<AuthProvider>().status == AuthStatus.sendingOtp;

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
              // -- Logo + Form --------------------------------------
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, size.height * 0.022, hPad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Image Matching Component Fixed Scaling
                    Image.asset(
                      'assets/images/y2logo.png',
                      width: size.width * 0.32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback visually reminiscent of logo structure if image is missing locally
                        return Container(
                          width: size.width * 0.32,
                          height: size.height * 0.08,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE52321),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: Text(
                              'Y2A',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: size.height * 0.012),

                    // Title Login
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: size.width * 0.085,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: size.height * 0.025),

                    // Label Input
                    Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: size.width * 0.036,
                        color: Color(0xff262626),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: size.height * 0.008),

                    // Two Separate Input Boxes Layout Block
                    Row(
                      children: [
                        // 1. Tappable Box for Country Flag & Dial Code
                        GestureDetector(
                          onTap: _openCountryPicker,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.03,
                            ),
                            height: size.height * 0.062,
                            decoration: BoxDecoration(
                              color: _bgWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _borderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CountryFlag.fromCountryCode(
                                  _countryCode,
                                  theme: ImageTheme(
                                    height: size.width * 0.05,
                                    width: size.width * 0.07,
                                    shape: const RoundedRectangle(3),
                                  ),
                                ),
                                SizedBox(width: size.width * 0.02),
                                Text(
                                  '+$_phoneCode',
                                  style: TextStyle(
                                    fontSize: size.width * 0.038,
                                    color: _textPrimary,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: size.width * 0.05,
                                  color: _textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),

                        // 2. Rectangular Box for Input Digits
                        Expanded(
                          child: GestureDetector(
                            onTap: _onFieldTap,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.035,
                              ),
                              height: size.height * 0.062,
                              decoration: BoxDecoration(
                                color: _bgWhite,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _borderColor,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _phoneController.text,
                                    style: TextStyle(
                                      fontSize: size.width * 0.04,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  if (_showKeypad)
                                    const BlinkingCursor(color: _textPrimary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // -- Bottom Section Containing OTP Button & Terms ------
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Send OTP Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: SizedBox(
                      width: double.infinity,
                      height: size.height * 0.062,
                      child: ElevatedButton(
                        onPressed: sending ? null : _onSendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.black54,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Send OTP',
                                style: TextStyle(
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.018),

                  // Terms and conditions section
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

                  // Fixed Native iOS Platform UI Styled Keypad
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

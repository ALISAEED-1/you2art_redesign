import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repository.dart';

/// Where we are in the phone → OTP → verified flow.
enum AuthStatus { idle, sendingOtp, otpSent, verifying, authenticated, error }

/// App-wide auth state for the phone-OTP login flow.
///
/// Exposed through `provider`; screens read it with `context.watch/read`.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repo = repository ?? AuthRepository();

  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.idle;
  AuthStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// E.164 phone currently being verified, e.g. "+923001234567".
  String? _phoneE164;
  String? get phoneE164 => _phoneE164;

  /// True while an OTP send or verify is in flight.
  bool get isBusy =>
      _status == AuthStatus.sendingOtp || _status == AuthStatus.verifying;

  /// Whether a valid session currently exists.
  bool get isAuthenticated => _repo.currentSession != null;

  /// Masked phone for display, e.g. "+92300*****67".
  String get maskedPhone {
    final p = _phoneE164 ?? '';
    if (p.length <= 8) return p;
    final start = p.substring(0, 6);
    final end = p.substring(p.length - 2);
    final stars = '*' * (p.length - 8);
    return '$start$stars$end';
  }

  /// Builds the E.164 number from a dial [phoneCode] (e.g. "92") and the
  /// [national] digits the user typed.
  ///
  /// Strips a leading trunk "0" (e.g. Pakistan's domestic "0300...") since
  /// E.164 never includes it — otherwise "+92" + "03001112233" would wrongly
  /// become "+9203001112233" instead of "+923001112233".
  void setPhone({required String phoneCode, required String national}) {
    var digits = national.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    _phoneE164 = '+$phoneCode$digits';
  }

  /// Sends the OTP. Returns true on success.
  Future<bool> sendOtp() async {
    final phone = _phoneE164;
    if (phone == null || phone.replaceAll(RegExp(r'\D'), '').length < 7) {
      _fail('Please enter a valid phone number.');
      return false;
    }
    _setStatus(AuthStatus.sendingOtp);
    try {
      await _repo.sendOtp(phone);
      _setStatus(AuthStatus.otpSent);
      return true;
    } on AuthException catch (e) {
      _fail(e.message);
      return false;
    } catch (_) {
      _fail('Could not send the code. Please try again.');
      return false;
    }
  }

  /// Verifies the entered [code]. Returns true on success.
  Future<bool> verifyOtp(String code) async {
    final phone = _phoneE164;
    if (phone == null) {
      _fail('Please request a code first.');
      return false;
    }
    if (code.length < 6) {
      _fail('Enter the 6-digit code.');
      return false;
    }
    _setStatus(AuthStatus.verifying);
    try {
      final res = await _repo.verifyOtp(phoneE164: phone, token: code);
      if (res.session != null) {
        _setStatus(AuthStatus.authenticated);
        return true;
      }
      _fail('Verification failed. Please try again.');
      return false;
    } on AuthException catch (e) {
      _fail(e.message);
      return false;
    } catch (_) {
      _fail('Could not verify the code. Please try again.');
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _phoneE164 = null;
    _setStatus(AuthStatus.idle);
  }

  /// Clears a previous error so the UI can return to a neutral state.
  void clearError() {
    if (_status == AuthStatus.error) {
      _errorMessage = null;
      _setStatus(AuthStatus.idle);
    }
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    if (status != AuthStatus.error) _errorMessage = null;
    notifyListeners();
  }

  void _fail(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/models/profile.dart';
import '../data/repositories/profile_repository.dart';

/// App-wide profile state: the signed-in user's profile plus the save actions
/// used by Choose Category and Complete Profile.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({ProfileRepository? repository})
      : _repo = repository ?? ProfileRepository();

  final ProfileRepository _repo;

  Profile? _profile;
  Profile? get profile => _profile;

  bool _saving = false;
  bool get saving => _saving;

  String? _error;
  String? get error => _error;

  /// Clears the cached profile (on logout).
  void clear() {
    _profile = null;
    _error = null;
    notifyListeners();
  }

  /// Loads the current user's profile into [profile].
  Future<void> loadMyProfile() async {
    try {
      _profile = await _repo.fetchMyProfile();
      notifyListeners();
    } catch (_) {
      // Non-fatal: screens fall back to their placeholder content.
    }
  }

  /// Saves the chosen [category] (from the Choose Category screen).
  Future<bool> saveCategory(String category) {
    return _run(() async {
      _profile = await _repo.updateMyProfile({'category': category});
    });
  }

  /// Saves the Complete Profile form fields.
  Future<bool> completeProfile({
    required String firstName,
    required String lastName,
    String? country,
    String? city,
    required String bio,
  }) {
    return _run(() async {
      _profile = await _repo.updateMyProfile({
        'first_name': firstName,
        'last_name': lastName,
        'country': country,
        'city': city,
        'bio': bio,
      });
    });
  }

  /// Uploads [file] as the profile photo and stores its public URL.
  Future<bool> uploadAvatar(File file) {
    return _run(() async {
      final url = await _repo.uploadAvatar(file);
      _profile = await _repo.updateMyProfile({'avatar_url': url});
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _saving = false;
      _error = _friendly(e);
      notifyListeners();
      return false;
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    return msg.replaceFirst('Exception: ', '');
  }
}

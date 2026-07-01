import 'package:flutter/foundation.dart';

import '../data/models/casting_call.dart';
import '../data/repositories/casting_repository.dart';

/// State for the Casting Calls tab: browse / applied / my-calls lists.
class CastingProvider extends ChangeNotifier {
  CastingProvider({CastingRepository? repository})
      : _repo = repository ?? CastingRepository();

  final CastingRepository _repo;

  List<CastingCall> _all = const [];
  List<CastingCall> _applied = const [];
  List<CastingCall> _mine = const [];
  List<CastingCall> get all => _all;
  List<CastingCall> get applied => _applied;
  List<CastingCall> get mine => _mine;

  bool _loading = false;
  bool get loading => _loading;

  bool _busy = false;
  bool get busy => _busy;

  String? error;

  /// Loads all three lists (used on first open + pull-to-refresh).
  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      _all = await _repo.fetchAllCalls();
      _applied = await _repo.fetchAppliedCalls();
      _mine = await _repo.fetchMyCalls();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createCall(Map<String, dynamic> data) =>
      _wrap(() => _repo.createCall(data));

  Future<bool> deleteCall(String id) => _wrap(() => _repo.deleteCall(id));

  Future<bool> apply({
    required String callId,
    required String name,
    required String photo,
    String? phone,
    String? email,
    String? note,
    String? age,
    String? height,
    String? gender,
    String? experience,
  }) =>
      _wrap(() => _repo.apply(
            callId: callId,
            name: name,
            photo: photo,
            phone: phone,
            email: email,
            note: note,
            age: age,
            height: height,
            gender: gender,
            experience: experience,
          ));

  Future<bool> _wrap(Future<void> Function() action) async {
    _busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      await loadAll();
      _busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      _busy = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

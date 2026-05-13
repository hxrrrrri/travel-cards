import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const _keyUserId = 'userId';
  static const _keyEmail = 'email';
  static const _keyName = 'name';

  Box<dynamic> get _box => Hive.box(AppConstants.hiveBoxAuth);

  @override
  String? get currentUserId => _box.get(_keyUserId) as String?;

  @override
  String? get currentEmail => _box.get(_keyEmail) as String?;

  @override
  String? get currentDisplayName => _box.get(_keyName) as String?;

  @override
  bool get isLoggedIn => currentUserId != null;

  @override
  Future<bool> loginDemo() async {
    await _box.put(_keyUserId, 'demo-user-001');
    await _box.put(_keyEmail, 'demo@tripgraph.app');
    await _box.put(_keyName, 'Explorer');
    return true;
  }

  @override
  Future<bool> login(String email, String password) async {
    // Stub: accept any non-empty credentials in dev
    if (email.isEmpty || password.isEmpty) return false;
    await _box.put(_keyUserId, 'user-${email.hashCode}');
    await _box.put(_keyEmail, email);
    await _box.put(_keyName, email.split('@').first);
    return true;
  }

  @override
  Future<bool> signup(String email, String password, String name) async {
    if (email.isEmpty || password.isEmpty) return false;
    await _box.put(_keyUserId, 'user-${email.hashCode}');
    await _box.put(_keyEmail, email);
    await _box.put(_keyName, name);
    return true;
  }

  @override
  Future<void> logout() async {
    await _box.deleteAll([_keyUserId, _keyEmail, _keyName]);
  }
}

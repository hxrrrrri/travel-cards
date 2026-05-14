import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/env.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/auth_repository.dart';

/// Tries Supabase first, falls back to Hive if unavailable.
/// Allows smooth transition between auth backends.
class HybridAuthRepository implements AuthRepository {
  static const _keyUserId = 'userId';
  static const _keyEmail = 'email';
  static const _keyName = 'name';

  Box<dynamic> get _hiveBox => Hive.box(AppConstants.hiveBoxAuth);
  SupabaseClient? get _supabaseClient =>
      Env.hasSupabase ? Supabase.instance.client : null;

  @override
  bool get isLoggedIn {
    if (_supabaseClient != null && _supabaseClient!.auth.currentUser != null) {
      return true;
    }
    return _hiveBox.get(_keyUserId) != null;
  }

  @override
  String? get currentUserId {
    // Prefer Supabase if logged in
    if (_supabaseClient != null && _supabaseClient!.auth.currentUser != null) {
      return _supabaseClient!.auth.currentUser!.id;
    }
    return _hiveBox.get(_keyUserId) as String?;
  }

  @override
  String? get currentEmail {
    if (_supabaseClient != null && _supabaseClient!.auth.currentUser != null) {
      return _supabaseClient!.auth.currentUser!.email;
    }
    return _hiveBox.get(_keyEmail) as String?;
  }

  @override
  String? get currentDisplayName {
    if (_supabaseClient != null && _supabaseClient!.auth.currentUser != null) {
      final meta = _supabaseClient!.auth.currentUser!.userMetadata;
      if (meta != null && meta['name'] != null) {
        return meta['name'] as String;
      }
      return _supabaseClient!.auth.currentUser!.email?.split('@').first;
    }
    return _hiveBox.get(_keyName) as String?;
  }

  @override
  Future<bool> loginDemo() async {
    if (_supabaseClient != null) {
      try {
        final res = await _supabaseClient!.auth.signInWithPassword(
          email: 'demo@tripgraph.app',
          password: 'TripGraphDemo2024!',
        );
        if (res.user != null) {
          // Sync to Hive too
          await _hiveBox.put(_keyUserId, res.user!.id);
          await _hiveBox.put(_keyEmail, res.user!.email ?? '');
          await _hiveBox.put(_keyName, 'Demo User');
          return true;
        }
      } catch (_) {
        // Supabase failed, fall through to Hive
      }
    }
    // Fallback: local Hive
    await _hiveBox.put(_keyUserId, 'demo-user-001');
    await _hiveBox.put(_keyEmail, 'demo@tripgraph.app');
    await _hiveBox.put(_keyName, 'Explorer');
    return true;
  }

  @override
  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return false;

    if (_supabaseClient != null) {
      try {
        final res = await _supabaseClient!.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (res.user != null) {
          // Sync to Hive
          await _hiveBox.put(_keyUserId, res.user!.id);
          await _hiveBox.put(_keyEmail, res.user!.email ?? '');
          await _hiveBox.put(_keyName,
              res.user!.userMetadata?['name'] as String? ??
              email.split('@').first);
          return true;
        }
      } catch (_) {
        // Supabase failed, fall through to Hive
      }
    }

    // Fallback: local Hive
    await _hiveBox.put(_keyUserId, 'user-${email.hashCode}');
    await _hiveBox.put(_keyEmail, email);
    await _hiveBox.put(_keyName, email.split('@').first);
    return true;
  }

  @override
  Future<bool> signup(String email, String password, String name) async {
    if (email.isEmpty || password.isEmpty) return false;

    if (_supabaseClient != null) {
      try {
        final res = await _supabaseClient!.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
        );
        if (res.user != null) {
          // Sync to Hive
          await _hiveBox.put(_keyUserId, res.user!.id);
          await _hiveBox.put(_keyEmail, res.user!.email ?? '');
          await _hiveBox.put(_keyName, name);
          return true;
        }
      } catch (_) {
        // Supabase signup failed, fall through to Hive
      }
    }

    // Fallback: local Hive
    await _hiveBox.put(_keyUserId, 'user-${email.hashCode}');
    await _hiveBox.put(_keyEmail, email);
    await _hiveBox.put(_keyName, name);
    return true;
  }

  @override
  Future<void> logout() async {
    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.signOut();
      } catch (_) {}
    }
    await _hiveBox.deleteAll([_keyUserId, _keyEmail, _keyName]);
  }
}

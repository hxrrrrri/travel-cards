import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  bool get isLoggedIn => _client.auth.currentUser != null;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  String? get currentEmail => _client.auth.currentUser?.email;

  @override
  String? get currentDisplayName =>
      _client.auth.currentUser?.userMetadata?['name'] as String? ??
      currentEmail?.split('@').first;

  @override
  Future<bool> loginDemo() async {
    // Demo login uses a shared demo account
    try {
      final res = await _client.auth.signInWithPassword(
        email: 'demo@tripgraph.app',
        password: 'TripGraphDemo2024!',
      );
      return res.user != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.user != null;
    } on AuthException {
      return false;
    }
  }

  @override
  Future<bool> signup(String email, String password, String name) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      return res.user != null;
    } on AuthException {
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}

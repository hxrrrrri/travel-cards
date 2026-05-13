import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final String? email;
  final String? displayName;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.userId,
    this.email,
    this.displayName,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? email,
    String? displayName,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        userId: userId ?? this.userId,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthController extends StateNotifier<AuthState> with ChangeNotifier {
  final AuthRepository _repo;

  AuthController(this._repo)
      : super(AuthState(
          isLoggedIn: _repo.isLoggedIn,
          userId: _repo.currentUserId,
          email: _repo.currentEmail,
          displayName: _repo.currentDisplayName,
        ));

  Future<void> loginDemo() async {
    state = state.copyWith(isLoading: true, error: null);
    final ok = await _repo.loginDemo();
    state = state.copyWith(
      isLoading: false,
      isLoggedIn: ok,
      userId: _repo.currentUserId,
      email: _repo.currentEmail,
      displayName: _repo.currentDisplayName,
    );
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ok = await _repo.login(email, password);
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: ok,
        userId: _repo.currentUserId,
        email: _repo.currentEmail,
        displayName: _repo.currentDisplayName,
        error: ok ? null : 'Invalid credentials',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
    notifyListeners();
  }

  Future<void> signup(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ok = await _repo.signup(email, password, name);
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: ok,
        userId: _repo.currentUserId,
        email: _repo.currentEmail,
        displayName: _repo.currentDisplayName,
        error: ok ? null : 'Sign up failed',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
    notifyListeners();
  }
}

final _authRepoProvider = Provider<AuthRepository>((_) => AuthRepositoryImpl());

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
        (ref) => AuthController(ref.read(_authRepoProvider)));

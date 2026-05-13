abstract class AuthRepository {
  Future<bool> loginDemo();
  Future<bool> login(String email, String password);
  Future<bool> signup(String email, String password, String name);
  Future<void> logout();
  String? get currentUserId;
  String? get currentEmail;
  String? get currentDisplayName;
  bool get isLoggedIn;
}

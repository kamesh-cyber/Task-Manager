import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class AuthService {
  // Sign up new user
  static Future<ParseResponse> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final user = ParseUser(username, password, email);
    return await user.signUp();
  }

  // Login user
  static Future<ParseResponse> login({
    required String email,
    required String password,
  }) async {
    final user = ParseUser(email, password, email);
    return await user.login();
  }

  // Logout user
  static Future<ParseResponse?> logout() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      return await user.logout();
    }
    return null;
  }

  // Get current user
  static Future<ParseUser?> getCurrentUser() async {
    return await ParseUser.currentUser() as ParseUser?;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}

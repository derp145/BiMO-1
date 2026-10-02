import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterResult {
  final bool isSuccess;
  final bool requiresEmailConfirmation;
  final String? errorMessage;

  const RegisterResult({
    required this.isSuccess,
    this.requiresEmailConfirmation = false,
    this.errorMessage,
  });
}

class MockAuthService {
  const MockAuthService();

  // Keep the existing demo login.
  static const testEmail = 'bimo@gmail.com';
  static const testPassword = 'admin123';

  static bool _isLoggedIn = false;
  static String? _currentUserEmail;

  bool get isLoggedIn =>
      Supabase.instance.client.auth.currentUser != null || _isLoggedIn;
  String? get currentUserEmail =>
      Supabase.instance.client.auth.currentUser?.email ?? _currentUserEmail;

  Future<bool> login({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();

    // The demo credential must also establish a real Supabase session so
    // saved projects can be associated with auth.users.id.
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      return false;
    }

    _isLoggedIn = true;
    _currentUserEmail = user.email;

    return true;
  }

  Future<RegisterResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      // Real Supabase registration.
      final response = await Supabase.instance.client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'full_name': fullName.trim()},
      );

      final user = response.user;
      if (user == null) {
        return const RegisterResult(
          isSuccess: false,
          errorMessage: 'Unable to create an account.',
        );
      }

      // If email confirmation is enabled on Supabase, session is null upon signup.
      final bool requiresEmailConfirmation = response.session == null;

      return RegisterResult(
        isSuccess: true,
        requiresEmailConfirmation: requiresEmailConfirmation,
      );
    } on AuthException catch (e) {
      return RegisterResult(isSuccess: false, errorMessage: e.message);
    } catch (_) {
      return const RegisterResult(
        isSuccess: false,
        errorMessage: 'Unable to create an account.',
      );
    }
  }

  Future<bool> sendPasswordReset({required String email}) async {
    final cleanEmail = email.trim().toLowerCase();

    await Supabase.instance.client.auth.resetPasswordForEmail(cleanEmail);

    return true;
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();

    _isLoggedIn = false;
    _currentUserEmail = null;
  }
}

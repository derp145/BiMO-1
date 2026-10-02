import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../services/mock_auth_service.dart';
import '../../shared/widgets/bimo_notification.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = const MockAuthService();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await _authService.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);

      if (result.isSuccess) {
        AuthNotificationState.showAccountCreated(
          'Account created successfully. A confirmation email has been sent to your email. Please confirm your email before logging in.',
        );
        context.go('/login');
      } else {
        showBiMONotification(
          context,
          message: result.errorMessage ?? 'Unable to create an account.',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      showBiMONotification(
        context,
        message: 'Unable to create an account.',
        isError: true,
      );
    }
  }

  String? _validateRequired(String? value, String label) {
    if (value?.trim().isEmpty ?? true) {
      return '$label is required.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 600 ? 20.0 : 32.0;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 64)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Container(
                          padding: EdgeInsets.all(screenWidth < 600 ? 24 : 32),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: AppColors.emeraldLight,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Create your account',
                                  style: AppTypography.headingLarge(isDark),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Start organizing your builds with BiMO.',
                                  style: AppTypography.bodyMedium(isDark),
                                ),
                                const SizedBox(height: 28),
                                TextFormField(
                                  controller: _fullNameController,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: (value) =>
                                      _validateRequired(value, 'Full name'),
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    hintText: 'Enter your full name',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: _validateEmail,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'Enter your email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _isPasswordObscured,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: _validatePassword,
                                  decoration: _passwordDecoration(
                                    label: 'Password',
                                    hint: 'Create a password',
                                    isObscured: _isPasswordObscured,
                                    onToggle: () {
                                      setState(() {
                                        _isPasswordObscured =
                                            !_isPasswordObscured;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _isConfirmPasswordObscured,
                                  textInputAction: TextInputAction.done,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: _validateConfirmPassword,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: _passwordDecoration(
                                    label: 'Confirm Password',
                                    hint: 'Re-enter your password',
                                    isObscured: _isConfirmPasswordObscured,
                                    onToggle: () {
                                      setState(() {
                                        _isConfirmPasswordObscured =
                                            !_isConfirmPasswordObscured;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Create Account'),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: AppTypography.bodyMedium(isDark),
                                    ),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => context.go('/login'),
                                      child: const Text('Log In'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const PersistentAuthNotification(),
          ],
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String label,
    required String hint,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        tooltip: isObscured ? 'Show password' : 'Hide password',
        onPressed: onToggle,
        icon: Icon(
          isObscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    );
  }
}

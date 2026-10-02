import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../services/mock_auth_service.dart';
import '../../shared/widgets/bimo_notification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: MockAuthService.testEmail,
  );
  final _passwordController = TextEditingController(
    text: MockAuthService.testPassword,
  );
  final _authService = const MockAuthService();

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final isSuccessful = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);

      if (isSuccessful) {
        AuthNotificationState.clear();
        showBiMONotification(context, message: 'Logged in successfully.');
        context.go('/');
      } else {
        showBiMONotification(
          context,
          message: 'Unable to log in. Please check your email and password.',
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
        message: 'Unable to log in. Please check your email and password.',
        isError: true,
      );
    }
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
                return ValueListenableBuilder<String?>(
                  valueListenable: AuthNotificationState.accountCreatedMessage,
                  builder: (context, msg, _) {
                    final hasNotification = msg != null && msg.isNotEmpty;
                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        top: 32,
                        bottom: (hasNotification && screenWidth <= 900)
                            ? 100
                            : 32,
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
                              padding: EdgeInsets.all(
                                screenWidth < 600 ? 24 : 32,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.emeraldSoft,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.account_tree_rounded,
                                        color: AppColors.emeraldLight,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Welcome back',
                                      style: AppTypography.headingLarge(isDark),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Sign in to continue organizing your builds.',
                                      style: AppTypography.bodyMedium(isDark),
                                    ),
                                    const SizedBox(height: 28),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
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
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: _validatePassword,
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        hintText: 'Enter your password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _isPasswordObscured
                                              ? 'Show password'
                                              : 'Hide password',
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordObscured =
                                                  !_isPasswordObscured;
                                            });
                                          },
                                          icon: Icon(
                                            _isPasswordObscured
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => context.push(
                                                '/forgot-password',
                                              ),
                                        child: const Text('Forgot Password?'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 52,
                                      child: FilledButton(
                                        onPressed: _isLoading ? null : _submit,
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text('Log In'),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account?",
                                          style: AppTypography.bodyMedium(
                                            isDark,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () => context.push('/signup'),
                                          child: const Text('Sign Up'),
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
                );
              },
            ),
            const PersistentAuthNotification(),
          ],
        ),
      ),
    );
  }
}

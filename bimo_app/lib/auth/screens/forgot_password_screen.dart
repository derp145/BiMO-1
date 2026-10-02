import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../services/mock_auth_service.dart';
import '../../shared/widgets/bimo_notification.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = const MockAuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final isSuccessful = await _authService.sendPasswordReset(
        email: _emailController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);

      if (isSuccessful) {
        showBiMONotification(
          context,
          message: 'Password reset link sent successfully.',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      showBiMONotification(
        context,
        message: 'Unable to send a reset link.',
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
                                        Icons.lock_reset_rounded,
                                        color: AppColors.emeraldLight,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Forgot Password?',
                                      style: AppTypography.headingLarge(isDark),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Enter your email and we will send a password reset link.',
                                      style: AppTypography.bodyMedium(isDark),
                                    ),
                                    const SizedBox(height: 28),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: _validateEmail,
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'Enter your email',
                                        prefixIcon: Icon(Icons.email_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
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
                                            : const Text('Send Reset Link'),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : () => context.go('/login'),
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                      ),
                                      label: const Text('Back to Log In'),
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

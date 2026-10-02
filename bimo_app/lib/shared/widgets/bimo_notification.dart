import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AuthNotificationState {
  AuthNotificationState._();

  static final ValueNotifier<String?> accountCreatedMessage =
      ValueNotifier<String?>(null);

  static bool get hasNotification =>
      accountCreatedMessage.value != null &&
      accountCreatedMessage.value!.isNotEmpty;

  static void showAccountCreated([
    String message =
        'Account created successfully. A confirmation email has been sent to your email. Please confirm your email before logging in.',
  ]) {
    accountCreatedMessage.value = message;
  }

  static void clear() {
    accountCreatedMessage.value = null;
  }
}

class BiMONotificationCard extends StatelessWidget {
  final String message;
  final bool isError;

  const BiMONotificationCard({
    super.key,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2028),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E3240)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? AppColors.redAlert : AppColors.emeraldLight,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PersistentAuthNotification extends StatelessWidget {
  const PersistentAuthNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AuthNotificationState.accountCreatedMessage,
      builder: (context, message, child) {
        if (message == null || message.isEmpty) {
          return const SizedBox.shrink();
        }

        final mediaQuery = MediaQuery.of(context);
        final width = mediaQuery.size.width;
        final isDesktop = width > 900;
        final isMobile = width < 600;

        if (isDesktop) {
          return Positioned(
            right: 24,
            bottom: 24,
            width: 320,
            child: Material(
              color: Colors.transparent,
              child: BiMONotificationCard(message: message),
            ),
          );
        }

        return Positioned(
          left: isMobile ? 16 : 32,
          right: isMobile ? 16 : 32,
          bottom: isMobile ? 20 : 24,
          child: Material(
            color: Colors.transparent,
            child: BiMONotificationCard(message: message),
          ),
        );
      },
    );
  }
}

void showBiMONotification(
  BuildContext context, {
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  final mediaQuery = MediaQuery.of(context);
  final width = mediaQuery.size.width;
  final isDesktop = width > 900;
  final isMobile = width < 600;
  final hasPersistent = AuthNotificationState.hasNotification;

  final snackBarMargin = isDesktop
      ? EdgeInsets.only(
          left: width - 340,
          right: 24,
          bottom: hasPersistent ? 96 : 24,
        )
      : EdgeInsets.fromLTRB(
          isMobile ? 16 : 32,
          0,
          isMobile ? 16 : 32,
          hasPersistent ? (isMobile ? 96 : 100) : (isMobile ? 20 : 24),
        );

  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? AppColors.redAlert : AppColors.emeraldLight,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      margin: snackBarMargin,
      duration: duration,
      backgroundColor: const Color(0xFF1E2028),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF2E3240)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),
  );
}

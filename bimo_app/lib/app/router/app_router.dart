import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/screens/forgot_password_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/signup_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/wizard/presentation/project_wizard_screen.dart';
import '../../features/maker/presentation/maker_portal_screen.dart';
import '../../features/planner/presentation/project_planner_screen.dart';
import '../../features/saved/presentation/saved_projects_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/help/presentation/help_about_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _instantPage(const LoginScreen()),
    ),

    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => _instantPage(const SignupScreen()),
    ),

    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) =>
          _instantPage(const ForgotPasswordScreen()),
    ),

    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _instantPage(const DashboardScreen()),
    ),

    GoRoute(
      path: '/wizard',
      pageBuilder: (context, state) =>
          _instantPage(const ProjectWizardScreen()),
    ),

    GoRoute(
      path: '/maker',
      pageBuilder: (context, state) {
        final extraMap = state.extra is Map<String, dynamic>
            ? state.extra as Map<String, dynamic>
            : null;

        return _instantPage(MakerPortalScreen(wizardData: extraMap));
      },
    ),

    GoRoute(
      path: '/planner',
      pageBuilder: (context, state) =>
          _instantPage(const ProjectPlannerScreen()),
    ),

    GoRoute(
      path: '/saved',
      pageBuilder: (context, state) =>
          _instantPage(const SavedProjectsScreen()),
    ),

    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _instantPage(const SettingsScreen()),
    ),

    GoRoute(
      path: '/help',
      pageBuilder: (context, state) => _instantPage(const HelpAboutScreen()),
    ),
  ],

  errorBuilder: (context, state) {
    return Scaffold(body: Center(child: Text('Route not found: ${state.uri}')));
  },
);

NoTransitionPage<void> _instantPage(Widget child) {
  return NoTransitionPage<void>(child: child);
}

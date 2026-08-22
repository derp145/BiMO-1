import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/wizard/presentation/project_wizard_screen.dart';
import '../../features/maker/presentation/maker_portal_screen.dart';
import '../../features/planner/presentation/project_planner_screen.dart';
import '../../features/saved/presentation/saved_projects_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/help/presentation/help_about_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(
      path: '/wizard',
      builder: (context, state) => const ProjectWizardScreen(),
    ),
    GoRoute(
      path: '/maker',
      builder: (context, state) {
        final extraMap = state.extra is Map<String, dynamic>
            ? state.extra as Map<String, dynamic>
            : null;
        return MakerPortalScreen(wizardData: extraMap);
      },
    ),
    GoRoute(
      path: '/planner',
      builder: (context, state) => const ProjectPlannerScreen(),
    ),
    GoRoute(
      path: '/saved',
      builder: (context, state) => const SavedProjectsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpAboutScreen(),
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
);

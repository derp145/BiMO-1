import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/services/mock_auth_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../projects/data/project_provider.dart';
import '../../../shared/widgets/bimo_notification.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;
  final _authService = const MockAuthService();
  Timer? _nameSaveDebounce;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.displayName);
  }

  @override
  void dispose() {
    _nameSaveDebounce?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _onDisplayNameChanged(String value) {
    ref.read(profileProvider.notifier).setDisplayName(value);
    _nameSaveDebounce?.cancel();
    _nameSaveDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        await ref.read(profileProvider.notifier).saveDisplayName(value);
      } catch (_) {
        if (!mounted) return;
        showBiMONotification(
          context,
          message: 'Could not save display name.',
          isError: true,
        );
      }
    });
  }

  Future<void> _confirmLogout() async {
    final shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogOut != true || !mounted) {
      return;
    }

    await _authService.logout();

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final profile = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentUserEmail = _authService.currentUserEmail;
    return AppScaffold(
      title: 'Workspace Settings',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SETTINGS', style: AppTypography.labelUppercase()),
                const SizedBox(height: 4),
                Text(
                  'Workspace preferences',
                  style: AppTypography.displayMedium(isDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your profile, choose application appearance, and learn about BiMO.',
                  style: AppTypography.bodyMedium(isDark),
                ),
                const SizedBox(height: 32),

                // Section 1: Profile
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Settings Header
                        if (isMobile)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile Settings',
                                style: AppTypography.headingLarge(isDark),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'CHANGES SAVE INSTANTLY',
                                  style: AppTypography.labelUppercase(),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profile Settings',
                                style: AppTypography.headingLarge(isDark),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'CHANGES SAVE INSTANTLY',
                                  style: AppTypography.labelUppercase(),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 20),

                        // MOBILE PROFILE LAYOUT
                        if (isMobile)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Display Name
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DISPLAY NAME',
                                    style: AppTypography.labelUppercase(),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your display name',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                    onChanged: _onDisplayNameChanged,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This name is shown across BiMO project workspaces and exported summaries.',
                                    style: AppTypography.bodySmall(isDark),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Mobile Profile Preview
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkPanel
                                      : AppColors.lightPanel,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.emeraldSoft,
                                      child: Text(
                                        profile.avatarInitial,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: AppColors.emeraldLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.displayName,
                                            style: AppTypography.headingMedium(
                                              isDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Build Intelligence & Materials Organizer',
                                            style: AppTypography.bodySmall(
                                              isDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        // DESKTOP PROFILE LAYOUT
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DISPLAY NAME',
                                      style: AppTypography.labelUppercase(),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter your display name',
                                        prefixIcon: Icon(
                                          Icons.person_outline_rounded,
                                        ),
                                      ),
                                      onChanged: _onDisplayNameChanged,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This name is shown across BiMO project workspaces and exported summaries.',
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 24),

                              // Desktop Profile Preview
                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkPanel
                                        : AppColors.lightPanel,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: AppColors.emeraldSoft,
                                        child: Text(
                                          profile.avatarInitial,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            color: AppColors.emeraldLight,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile.displayName,
                                              style:
                                                  AppTypography.headingMedium(
                                                    isDark,
                                                  ),
                                            ),
                                            Text(
                                              'Build Intelligence & Materials Organizer',
                                              style: AppTypography.bodySmall(
                                                isDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section 2: Appearance
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance & Theme',
                          style: AppTypography.headingLarge(isDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose how BiMO appears across your workspace screens.',
                          style: AppTypography.bodyMedium(isDark),
                        ),
                        const SizedBox(height: 20),

                        if (isMobile)
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: _ThemeChoiceCard(
                                  label: 'Dark Mode',
                                  subtitle: 'Near-black high contrast',
                                  icon: Icons.dark_mode_outlined,
                                  selected: themeMode == ThemeMode.dark,
                                  onTap: () {
                                    ref.read(themeModeProvider.notifier).state =
                                        ThemeMode.dark;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: _ThemeChoiceCard(
                                  label: 'Light Mode',
                                  subtitle: 'Clean light background',
                                  icon: Icons.light_mode_outlined,
                                  selected: themeMode == ThemeMode.light,
                                  onTap: () {
                                    ref.read(themeModeProvider.notifier).state =
                                        ThemeMode.light;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: _ThemeChoiceCard(
                                  label: 'System Mode',
                                  subtitle: 'Follow OS preference',
                                  icon: Icons.settings_brightness_outlined,
                                  selected: themeMode == ThemeMode.system,
                                  onTap: () {
                                    ref.read(themeModeProvider.notifier).state =
                                        ThemeMode.system;
                                  },
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _ThemeChoiceCard(
                                  label: 'Dark Mode',
                                  subtitle: 'Near-black high contrast',
                                  icon: Icons.dark_mode_outlined,
                                  selected: themeMode == ThemeMode.dark,
                                  onTap: () {
                                    ref.read(themeModeProvider.notifier).state =
                                        ThemeMode.dark;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ThemeChoiceCard(
                                  label: 'Light Mode',
                                  subtitle: 'Clean light background',
                                  icon: Icons.light_mode_outlined,
                                  selected: themeMode == ThemeMode.light,
                                  onTap: () {
                                    ref.read(themeModeProvider.notifier).state =
                                        ThemeMode.light;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ThemeChoiceCard(
                                  label: 'System Mode',
                                  subtitle: 'Follow OS preference',
                                  icon: Icons.settings_brightness_outlined,
                                  selected: themeMode == ThemeMode.system,
                                  onTap: () {
                                    ref.read(themeModeProvider.notifier).state =
                                        ThemeMode.system;
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section 3: Account & Security
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account & Security',
                          style: AppTypography.headingLarge(isDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage the account currently signed in to BiMO.',
                          style: AppTypography.bodyMedium(isDark),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkPanel
                                : AppColors.lightPanel,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EMAIL',
                                style: AppTypography.labelUppercase(),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentUserEmail ?? 'Not signed in',
                                style: AppTypography.bodyLarge(isDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _authService.isLoggedIn
                                ? _confirmLogout
                                : null,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Log Out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section 4: About BiMO
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About BiMO',
                          style: AppTypography.headingLarge(isDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'BiMO (Build Intelligence and Materials Organizer) helps makers, hardware engineers, and IoT developers turn concepts into structured project workspaces, BOMs, component compatibility checks, and localized procurement.',
                          style: AppTypography.bodyMedium(isDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoiceCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.emeraldSoft
              : (isDark ? AppColors.darkPanel : AppColors.lightPanel),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.emeraldLight
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.emeraldLight
                  : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTypography.headingMedium(isDark).copyWith(
                fontSize: 15,
                color: selected ? AppColors.emeraldLight : null,
              ),
            ),
            Text(subtitle, style: AppTypography.bodySmall(isDark)),
          ],
        ),
      ),
    );
  }
}

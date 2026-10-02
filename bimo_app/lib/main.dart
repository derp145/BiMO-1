import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'features/projects/data/project_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ubepjcguepljrnnsgnfe.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InViZXBqY2d1ZXBsanJubnNnbmZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxMTc0MjQsImV4cCI6MjEwNDY5MzQyNH0.198ZiebIZksb23CL2eY_lWRXmtAl98mCjevB2E2-OiQ',
  );

  runApp(const ProviderScope(child: BiMoApp()));
}

class BiMoApp extends ConsumerWidget {
  const BiMoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'BiMO — Build Intelligence and Materials Organizer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}

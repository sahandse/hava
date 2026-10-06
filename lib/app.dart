import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/core/theme/app_theme.dart';
import 'package:hava/features/settings/application/settings_controller.dart';
import 'package:hava/features/location/presentation/startup_gate.dart';

class HavaApp extends ConsumerWidget {
  const HavaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'هوا',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const StartupGate(),
    );
  }
}

import 'dart:developer' as developer;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:amparo_coletivo/config/settings_controller.dart';
import 'package:amparo_coletivo/config/theme.dart';
import 'package:amparo_coletivo/routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://luooeidsfkypyctvytok.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx1b29laWRzZmt5cHljdHZ5dG9rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyMDMzNjcsImV4cCI6MjA2NTc3OTM2N30.kM_S-oLmRTTuBkbpKW2MUn3Ngl7ic0ZaGb-sltYzB0E',
  );
  final settingsController = SettingsController();
  await settingsController.init();
  runApp(
    DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return ChangeNotifierProvider.value(
          value: settingsController,
          child: App(
            lightDynamicScheme: lightDynamic,
            darkDynamicScheme: darkDynamic,
          ),
        );
      },
    ),
  );
}

class App extends StatelessWidget {
  const App({
    super.key,
    this.lightDynamicScheme,
    this.darkDynamicScheme,
  });

  final ColorScheme? lightDynamicScheme;
  final ColorScheme? darkDynamicScheme;

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      developer.log('No user logged in', name: 'App');
    } else {
      developer.log('Auth UID: ${user.id}', name: 'App');
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Amparo Coletivo',
      theme: AppTheme.light(dynamicScheme: lightDynamicScheme),
      darkTheme: AppTheme.dark(dynamicScheme: darkDynamicScheme),
      themeMode: settingsController.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}

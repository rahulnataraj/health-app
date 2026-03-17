import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app_mobile/core/theme/app_theme.dart';
import 'package:health_app_mobile/core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HealthApp()));
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Health App',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

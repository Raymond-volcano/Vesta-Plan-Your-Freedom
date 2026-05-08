import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class FinancialFreedomApp extends StatelessWidget {
  const FinancialFreedomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '财务自由希望',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}

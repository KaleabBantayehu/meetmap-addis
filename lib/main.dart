import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const MeetMapApp());
}

class MeetMapApp extends StatelessWidget {
  const MeetMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MeetMap Addis',

      // Simple theme for now
      theme: AppTheme.lightTheme,
      // Start screen
      initialRoute: '/login',

      // Centralized routes
      routes: AppRoutes.routes,
    );
  }
}

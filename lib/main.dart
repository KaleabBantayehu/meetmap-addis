import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'core/repositories/mock/mock_place_repository.dart';
import 'core/repositories/mock/mock_auth_repository.dart';
import 'providers/places_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/saved_provider.dart';

void main() {
  final placeRepository = MockPlaceRepository();
  final authRepository = MockAuthRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlacesProvider(placeRepository: placeRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SavedProvider(placeRepository: placeRepository),
        ),
      ],
      child: const MeetMapApp(),
    ),
  );
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
      initialRoute: AppRoutes.login,

      // Centralized routes
      routes: AppRoutes.routes,
    );
  }
}

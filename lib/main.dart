import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'core/repositories/mock/mock_place_repository.dart';
import 'core/repositories/firebase/firebase_auth_repository.dart';
import 'core/repositories/mock/mock_event_repository.dart';
import 'core/repositories/mock/mock_network_repository.dart';
import 'core/repositories/mock/mock_hangout_repository.dart';
import 'providers/places_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/saved_provider.dart';
import 'providers/events_provider.dart';
import 'providers/network_provider.dart';
import 'providers/hangouts_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Activate Firebase App Check.
    // In debug/dev builds: uses a debug token (printed to console on first run).
    //   → Register that token once in: Firebase Console > App Check > your app > Manage debug tokens.
    // In release builds: uses Play Integrity (no reCAPTCHA fallback).
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider()
          : AndroidPlayIntegrityProvider(),
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  final placeRepository = MockPlaceRepository();
  final authRepository = FirebaseAuthRepository();
  final eventRepository = MockEventRepository();
  final networkRepository = MockNetworkRepository();
  final hangoutRepository = MockHangoutRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlacesProvider(placeRepository: placeRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(authRepository: authRepository)..checkCurrentUser(),
        ),
        ChangeNotifierProvider(
          create: (_) => SavedProvider(placeRepository: placeRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => EventsProvider(eventRepository: eventRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => NetworkProvider(networkRepository: networkRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => HangoutsProvider(hangoutRepository: hangoutRepository),
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

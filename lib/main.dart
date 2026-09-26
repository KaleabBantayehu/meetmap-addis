import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'core/repositories/firebase/firebase_place_repository.dart';
import 'core/repositories/firebase/firebase_auth_repository.dart';
import 'core/repositories/firebase/firebase_saved_repository.dart';
import 'core/repositories/firebase/firebase_review_repository.dart';
import 'core/repositories/firebase/firebase_event_repository.dart';
import 'core/repositories/firebase/firebase_network_repository.dart';
import 'core/repositories/firebase/firebase_hangout_repository.dart';
import 'core/repositories/firebase/firebase_user_repository.dart';
import 'providers/places_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/saved_provider.dart';
import 'providers/reviews_provider.dart';
import 'providers/events_provider.dart';
import 'providers/network_provider.dart';
import 'providers/hangouts_provider.dart';
import 'providers/user_provider.dart';
import 'firebase_options.dart';

import 'core/storage/local_storage_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/storage/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. LocalStorageService.init()
  // 2. SecureStorageService.init()
  // 3. ConnectivityService.init()
  try {
    await LocalStorageService.init();
    await SecureStorageService.init();
    await ConnectivityService.init();
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Local services initialization failed: $e');
  }

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

  final placeRepository = FirebasePlaceRepository();
  final authRepository = FirebaseAuthRepository();
  final eventRepository = FirebaseEventRepository();
  final networkRepository = FirebaseNetworkRepository();
  final hangoutRepository = FirebaseHangoutRepository();
  final savedRepository = FirebaseSavedRepository();
  final reviewRepository = FirebaseReviewRepository();
  final userRepository = FirebaseUserRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlacesProvider(placeRepository: placeRepository),
        ),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(authRepository: authRepository)..checkCurrentUser(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SavedProvider>(
          create: (context) => SavedProvider(
            savedRepository: savedRepository,
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, authProvider, previous) {
            final provider =
                previous ??
                SavedProvider(
                  savedRepository: savedRepository,
                  authProvider: authProvider,
                );
            provider.syncSession(authProvider.currentUser?.id);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReviewsProvider>(
          create: (context) => ReviewsProvider(
            reviewRepository: reviewRepository,
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, authProvider, previous) =>
              previous ??
              ReviewsProvider(
                reviewRepository: reviewRepository,
                authProvider: authProvider,
              ),
        ),
        ChangeNotifierProvider(
          create: (_) => EventsProvider(eventRepository: eventRepository),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NetworkProvider>(
          create: (_) => NetworkProvider(networkRepository: networkRepository),
          update: (_, authProvider, previous) {
            final provider =
                previous ??
                NetworkProvider(networkRepository: networkRepository);
            provider.syncSession(authProvider.currentUser?.id);
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => HangoutsProvider(hangoutRepository: hangoutRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(userRepository: userRepository),
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

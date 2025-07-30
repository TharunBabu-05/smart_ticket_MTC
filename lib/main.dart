import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/ticket_booking_screen.dart';
import 'screens/conductor_verification_screen.dart';
import 'screens/map_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/support_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/demo_test_screen.dart';
import 'screens/debug_screen.dart';
import 'services/background_service.dart';
import 'services/bus_stop_service.dart';
import 'services/enhanced_auth_service.dart';
import 'services/enhanced_ticket_service.dart';
import 'services/fraud_detection_service_new.dart';
import 'services/theme_service.dart';
import 'services/offline_storage_service.dart';
import 'services/performance_service.dart';
import 'firebase_options.dart';

void main() async {
  // Start app initialization timer
  final Stopwatch appStartTimer = Stopwatch()..start();
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize performance monitoring first
  final PerformanceService performanceService = PerformanceService();
  await performanceService.initialize();
  
  try {
    // Initialize Firebase with error handling
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    performanceService.recordError('firebase_init_error', errorMessage: e.toString());
    // Continue without Firebase for now
  }
  
  try {
    // Initialize offline storage
    await OfflineStorageService.initialize();
    print('Offline storage initialized successfully');
  } catch (e) {
    print('Offline storage initialization error: $e');
    performanceService.recordError('offline_storage_init_error', errorMessage: e.toString());
  }
  
  try {
    // Initialize background service with error handling
    await BackgroundTripService.initializeService();
    print('Background service initialized successfully');
  } catch (e) {
    print('Background service initialization error: $e');
    performanceService.recordError('background_service_init_error', errorMessage: e.toString());
    // Continue without background service
  }
  
  try {
    // Initialize bus stop service with error handling
    await BusStopService.initialize();
    print('Bus stop service initialized successfully');
  } catch (e) {
    print('Bus stop service initialization error: $e');
    performanceService.recordError('bus_stop_service_init_error', errorMessage: e.toString());
    // Continue without bus stop service
  }
  
  try {
    // Initialize enhanced ticket service
    await EnhancedTicketService.initialize();
    print('Enhanced ticket service initialized successfully');
  } catch (e) {
    print('Enhanced ticket service initialization error: $e');
    performanceService.recordError('enhanced_ticket_service_init_error', errorMessage: e.toString());
    // Continue without enhanced ticket service
  }

  try {
    // Initialize fraud detection service
    await FraudDetectionService.initialize();
    print('Fraud detection service initialized successfully');
  } catch (e) {
    print('Fraud detection service initialization error: $e');
    performanceService.recordError('fraud_detection_service_init_error', errorMessage: e.toString());
    // Continue without fraud detection service
  }
  
  // Initialize theme service
  final ThemeService themeService = await ThemeService.initialize();
  
  // Record app start time
  appStartTimer.stop();
  performanceService.recordAppStartTime(
    Duration(milliseconds: appStartTimer.elapsedMilliseconds),
  );
  
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    performanceService.recordError(
      'flutter_error',
      errorMessage: details.exception.toString(),
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  
  runApp(SmartTicketingApp(themeService: themeService));
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          // User is logged in
          return const HomeScreen();
        } else {
          // User is not logged in
          return const AuthScreen();
        }
      },
    );
  }
}

class SmartTicketingApp extends StatelessWidget {
  final ThemeService themeService;
  
  const SmartTicketingApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeService>.value(
      value: themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Smart Ticketing MTC',
            theme: themeService.getThemeData(Brightness.light),
            darkTheme: themeService.getThemeData(Brightness.dark),
            themeMode: _getThemeMode(themeService.themeMode),
            home: const AuthWrapper(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/auth': (context) => const AuthScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/support': (context) => const SupportScreen(),
              '/booking': (context) => TicketBookingScreen(),
              '/conductor': (context) => ConductorVerificationScreen(),
              '/map': (context) => const MapScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/demo': (context) => DemoTestScreen(),
              '/debug': (context) => const DebugScreen(),
            },
            builder: (context, child) {
              // Global error boundary and performance monitoring
              return _ErrorBoundary(child: child ?? const SizedBox());
            },
          );
        },
      ),
    );
  }
  
  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Global error boundary widget
class _ErrorBoundary extends StatelessWidget {
  final Widget child;
  
  const _ErrorBoundary({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

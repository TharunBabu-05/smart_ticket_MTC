import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/ticket_booking_screen.dart';
import 'screens/conductor_verification_screen.dart';
import 'screens/map_screen.dart';
import 'services/background_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with error handling
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue without Firebase for now
  }
  
  try {
    // Initialize background service with error handling
    await BackgroundTripService.initializeService();
    print('Background service initialized successfully');
  } catch (e) {
    print('Background service initialization error: $e');
    // Continue without background service
  }
  
  runApp(const SmartTicketingApp());
}

class SmartTicketingApp extends StatelessWidget {
  const SmartTicketingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ticketing MTC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      routes: {
        '/': (context) => const HomeScreen(),
        '/booking': (context) => TicketBookingScreen(),
        '/conductor': (context) => ConductorVerificationScreen(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}

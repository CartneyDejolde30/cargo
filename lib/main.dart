import 'package:flutter/material.dart';
import 'onboarding.dart';
import 'login.dart';
import 'package:flutter_application_1/USERS-UI/Renter/renters.dart'; 
import 'package:flutter_application_1/USERS-UI/Renter/car_list_screen.dart'; 
import 'package:flutter_application_1/USERS-UI/Renter/chats/chat_list_screen.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_application_1/USERS-UI/Renter/bookings/booking_screen.dart'; // Booking form
import 'package:flutter_application_1/USERS-UI/Renter/bookings/history/my_booking_screen.dart'; // ✅ Add this new import


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CarGO',
      home: const OnboardingScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/renters': (context) => const HomeScreen(),
        '/car_list': (context) => const CarListScreen(),
        '/chat_list': (context) => const ChatListScreen(),
        '/my_bookings': (context) => const MyBookingsScreen(), // ✅ Changed this to MyBookingsScreen
        // You might also want to add a route for the booking form if needed:
        // '/booking': (context) => const BookingScreen(...), // This needs parameters though
      },
    );
  }
}
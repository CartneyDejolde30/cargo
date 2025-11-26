import 'package:flutter/material.dart';
import 'onboarding.dart';
import 'login.dart';
import 'package:flutter_application_1/USERS-UI/Renter/renters.dart'; // Your renters screen file
import 'package:flutter_application_1/USERS-UI/Renter/car_list_screen.dart'; // Your car list screen file
import 'package:flutter_application_1/USERS-UI/Renter/chats/chat_list_screen.dart'; // Your chat list screen file

void main() {
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
        '/renters': (context) => const HomeScreen(), // Add your renters screen
        '/car_list': (context) => const CarListScreen(), // Add your car list screen
        '/chat_list': (context) => const ChatListScreen(), // Add your chat list screen
      },
    );
  }
}
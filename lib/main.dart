import 'package:flutter/material.dart';
import 'onboarding.dart';
import 'login.dart';
import 'package:flutter_application_1/USERS-UI/Renter/renters.dart';
import 'package:flutter_application_1/USERS-UI/Renter/car_list_screen.dart';
import 'package:flutter_application_1/USERS-UI/Renter/chats/chat_list_screen.dart';
import 'package:flutter_application_1/USERS-UI/Renter/profile_screen.dart';
import 'package:flutter_application_1/USERS-UI/Owner/mycar_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/USERS-UI/Renter/bookings/history/my_booking_screen.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Permissions for Android/iOS
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // Local Notification setup
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'carGo_channel',
    'CarGO Notifications',
    description: 'Channel for real-time notifications',
    importance: Importance.high,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await _localNotifications.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
  );

  // Create channel
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Foreground listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _localNotifications.show(
        message.notification.hashCode,
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'carGo_channel',
            'CarGO Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  // 🔥 WRAP APP WITH THEME PROVIDER
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CarGO',

      // 🌙 LIGHT & DARK THEMES
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,

      home: const OnboardingScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/renters': (context) => const HomeScreen(),
        '/car_list': (context) => const CarListScreen(),
        '/chat_list': (context) => const ChatListScreen(),
        "/profile": (context) => const ProfileScreen(),

        '/mycars': (context) {
          final ownerId =
              ModalRoute.of(context)!.settings.arguments as int;
          return MyCarPage(ownerId: ownerId);
        },

        '/my_bookings': (context) => const MyBookingsScreen(),
      },
    );
  }
}

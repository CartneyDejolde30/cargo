import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

// 🔥 Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// 🔔 Notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🎨 Theme
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';

// 🧭 Screens
import 'onboarding.dart';
import 'login.dart';
import 'package:flutter_application_1/USERS-UI/Renter/renters.dart';
import 'package:flutter_application_1/USERS-UI/Renter/car_list_screen.dart';
import 'package:flutter_application_1/USERS-UI/Renter/chats/chat_list_screen.dart';
import 'package:flutter_application_1/USERS-UI/Renter/profile_screen.dart';
import 'package:flutter_application_1/USERS-UI/Owner/mycar_page.dart';
import 'package:flutter_application_1/USERS-UI/Renter/bookings/history/my_booking_screen.dart';

/// 🔔 Local Notifications Instance
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// 📩 Firebase Background Handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

/// 🚀 APP ENTRY POINT
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    _setupGlobalErrorHandling();

    // 🔥 Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ▶️ Start app
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    // 🔔 Setup notifications in background
    _setupNotificationsInBackground();
  }, (error, stack) {
    _logError('ZonedGuardedError', error, stack);
  });
}

/// 🛑 Global Error Handling
void _setupGlobalErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logError('FlutterError', details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _logError('PlatformError', error, stack);
    return true;
  };
}

/// 🧾 Centralized Error Logger
void _logError(String source, Object error, StackTrace? stack) {
  debugPrint('❌ [$source] Error: $error');
  if (stack != null) {
    debugPrint('📌 Stack trace:\n$stack');
  }

  // TODO: Send to Crashlytics / Sentry
  // FirebaseCrashlytics.instance.recordError(error, stack);
}

/// 🔔 Notification Setup (Non-blocking)
Future<void> _setupNotificationsInBackground() async {
  try {
    // 📲 Request Permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 📩 Background Messages
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 🔊 Android Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'carGo_channel',
      'CarGO Notifications',
      description: 'Channel for real-time notifications',
      importance: Importance.high,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    // ✅ Create Channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 📬 Foreground Notifications
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

    debugPrint("✅ Notifications setup completed");
  } catch (e, stack) {
    _logError('NotificationSetup', e, stack);
  }
}

/// 🎯 ROOT APP
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CarGO',

      // 🎨 THEMES
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // 🏠 START SCREEN
      home: const OnboardingScreen(),

      // 🧭 ROUTES
      routes: {
        '/login': (_) => const LoginPage(),
        '/renters': (_) => const HomeScreen(),
        '/car_list': (_) => const CarListScreen(),
        '/chat_list': (_) => const ChatListScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/my_bookings': (_) => const MyBookingsScreen(),
      },

      // 🧠 Dynamic Route (Owner Cars)
      onGenerateRoute: (settings) {
        if (settings.name == '/mycars') {
          final ownerId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => MyCarPage(ownerId: ownerId),
          );
        }
        return null;
      },
    );
  }
}

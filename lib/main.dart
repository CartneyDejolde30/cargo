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
import 'package:flutter_application_1/USERS-UI/Renter/favorites_screen.dart';
import 'package:flutter_application_1/services/user_presence_service.dart';
import 'package:flutter_application_1/services/persistent_auth_service.dart';
import 'package:flutter_application_1/USERS-UI/Owner/owner_home_screen.dart';

/// 🔔 Local Notifications Instance
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// 📩 Firebase Background Handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Setup error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError('FlutterError', details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('PlatformError', error, stack);
      return true;
    };

    // 🔥 Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

<<<<<<< HEAD
      // ✅ Do notification setup in background (non-blocking)
      _setupNotificationsInBackground();
      
      // ✅ Initialize presence service in background
      _initializePresenceService();
    },
    (error, stack) {
      _logError('ZonedGuardedError', error, stack);
    },
  );
}

/// ✅ NEW: Initialize presence service for logged-in users
Future<void> _initializePresenceService() async {
  try {
    final authService = PersistentAuthService();
    final isLoggedIn = await authService.isLoggedIn();
    
    if (isLoggedIn) {
      debugPrint('🟢 User is logged in - initializing presence service');
      
      // Add small delay to ensure Firebase is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      await UserPresenceService().initialize();
    } else {
      debugPrint('⚪ No logged in user - skipping presence service');
    }
  } catch (e) {
    debugPrint('❌ Error initializing presence service: $e');
  }
}

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

<<<<<<< HEAD
/// ✅ NEW: AuthWrapper to handle persistent login
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // ✅ Add small delay to ensure SharedPreferences is fully loaded
      await Future.delayed(const Duration(milliseconds: 200));
      
      final authService = PersistentAuthService();
      final isLoggedIn = await authService.isLoggedIn();
      final userRole = await authService.getUserRole();

      setState(() {
        _isLoggedIn = isLoggedIn;
        _userRole = userRole;
        _isLoading = false;
      });

      debugPrint('🔐 Auth check complete: ${isLoggedIn ? "LOGGED IN" : "NOT LOGGED IN"}');
      if (isLoggedIn) {
        debugPrint('   └─ Role: $userRole');
      } else {
        debugPrint('   └─ No session found');
      }
    } catch (e) {
      debugPrint('❌ Error checking auth status: $e');
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading screen while checking auth status
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLoggedIn && _userRole != null) {
      // User is logged in - navigate to appropriate home screen
      final normalizedRole = _userRole!.toLowerCase();
      
      if (normalizedRole == 'renter') {
        return const HomeScreen();
      } else if (normalizedRole == 'owner') {
        return OwnerHomeScreen();
      }
    }

    // User not logged in - show onboarding
    return const OnboardingScreen();
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
      home: const AuthWrapper(),

      // 🧭 ROUTES
      routes: {
        '/login': (context) => const LoginPage(),
        '/renters': (context) => const HomeScreen(),
        '/car_list': (context) => const CarListScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/chat_list': (context) => const ChatListScreen(),
        "/profile": (context) => const ProfileScreen(),
        '/my_bookings': (context) => const MyBookingsScreen(),
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
/// 🧾 Centralized Error Logger
void _logError(String source, Object error, StackTrace? stack) {
  debugPrint('❌ [$source] Error: $error');
  if (stack != null) {
    debugPrint('📌 Stack trace:\n$stack');
  }

  // Optional: Send to Crashlytics later
  // FirebaseCrashlytics.instance.recordError(error, stack);
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'register_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/USERS-UI/Renter/renters.dart';
import 'package:flutter_application_1/USERS-UI/Owner/owner_home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/Google/google_sign_in_service.dart';
import 'package:flutter_application_1/services/user_presence_service.dart';
import 'package:flutter_application_1/services/persistent_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/widgets/google_role_selection_dialog.dart';
// ❌ REMOVED: Facebook import

class CarGoApp extends StatelessWidget {
  const CarGoApp({super.key});

  void setUserStatus(String userId, bool online) {
    final ref = FirebaseDatabase.instance.ref("status/$userId");

    ref.set({
      "isOnline": online,
      "lastSeen": ServerValue.timestamp,
    });

    ref.onDisconnect().set({
      "isOnline": false,
      "lastSeen": ServerValue.timestamp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'CarGo Login',
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system,
  home: const LoginPage(),
);

  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  // ❌ REMOVED: FacebookSignInService
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isGoogleSigningIn = false;
  // ❌ REMOVED: _isFacebookSigningIn

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');
    bool remember = prefs.getBool('remember') ?? false;

    if (remember && email != null && password != null) {
      setState(() {
        _emailController.text = email;
        _passwordController.text = password;
        _rememberMe = true;
      });
    }
  }

  void _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('remember', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('remember', false);
    }
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    _saveCredentials();

    final url = Uri.parse(GlobalApiConfig.loginEndpoint);

    print("Sending JSON -> email: $email, password: $password");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // ✅ FIX: Check for "success" field instead of "status"
        if (responseData["success"] == true) {
          // Extract the actual user data from the "data" field
          final data = responseData["data"];
          
          // ✅ NEW: Sign in to Firebase Auth with custom token system
          // This authenticates the user with Firebase so Realtime Database rules work
          await _signInToFirebaseAuth(data);
          
          // ✅ Save user session using PersistentAuthService
          final authService = PersistentAuthService();
          await authService.saveUserSession(data);

          String role = data["role"].toString().toLowerCase(); // Convert to lowercase for comparison

          // ✅ OPTIMIZATION: Navigate immediately, do Firebase operations in background
          // Close loading dialog
          if (mounted) Navigator.pop(context);

          // Navigate to home screen immediately
          if (mounted) {
            if (role == "renter") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else if (role == "owner") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => OwnerHomeScreen()),
              );
            }
          }

          // ✅ Do Firebase operations in background (non-blocking)
          _updateFirebaseInBackground(data);
          
          // ✅ Initialize presence service for online status tracking
          _initializePresenceService();

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData["message"] ?? "Login successful")),
            );
          }
        } else {
          if (mounted) Navigator.pop(context);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData["message"] ?? "Login failed.")),
            );
          }
        }
      } else {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to server.')),
        );
      }
    }
  }

  // ✅ NEW: Sign in to Firebase Auth anonymously but link to user ID
  Future<void> _signInToFirebaseAuth(Map<String, dynamic> userData) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      
      // Check if already signed in
      if (auth.currentUser != null) {
        debugPrint('🔐 Already signed in to Firebase Auth: ${auth.currentUser!.uid}');
        return;
      }
      
      // Sign in anonymously - this gives us Firebase Auth credentials
      // We'll use the user's email as a unique identifier
      debugPrint('🔐 Signing in to Firebase Auth anonymously...');
      
      try {
        // Try to sign in with email (if Firebase Auth email is enabled)
        // For now, use anonymous auth which always works
        final userCredential = await auth.signInAnonymously();
        debugPrint('✅ Firebase Auth sign-in successful: ${userCredential.user?.uid}');
        
        // Update display name to match user ID
        await userCredential.user?.updateDisplayName(userData['id'].toString());
        
      } catch (e) {
        debugPrint('⚠️ Firebase Auth error (non-critical): $e');
        // Continue even if this fails - app will still work
      }
    } catch (e) {
      debugPrint('❌ Firebase Auth sign-in error: $e');
      // Don't throw - let the app continue
    }
  }

  // ✅ NEW: Initialize presence service
  Future<void> _initializePresenceService() async {
    try {
      await UserPresenceService().initialize();
      debugPrint('✅ Presence service initialized after login');
    } catch (e) {
      debugPrint('❌ Error initializing presence service: $e');
    }
  }

  // ✅ NEW: Background Firebase operations (non-blocking)
  Future<void> _updateFirebaseInBackground(Map<String, dynamic> data) async {
    try {
      final userRef = FirebaseFirestore.instance.collection("users").doc(data["id"].toString());

      // Check if user exists
      final docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        // Create new user
        await userRef.set({
          "uid": data["id"].toString(),
          "name": data["fullname"],               
          "avatar": data["profile_image"] ?? "",  
          "email": data["email"],
          "role": data["role"],
          "online": true,
          "createdAt": FieldValue.serverTimestamp(),
        });
        print("🔥 Firestore user CREATED in background");
      } else {
        // Update existing user - do both operations in parallel
        print("✔ Firestore user already exists → updating status");
        
        final futures = <Future>[];
        
        // Update user data
        futures.add(userRef.update({
          "online": true,
          "avatar": data["profile_image"] ?? "",
          "name": data["fullname"],
        }));

        // Get and update FCM token in parallel
        futures.add(
          FirebaseMessaging.instance.getToken().then((token) {
            if (token != null) {
              userRef.update({"fcm": token});
              print("📩 FCM Token Updated: $token");
            }
          }).catchError((e) {
            print("❌ Failed to save FCM Token: $e");
          })
        );

        // Wait for both operations to complete
        await Future.wait(futures);
      }
    } catch (e) {
      print("❌ Firebase background update error: $e");
      // Don't show error to user - this is background operation
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleSigningIn = true);

    try {
      final result = await _googleSignInService.signInWithGoogle();

      if (result == null) {
        setState(() => _isGoogleSigningIn = false);
        return;
      }

      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: ${result['error']}')),
        );
        setState(() => _isGoogleSigningIn = false);
        return;
      }

      if (result['isNewUser'] == true) {
        setState(() => _isGoogleSigningIn = false);
        _showRoleSelectionDialog(result);
      } else {
        final userData = result['user'];
        _navigateToHome(userData['role']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in error: $e')),
      );
    } finally {
      setState(() => _isGoogleSigningIn = false);
    }
  }

  void _showRoleSelectionDialog(Map<String, dynamic> googleData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GoogleRoleSelectionDialog(
          googleData: googleData,
          onComplete: (role, municipality) async {
            Navigator.pop(context);
            await _completeGoogleRegistration(
              googleData,
              role,
              municipality,
            );
          },
          onCancel: () {
            Navigator.pop(context);
            _googleSignInService.signOut();
          },
        );
      },
    );
  }

  Future<void> _completeGoogleRegistration(
    Map<String, dynamic> googleData,
    String role,
    String municipality,
  ) async {
    setState(() => _isGoogleSigningIn = true);

    final result = await _googleSignInService.registerGoogleUser(
      email: googleData['email'],
      fullName: googleData['fullName'],
      role: role,
      municipality: municipality,
      photoUrl: googleData['photoUrl'],
      firebaseUid: googleData['firebaseUid'],
    );

    setState(() => _isGoogleSigningIn = false);

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      _navigateToHome(role);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    }
  }

  // ❌ REMOVED: All Facebook-related methods
  // - _handleFacebookSignIn()
  // - _showFacebookRoleSelectionDialog()
  // - _completeFacebookRegistration()

  void _navigateToHome(String role) {
    // Convert role to lowercase for comparison
    final normalizedRole = role.toLowerCase();
    
    if (normalizedRole == "renter") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (normalizedRole == "owner") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OwnerHomeScreen()),
      );
    }
  }

  void _showForgotPasswordDialog() {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Forgot Password"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: "Enter your email",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Password reset link sent to ${emailController.text}')),
              );
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/cargo.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'CarGo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  color: Theme.of(context).iconTheme.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to hit the road.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                style: TextStyle(color: Theme.of(context).iconTheme.color),
                decoration: InputDecoration(
                  hintText: 'Email/Phone Number',
                  hintStyle:  TextStyle(color: Theme.of(context).disabledColor, fontSize: 14),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style:  TextStyle(color: Theme.of(context).iconTheme.color),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle:  TextStyle(color: Theme.of(context).disabledColor, fontSize: 14),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).disabledColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value!);
                          },
                          activeColor: Theme.of(context).iconTheme.color,
                          checkColor: Theme.of(context).colorScheme.onPrimary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                       Text(
                        'Remember Me',
                        style: TextStyle(color: Theme.of(context).iconTheme.color, fontSize: 13),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child:  Text(
                      'Forgot Password',
                      style: TextStyle(color: Theme.of(context).iconTheme.color, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children:  [
                  Expanded(child: Divider(color: Theme.of(context).dividerColor, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or',
                      style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).dividerColor, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              // ❌ REMOVED: Facebook Login Button

              // Google Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isGoogleSigningIn ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    side:  BorderSide(color: Theme.of(context).dividerColor, width: 1),
                    foregroundColor: Theme.of(context).iconTheme.color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isGoogleSigningIn
                      ?  SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).iconTheme.color,
                                ),

                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/search.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 12),
                            const Flexible(
                              child: Text(
                                'Continue with Google',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
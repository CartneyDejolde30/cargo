import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user online/offline presence in real-time
/// Uses both Firebase Realtime Database and Firestore for redundancy
class UserPresenceService with WidgetsBindingObserver {
  static final UserPresenceService _instance = UserPresenceService._internal();
  factory UserPresenceService() => _instance;
  UserPresenceService._internal();

  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _currentUserId;
  DatabaseReference? _presenceRef;
  DatabaseReference? _statusRef;
  StreamSubscription? _connectionSubscription;
  bool _isInitialized = false;

  /// Initialize presence tracking for the current user
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ UserPresenceService already initialized');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');

      if (_currentUserId == null) {
        debugPrint('❌ No user_id found in SharedPreferences');
        return;
      }

      debugPrint('🟢 Initializing presence service for user: $_currentUserId');

      // Set up lifecycle observer
      WidgetsBinding.instance.addObserver(this);

      // ✅ FIX: First check if user document exists, create if needed
      await _ensureUserDocumentExists();

      // Set user as online
      await _setOnlineStatus(true);

      // Listen to connection state
      _listenToConnectionState();

      _isInitialized = true;
      debugPrint('✅ UserPresenceService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing UserPresenceService: $e');
    }
  }

  /// Ensure user document exists in Firestore with offline status by default
  Future<void> _ensureUserDocumentExists() async {
    if (_currentUserId == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      
      if (!userDoc.exists) {
        debugPrint('📝 Creating user document for $_currentUserId');
        
        // Get user info from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        
        await _firestore.collection('users').doc(_currentUserId).set({
          'uid': _currentUserId,
          'name': prefs.getString('fullname') ?? 'User',
          'email': prefs.getString('email') ?? '',
          'role': prefs.getString('role') ?? '',
          'avatar': prefs.getString('profile_image') ?? '',
          'online': false, // Start as offline
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (!userDoc.data()!.containsKey('online')) {
        // Document exists but doesn't have online field
        debugPrint('🔧 Adding online field to existing user document');
        await _firestore.collection('users').doc(_currentUserId).update({
          'online': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error ensuring user document: $e');
    }
  }

  /// Listen to Firebase connection state changes
  void _listenToConnectionState() {
    final connectedRef = _realtimeDb.ref('.info/connected');
    
    _connectionSubscription = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      
      if (connected) {
        debugPrint('🟢 Firebase connected - setting user online');
        _setOnlineStatus(true);
        _setupDisconnectHandler();
      } else {
        debugPrint('🔴 Firebase disconnected');
      }
    });
  }

  /// Set up disconnect handler to update status when user goes offline
  void _setupDisconnectHandler() {
    if (_currentUserId == null) return;

    // Realtime Database disconnect handler
    _presenceRef = _realtimeDb.ref('presence/$_currentUserId');
    _statusRef = _realtimeDb.ref('status/$_currentUserId');

    // Set what should happen when user disconnects
    _presenceRef!.onDisconnect().set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });

    _statusRef!.onDisconnect().set({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });

    // Set current online status
    _presenceRef!.set({
      'online': true,
      'lastSeen': ServerValue.timestamp,
    });

    _statusRef!.set({
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
    });

    debugPrint('✅ Disconnect handler set up');
  }

  /// Set user online/offline status
  Future<void> _setOnlineStatus(bool online) async {
    if (_currentUserId == null) return;

    try {
      final timestamp = FieldValue.serverTimestamp();
      
      // Update Firestore
      await _firestore.collection('users').doc(_currentUserId).set({
        'online': online,
        'lastSeen': timestamp,
      }, SetOptions(merge: true));

      // Update Realtime Database
      await _realtimeDb.ref('presence/$_currentUserId').set({
        'online': online,
        'lastSeen': ServerValue.timestamp,
      });

      await _realtimeDb.ref('status/$_currentUserId').set({
        'isOnline': online,
        'lastSeen': ServerValue.timestamp,
      });

      debugPrint('✅ User status set to: ${online ? "ONLINE" : "OFFLINE"}');
    } catch (e) {
      debugPrint('❌ Error setting online status: $e');
    }
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed - setting user ONLINE');
        _setOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
        debugPrint('📱 App paused - setting user OFFLINE (session persists)');
        // ✅ Only update online status, DON'T clear session
        _setOnlineStatus(false);
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 App inactive - no action needed');
        // Do nothing - this happens during transitions
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App detached - setting user OFFLINE (session persists)');
        // ✅ Only update online status, DON'T clear session
        _setOnlineStatus(false);
        break;
      case AppLifecycleState.hidden:
        debugPrint('📱 App hidden - no action needed');
        // Do nothing - this is a brief state
        break;
    }
  }

  /// Get real-time presence stream for a specific user (for UI)
  Stream<bool> getUserPresenceStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        debugPrint('⚠️ User document does not exist for: $userId');
        return false;
      }
      
      final data = snapshot.data();
      if (data == null) {
        debugPrint('⚠️ User data is null for: $userId');
        return false;
      }
      
      final isOnline = data['online'] ?? false;
      debugPrint('👤 User $userId online status: $isOnline');
      return isOnline;
    });
  }

  /// Get user's last seen timestamp
  Stream<DateTime?> getUserLastSeenStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final lastSeen = snapshot.data()?['lastSeen'] as Timestamp?;
      return lastSeen?.toDate();
    });
  }

  /// Check if user is currently online (one-time check)
  Future<bool> isUserOnline(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      return doc.data()?['online'] ?? false;
    } catch (e) {
      debugPrint('❌ Error checking user online status: $e');
      return false;
    }
  }

  /// Get user's last seen (one-time check)
  Future<DateTime?> getUserLastSeen(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final lastSeen = doc.data()?['lastSeen'] as Timestamp?;
      return lastSeen?.toDate();
    } catch (e) {
      debugPrint('❌ Error getting user last seen: $e');
      return null;
    }
  }

  /// Manually set user offline (for logout)
  Future<void> setOffline() async {
    await _setOnlineStatus(false);
  }

  /// Manually set user online (for login)
  Future<void> setOnline() async {
    await _setOnlineStatus(true);
  }

  /// Clean up resources (called ONLY on logout, NOT on app close)
  Future<void> dispose() async {
    debugPrint('🧹 Disposing UserPresenceService (LOGOUT ONLY)');
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Set user offline
    await _setOnlineStatus(false);
    
    // Cancel subscriptions
    await _connectionSubscription?.cancel();
    
    // Clear references
    _presenceRef = null;
    _statusRef = null;
    _currentUserId = null;
    _isInitialized = false;
    
    debugPrint('✅ UserPresenceService disposed (user logged out)');
  }
}

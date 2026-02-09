import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility script to reset all users to offline status in Firebase
/// Run this once to fix the "everyone is online" issue
/// 
/// Usage: Call this from a button or run once on app startup
Future<void> resetAllUsersOffline() async {
  try {
    print('🔄 Starting to reset all users to offline...');
    
    final firestore = FirebaseFirestore.instance;
    
    // Get all user documents
    final usersSnapshot = await firestore.collection('users').get();
    
    print('📊 Found ${usersSnapshot.docs.length} users');
    
    // Batch update for efficiency
    final batch = firestore.batch();
    int count = 0;
    
    for (var doc in usersSnapshot.docs) {
      batch.update(doc.reference, {
        'online': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      count++;
      
      // Firebase batch limit is 500 operations
      if (count % 500 == 0) {
        await batch.commit();
        print('✅ Updated $count users...');
      }
    }
    
    // Commit remaining updates
    if (count % 500 != 0) {
      await batch.commit();
    }
    
    print('✅ Successfully reset $count users to offline status');
    print('🎉 All users are now offline. They will go online when they open the app.');
    
  } catch (e) {
    print('❌ Error resetting users: $e');
    rethrow;
  }
}

/// Alternative: Reset only users who haven't been seen in the last 24 hours
Future<void> resetInactiveUsersOffline() async {
  try {
    print('🔄 Resetting inactive users to offline...');
    
    final firestore = FirebaseFirestore.instance;
    final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
    
    // Get users who are marked online but haven't been seen recently
    final usersSnapshot = await firestore
        .collection('users')
        .where('online', isEqualTo: true)
        .get();
    
    final batch = firestore.batch();
    int count = 0;
    
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final lastSeen = data['lastSeen'] as Timestamp?;
      
      // If lastSeen is null or older than 24 hours, set offline
      if (lastSeen == null || lastSeen.toDate().isBefore(twentyFourHoursAgo)) {
        batch.update(doc.reference, {
          'online': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        count++;
      }
    }
    
    if (count > 0) {
      await batch.commit();
      print('✅ Reset $count inactive users to offline');
    } else {
      print('ℹ️ No inactive users to reset');
    }
    
  } catch (e) {
    print('❌ Error resetting inactive users: $e');
    rethrow;
  }
}

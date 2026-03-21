import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// In-memory cache for the current user's profile data.
/// Avoids redundant Firestore reads across screens.
class UserCache {
  // Singleton
  static final UserCache _instance = UserCache._internal();
  factory UserCache() => _instance;
  UserCache._internal();

  Map<String, dynamic>? _profileData;

  /// Returns cached profile data, or null if not loaded yet.
  Map<String, dynamic>? get profileData => _profileData;

  /// Whether profile data is cached.
  bool get hasCachedProfile => _profileData != null;

  /// Loads the profile from Firestore and caches it.
  /// Only reads from Firestore if not already cached (or if [forceRefresh] is true).
  Future<Map<String, dynamic>?> loadProfile({bool forceRefresh = false}) async {
    if (_profileData != null && !forceRefresh) {
      return _profileData;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      var doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        _profileData = doc.data()!;
      }
    } catch (e) {
      debugPrint("UserCache: Error loading profile: $e");
    }

    return _profileData;
  }

  /// Updates the cache with new data (e.g., after profile save).
  /// Does NOT write to Firestore — just updates the local cache.
  void updateCache(Map<String, dynamic> newData) {
    _profileData ??= {};
    _profileData!.addAll(newData);
  }

  /// Clears the cache (e.g., on logout).
  void clear() {
    _profileData = null;
  }
}

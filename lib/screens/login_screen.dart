import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_dashboard.dart';
import 'warden_dashboard.dart';
import 'profile_setup.dart';

const List<String> wardenEmails = [
  "23ece1032@nitgoa.ac.in",
  "warden2@nitgoa.ac.in",
  "warden3@nitgoa.ac.in",
];

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      googleProvider.setCustomParameters({
        "hd": "nitgoa.ac.in"
      });

      await FirebaseAuth.instance.signInWithPopup(googleProvider);

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {

        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({
          "name": user.displayName,
          "email": user.email,
          "role": "student",
          "createdAt": Timestamp.now(),
        }, SetOptions(merge: true));

        String email = user.email ?? "";

        // Check if we should still use the context
        if (!context.mounted) return;

        if (wardenEmails.contains(email)) {

          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const WardenDashboard(),
            ),
          );

        } else {

          // Check if student profile is complete
          bool isProfileComplete = await checkProfileCompletion(user.uid);

          if (!context.mounted) return;

          if (isProfileComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentDashboard(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileSetup(isFirstTime: true),
              ),
            );
          }

        }

      }

    } catch (e) {
      print("Login error: $e");
    }
  }

  Future<bool> checkProfileCompletion(String userId) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      if (!doc.exists) {
        return false;
      }

      var data = doc.data();

      if (data == null) {
        return false;
      }

      // Check if all required fields are filled
      bool hasRollNumber = data["rollNumber"] != null &&
          (data["rollNumber"] as String).isNotEmpty;
      bool hasDegree = data["degree"] != null &&
          (data["degree"] as String).isNotEmpty;
      bool hasHostel = data["hostel"] != null &&
          (data["hostel"] as String).isNotEmpty;
      bool hasRoomNumber = data["roomNumber"] != null &&
          (data["roomNumber"] as String).isNotEmpty;
      bool hasPhone = data["phone"] != null &&
          (data["phone"] as String).isNotEmpty;

      // Photo is now optional
      return hasRollNumber && hasDegree && hasHostel &&
          hasRoomNumber && hasPhone;
    } catch (e) {
      print("Error checking profile: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "NIT Goa Gate System",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () => signInWithGoogle(context),
              child: const Text("Sign in with Google"),
            ),
          ],
        ),
      ),
    );
  }
}
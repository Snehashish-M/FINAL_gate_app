import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'day_scholar.dart';
import 'hostel_exit.dart';
import 'leave_application.dart';
import 'leave_status.dart';
import 'profile_setup.dart';
import 'login_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {

  Uint8List? photoBytes;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      var doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        String? photo = doc.data()!["photo"];
        if (photo != null && photo.isNotEmpty && mounted) {
          try {
            setState(() {
              photoBytes = base64Decode(photo);
            });
          } catch (e) {
            debugPrint("Error decoding photo: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading photo: $e");
    }
  }

  void _handleMenuSelection(String value) async {
    if (value == "edit_profile") {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileSetup(),
        ),
      );
      // Reload photo in case user changed it
      _loadPhoto();
    } else if (value == "logout") {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(

      appBar: AppBar(
        title: const Text("Student Dashboard"),
        actions: [

          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            offset: const Offset(0, 50),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "edit_profile",
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 10),
                    Text("Edit Profile"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: "logout",
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 10),
                    Text("Log Out"),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: photoBytes != null
                    ? MemoryImage(photoBytes!)
                    : null,
                child: photoBytes == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
            ),
          ),

        ],
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              "Welcome ${user?.displayName ?? ""}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DayScholar(),
                  ),
                );

              },
              child: const Text("Day Scholar"),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HostelExit(),
                  ),
                );

              },
              child: const Text("Hostel Entry / Exit"),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaveApplication(),
                  ),
                );

              },
              child: const Text("Leave Application"),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaveStatus(),
                  ),
                );

              },
              child: const Text("Leave Status"),
            ),

          ],
        ),
      ),
    );
  }
}
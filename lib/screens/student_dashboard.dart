import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'day_scholar.dart';
import 'hostel_exit.dart';
import 'leave_application.dart';
import 'leave_status.dart';
import 'profile_setup.dart';
import 'login_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(

      appBar: AppBar(
        title: const Text("Student Dashboard"),
        actions: [

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {

              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );

            },
          )

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

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSetup(),
                  ),
                );

              },
              child: const Text("Edit Profile"),
            ),

          ],
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_dashboard.dart';

class ProfileSetup extends StatefulWidget {
  final bool isFirstTime;

  const ProfileSetup({super.key, this.isFirstTime = false});

  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {

  final rollController = TextEditingController();
  final degreeController = TextEditingController();
  final hostelController = TextEditingController();
  final roomController = TextEditingController();
  final phoneController = TextEditingController();

  Uint8List? _imageBytes;
  String? existingPhotoBase64; // base64 string from Firestore
  String _photoStatus = "";

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    rollController.dispose();
    degreeController.dispose();
    hostelController.dispose();
    roomController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future loadProfile() async {

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      var doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {

        var data = doc.data()!;

        rollController.text = data["rollNumber"] ?? "";
        degreeController.text = data["degree"] ?? "";
        hostelController.text = data["hostel"] ?? "";
        roomController.text = data["roomNumber"] ?? "";
        phoneController.text = data["phone"] ?? "";

        existingPhotoBase64 = data["photo"];

        setState(() {});
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: ${e.toString()}")),
        );
      }
    }
  }

  Future pickImage() async {

    // Compress: max 200x200 pixels, 70% quality → keeps size under 50KB
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 70,
    );

    if (picked != null) {

      final bytes = await picked.readAsBytes();
      final sizeKB = (bytes.length / 1024).toStringAsFixed(1);

      setState(() {
        _imageBytes = bytes;
        _photoStatus = "Photo selected ✓ (${sizeKB}KB)";
      });

    }
  }

  /// Get the photo to display as bytes (from picked image or existing base64)
  Uint8List? _getDisplayBytes() {
    if (_imageBytes != null) return _imageBytes;
    if (existingPhotoBase64 != null && existingPhotoBase64!.isNotEmpty) {
      try {
        return base64Decode(existingPhotoBase64!);
      } catch (e) {
        debugPrint("Error decoding photo: $e");
        return null;
      }
    }
    return null;
  }

  Future saveProfile() async {

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("ERROR: No user found");
      return;
    }

    if (rollController.text.isEmpty ||
        degreeController.text.isEmpty ||
        hostelController.text.isEmpty ||
        roomController.text.isEmpty ||
        phoneController.text.isEmpty) {

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (!mounted) return;

    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Saving profile..."),
            ],
          ),
        );
      },
    );

    try {
      // Encode photo as base64 string to store directly in Firestore
      String photoBase64 = existingPhotoBase64 ?? "";

      if (_imageBytes != null) {
        photoBase64 = base64Encode(_imageBytes!);
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({

        "rollNumber": rollController.text,
        "degree": degreeController.text,
        "hostel": hostelController.text,
        "roomNumber": roomController.text,
        "phone": phoneController.text,
        "photo": photoBase64,

      }, SetOptions(merge: true));

      // Close loading dialog
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              photoBase64.isNotEmpty
                  ? "Profile saved with photo ✓"
                  : "Profile saved (no photo)",
            ),
          ),
        );
      }

      // If first time setup, navigate to StudentDashboard
      if (widget.isFirstTime && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentDashboard(),
          ),
        );
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");

      // Close loading dialog
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final displayBytes = _getDisplayBytes();

    return Scaffold(

      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: ListView(
          children: [

            if (widget.isFirstTime)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1976D2)),
                ),
                child: const Text(
                  "Complete your profile to access the student portal. All text fields are mandatory. Photo is optional.",
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (widget.isFirstTime)
              const SizedBox(height: 20),

            // Photo preview — centered circle
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: displayBytes != null
                        ? MemoryImage(displayBytes)
                        : null,
                    child: displayBytes == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Photo status text
            if (_photoStatus.isNotEmpty)
              Center(
                child: Text(
                  _photoStatus,
                  style: TextStyle(
                    color: _photoStatus.contains("✗")
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            TextField(
              controller: rollController,
              decoration: const InputDecoration(
                labelText: "Roll Number",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: degreeController,
              decoration: const InputDecoration(
                labelText: "Degree",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: hostelController,
              decoration: const InputDecoration(
                labelText: "Hostel Name",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: "Room Number",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: saveProfile,
              child: const Text("Save Profile"),
            ),

          ],
        ),
      ),
    );
  }
}
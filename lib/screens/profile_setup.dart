import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  String? existingPhoto;

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

        existingPhoto = data["photo"];

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

    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {

      final bytes = await picked.readAsBytes();

      setState(() {
        _imageBytes = bytes;
      });

    }
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
      String imageUrl = existingPhoto ?? "";

      if (_imageBytes != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child("profile_photos")
              .child("${user.uid}.jpg");

          // Add content-type metadata for better Storage compatibility
          final metadata = SettableMetadata(contentType: 'image/jpeg');

          final task = ref.putData(_imageBytes!, metadata);

          await task.timeout(
            const Duration(seconds: 60),
          );

          imageUrl = await ref.getDownloadURL();
          debugPrint("Image uploaded successfully");
        } catch (uploadError) {
          debugPrint("Error uploading image: $uploadError");
          // Don't throw - allow profile to save without photo
          imageUrl = existingPhoto ?? "";
        }
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
        "photo": imageUrl,

      }, SetOptions(merge: true));

      // Close loading dialog using the dialogContext
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Saved Successfully")),
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

            if (_imageBytes != null)
              Image.memory(_imageBytes!, height: 120)

            else if (existingPhoto != null && existingPhoto!.isNotEmpty)
              Image.network(existingPhoto!, height: 120),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Upload Photo"),
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
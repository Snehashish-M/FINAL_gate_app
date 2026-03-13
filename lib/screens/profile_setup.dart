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

  Future loadProfile() async {

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

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

    print("=== PROFILE SAVE STARTED ===");

    User? user = FirebaseAuth.instance.currentUser;

    print("User: $user");
    if (user == null) {
      print("ERROR: No user found");
      return;
    }

    // Validate all required fields
    print("Validating fields...");
    print("Roll: ${rollController.text}");
    print("Degree: ${degreeController.text}");
    print("Hostel: ${hostelController.text}");
    print("Room: ${roomController.text}");
    print("Phone: ${phoneController.text}");
    print("Image bytes: ${_imageBytes != null ? 'YES' : 'NO'}");
    print("Existing photo: $existingPhoto");

    if (rollController.text.isEmpty ||
        degreeController.text.isEmpty ||
        hostelController.text.isEmpty ||
        roomController.text.isEmpty ||
        phoneController.text.isEmpty) {

      print("ERROR: Validation failed");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    // On first time setup, photo is optional. On edit, photo is also optional
    print("Photo check passed (photo is optional)");

    print("Validation passed");
    print("Mounted: $mounted");

    // Show loading dialog
    if (!mounted) {
      print("ERROR: Not mounted before showing dialog");
      return;
    }

    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        print("Dialog builder called");
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

    print("Dialog shown");

    try {
      String imageUrl = existingPhoto ?? "";
      print("Initial image URL: $imageUrl");

      if (_imageBytes != null) {
        print("Uploading image...");
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child("profile_photos")
              .child("${user.uid}.jpg");

          print("Firebase Storage ref created: ${ref.fullPath}");
          print("Image size: ${_imageBytes!.length} bytes");

          print("Attempting upload...");
          final task = ref.putData(_imageBytes!);

          // Listen to upload progress
          task.snapshotEvents.listen((event) {
            print("Upload progress: ${event.bytesTransferred}/${event.totalBytes}");
          });

          await task.timeout(
            const Duration(seconds: 60),
          );

          print("Image uploaded successfully");

          imageUrl = await ref.getDownloadURL();
          print("Image URL obtained: $imageUrl");
        } catch (uploadError) {
          print("ERROR uploading image: $uploadError");
          print("Error type: ${uploadError.runtimeType}");
          // Don't throw - allow profile to save without photo
          print("Continuing without photo...");
          imageUrl = ""; // Set empty photo URL
        }
      }

      print("Saving to Firestore...");
      print("Document path: users/${user.uid}");
      print("Data: {rollNumber: ${rollController.text}, degree: ${degreeController.text}, hostel: ${hostelController.text}, roomNumber: ${roomController.text}, phone: ${phoneController.text}, photo: $imageUrl}");

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

      print("Firestore save completed");

      // Close loading dialog using the dialogContext
      if (dialogContext != null && dialogContext!.mounted) {
        print("Closing dialog...");
        Navigator.of(dialogContext!).pop();
        print("Dialog closed");
      } else {
        print("ERROR: Dialog context not available");
      }

      if (mounted) {
        print("Showing success message");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Saved Successfully")),
        );
      }

      // If first time setup, navigate to StudentDashboard
      if (widget.isFirstTime && mounted) {
        print("First time setup - navigating to StudentDashboard");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentDashboard(),
          ),
        );
      } else if (mounted) {
        print("Editing existing profile - popping back");
        Navigator.pop(context);
      }
      print("=== PROFILE SAVE COMPLETED SUCCESSFULLY ===");
    } catch (e) {
      print("=== ERROR IN PROFILE SAVE ===");
      print("Exception: $e");
      print("Exception type: ${e.runtimeType}");

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

    print("=== PROFILE SETUP WIDGET BUILDING ===");

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
              onPressed: () {
                print("=== SAVE BUTTON TAPPED ===");
                saveProfile();
              },
              child: const Text("Save Profile"),
            ),

          ],
        ),
      ),
    );
  }
}
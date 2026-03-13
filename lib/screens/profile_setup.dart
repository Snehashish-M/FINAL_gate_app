import 'dart:io';
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

  File? _image;
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

      setState(() {
        _image = File(picked.path);
      });

    }
  }

  Future saveProfile() async {

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    // Validate all required fields
    if (rollController.text.isEmpty ||
        degreeController.text.isEmpty ||
        hostelController.text.isEmpty ||
        roomController.text.isEmpty ||
        phoneController.text.isEmpty ||
        _image == null && existingPhoto == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and upload a photo")),
      );
      return;
    }

    String imageUrl = existingPhoto ?? "";

    if (_image != null) {

      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_photos")
          .child("${user.uid}.jpg");

      await ref.putFile(_image!);

      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({

      "rollNumber": rollController.text,
      "degree": degreeController.text,
      "hostel": hostelController.text,
      "roomNumber": roomController.text,
      "phone": phoneController.text,
      "photo": imageUrl,

    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Saved")),
    );

    // If first time setup, navigate to StudentDashboard
    if (widget.isFirstTime) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const StudentDashboard(),
        ),
      );
    } else {
      Navigator.pop(context);
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
                  "Complete your profile to access the student portal. All fields are mandatory.",
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (widget.isFirstTime)
              const SizedBox(height: 20),

            if (_image != null)
              Image.file(_image!, height: 120)

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
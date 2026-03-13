import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DayScholar extends StatefulWidget {
  const DayScholar({super.key});

  @override
  State<DayScholar> createState() => _DayScholarState();
}

class _DayScholarState extends State<DayScholar> {

  final placeController = TextEditingController();

  Map<String, dynamic>? userData;

  String? qrData;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future loadUserProfile() async {

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    var doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    setState(() {
      userData = doc.data();
    });

  }

  Future generateQR() async {

    if (userData == null) return;

    // Validate place field
    if (placeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter where you are coming from")),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    DocumentReference passRef =
        FirebaseFirestore.instance.collection("gate_passes").doc();

    await passRef.set({

      "studentId": user.uid,

      "name": userData!["name"],
      "rollNumber": userData!["rollNumber"],
      "degree": userData!["degree"],
      "phone": userData!["phone"],

      "comingFrom": placeController.text,

      "type": "day_scholar",

      "status": "active",

      "scanCount": 0,

      "createdAt": Timestamp.now()

    });

    setState(() {
      qrData = passRef.id;
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Day Scholar Portal"),
      ),

      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),

              child: ListView(
                children: [

                  TextField(
                    controller: placeController,
                    decoration: const InputDecoration(
                      labelText: "Place you are coming from",
                    ),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: generateQR,
                    child: const Text("Generate QR"),
                  ),

                  const SizedBox(height: 40),

                  if (qrData != null)
                    Center(
                      child: QrImageView(
                        data: qrData!,
                        size: 250,
                      ),
                    ),

                ],
              ),
            ),
    );
  }
}
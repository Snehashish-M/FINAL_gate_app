import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LeaveApplication extends StatefulWidget {
  const LeaveApplication({super.key});

  @override
  State<LeaveApplication> createState() => _LeaveApplicationState();
}

class _LeaveApplicationState extends State<LeaveApplication> {

  Map<String, dynamic>? userData;

  final floorController = TextEditingController();
  final transportController = TextEditingController();
  final purposeController = TextEditingController();
  final addressController = TextEditingController();
  final parentPhoneController = TextEditingController();

  DateTime? leavingDate;
  DateTime? returnDate;

  TimeOfDay? leavingTime;
  TimeOfDay? returnTime;

  int durationDays = 0;

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

  Future pickDate(bool isLeaving) async {

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {

      setState(() {

        if (isLeaving) {
          leavingDate = picked;
        } else {
          returnDate = picked;
        }

        calculateDuration();

      });

    }
  }

  Future pickTime(bool isLeaving) async {

    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {

      setState(() {

        if (isLeaving) {
          leavingTime = picked;
        } else {
          returnTime = picked;
        }

      });

    }
  }

  void calculateDuration() {

    if (leavingDate != null && returnDate != null) {

      durationDays = returnDate!.difference(leavingDate!).inDays + 1;

    }

  }

  Future submitApplication() async {

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance.collection("leave_requests").add({

      "studentId": user.uid,

      "name": userData?["name"],
      "rollNumber": userData?["rollNumber"],
      "degree": userData?["degree"],
      "hostel": userData?["hostel"],
      "roomNumber": userData?["roomNumber"],
      "phone": userData?["phone"],

      "floor": floorController.text,

      "leavingDate": leavingDate,
      "returnDate": returnDate,

      "leavingTime": leavingTime?.format(context),
      "returnTime": returnTime?.format(context),

      "durationDays": durationDays,

      "modeOfTransport": transportController.text,
      "purpose": purposeController.text,

      "addressDuringLeave": addressController.text,
      "parentPhone": parentPhoneController.text,

      "status": "pending",

      "createdAt": Timestamp.now()

    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Leave Application Submitted")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Leave Application"),
      ),

      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),

              child: ListView(
                children: [

                  Text("Name: ${userData!["name"]}"),
                  Text("Roll Number: ${userData!["rollNumber"]}"),
                  Text("Degree: ${userData!["degree"]}"),
                  Text("Hostel: ${userData!["hostel"]}"),
                  Text("Room: ${userData!["roomNumber"]}"),
                  Text("Phone: ${userData!["phone"]}"),

                  const SizedBox(height: 20),

                  TextField(
                    controller: floorController,
                    decoration: const InputDecoration(labelText: "Floor"),
                  ),

                  const SizedBox(height: 20),

                  ListTile(
                    title: Text(leavingDate == null
                        ? "Select Leaving Date"
                        : DateFormat('yyyy-MM-dd').format(leavingDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => pickDate(true),
                  ),

                  ListTile(
                    title: Text(leavingTime == null
                        ? "Select Leaving Time"
                        : leavingTime!.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => pickTime(true),
                  ),

                  const SizedBox(height: 10),

                  ListTile(
                    title: Text(returnDate == null
                        ? "Select Return Date"
                        : DateFormat('yyyy-MM-dd').format(returnDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => pickDate(false),
                  ),

                  ListTile(
                    title: Text(returnTime == null
                        ? "Select Return Time"
                        : returnTime!.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => pickTime(false),
                  ),

                  const SizedBox(height: 10),

                  Text("Duration: $durationDays days"),

                  const SizedBox(height: 20),

                  TextField(
                    controller: transportController,
                    decoration: const InputDecoration(labelText: "Mode of Transport"),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: purposeController,
                    decoration: const InputDecoration(labelText: "Purpose of Leave"),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "Address During Leave"),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: parentPhoneController,
                    decoration: const InputDecoration(labelText: "Parent Phone Number"),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: submitApplication,
                    child: const Text("Submit Application"),
                  ),

                ],
              ),
            ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WardenDashboard extends StatelessWidget {
  const WardenDashboard({super.key});

  Future approveRequest(DocumentSnapshot request) async {

    DocumentReference passRef =
        FirebaseFirestore.instance.collection("gate_passes").doc();

    await passRef.set({

      "studentId": request["studentId"],

      "name": request["name"],
      "rollNumber": request["rollNumber"],
      "degree": request["degree"],
      "hostel": request["hostel"],
      "roomNumber": request["roomNumber"],

      "type": "leave",

      "leavingDate": request["leavingDate"],
      "returnDate": request["returnDate"],

      "status": "active",

      "scanCount": 0,

      "createdAt": Timestamp.now()

    });

    await FirebaseFirestore.instance
        .collection("leave_requests")
        .doc(request.id)
        .update({
      "status": "approved",
      "passId": passRef.id
    });

  }

  Future rejectRequest(DocumentSnapshot request) async {

    await FirebaseFirestore.instance
        .collection("leave_requests")
        .doc(request.id)
        .update({
      "status": "rejected"
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Warden Dashboard"),
      ),

      body: StreamBuilder(

        stream: FirebaseFirestore.instance
            .collection("leave_requests")
            .where("status", isEqualTo: "pending")
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No Pending Requests"));
          }

          return ListView.builder(

            itemCount: docs.length,

            itemBuilder: (context, index) {

              var request = docs[index];

              return Card(

                margin: const EdgeInsets.all(10),

                child: Padding(
                  padding: const EdgeInsets.all(15),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text("Name: ${request["name"]}"),
                      Text("Roll: ${request["rollNumber"]}"),
                      Text("Degree: ${request["degree"]}"),
                      Text("Hostel: ${request["hostel"]}"),
                      Text("Room: ${request["roomNumber"]}"),

                      const SizedBox(height: 10),

                      Text("Purpose: ${request["purpose"]}"),

                      const SizedBox(height: 10),

                      Row(

                        children: [

                          ElevatedButton(
                            onPressed: () {
                              approveRequest(request);
                            },
                            child: const Text("Approve"),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            onPressed: () {
                              rejectRequest(request);
                            },
                            child: const Text("Reject"),
                          ),

                        ],
                      )

                    ],
                  ),
                ),

              );

            },

          );

        },

      ),

    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/screens/nurse_chat_screen.dart';

class NurseListScreen extends StatefulWidget {
  const NurseListScreen({Key? key}) : super(key: key);

  @override
  State<NurseListScreen> createState() => _NurseListScreenState();
}

class _NurseListScreenState extends State<NurseListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Available Nurses",
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo[900],
      ),

      body: StreamBuilder(
        stream: _firestore.collection("nurse").snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var nurses = snapshot.data.docs;

          if (nurses.isEmpty) {
            return const Center(
              child: Text("No nurses available"),
            );
          }

          return ListView.builder(
            itemCount: nurses.length,
            itemBuilder: (context, index) {
              var nurse = nurses[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),

                  title: Text(
                    nurse['name'] ?? "Nurse",
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hospital: ${nurse['hospital'] ?? 'N/A'}"),
                      Text("Experience: ${nurse['experience'] ?? '0'} years"),
                      Text("Phone: ${nurse['phone'] ?? 'Not added'}"),
                    ],
                  ),

                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text("Call"),
                        onTap: () {
                          // optional call logic
                        },
                      ),
                      PopupMenuItem(
                        child: const Text("Contact"),
                        onTap: () {
                          _openChat(nurse.id, nurse['name']);
                        },
                      ),
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

  void _openChat(String nurseId, String nurseName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NurseChatScreen(
          nurseId: nurseId,
          nurseName: nurseName,
        ),
      ),
    );
  }
}
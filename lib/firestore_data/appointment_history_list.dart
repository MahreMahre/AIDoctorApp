import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/globals.dart';
import 'package:intl/intl.dart';

class AppointmentHistoryList extends StatefulWidget {
  const AppointmentHistoryList({Key? key}) : super(key: key);

  @override
  State<AppointmentHistoryList> createState() => _AppointmentHistoryListState();
}

class _AppointmentHistoryListState extends State<AppointmentHistoryList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  String _dateFormatter(Timestamp timestamp) {
    try {
      return DateFormat('dd-MM-yyyy').format(timestamp.toDate());
    } catch (_) {
      return 'Invalid date';
    }
  }

  Future<void> deleteAppointment(String docID) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(user!.uid)
          .collection('all')
          .doc(docID)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete appointment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .doc(user!.uid)
              .collection('all')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('An error occurred while fetching data.'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'No appointment history found.',
                  // style: GoogleFonts.lato(
                  //   color: Colors.grey[600],
                  //   fontSize: 18,
                  //   fontWeight: FontWeight.w500,
                  // ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                final String name = isDoctor
                    ? data['patientName'] ?? 'Unknown Patient'
                    : data['doctorName'] ?? 'Unknown Doctor';
                final String description = data['description'] ?? 'No description';
                final Timestamp? timestamp = data['date'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.blueGrey[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    title: Text(
                      '${index + 1}. $name',
                      // style: GoogleFonts.lato(fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timestamp != null
                              ? _dateFormatter(timestamp)
                              : 'No Date',
                          // style: GoogleFonts.lato(
                          //   fontSize: 13,
                          //   fontWeight: FontWeight.bold,
                          // ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          // style: GoogleFonts.lato(fontSize: 13),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever,
                          color: Colors.redAccent),
                      onPressed: () => deleteAppointment(doc.id),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

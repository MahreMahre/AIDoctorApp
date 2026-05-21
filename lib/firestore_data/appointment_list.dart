import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/globals.dart';
import 'package:intl/intl.dart';

class AppointmentList extends StatefulWidget {
  const AppointmentList({Key? key}) : super(key: key);

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String? _documentID;

  Future<void> _getUser() async {
    user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
    }
  }

  Future<void> deleteAppointment(String docID, String doctorId, String patientId) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(doctorId)
          .collection('pending')
          .doc(docID)
          .delete();

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(patientId)
          .collection('pending')
          .doc(docID)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting appointment: $e")),
      );
    }
  }

  String _dateFormatter(String timestamp) {
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(timestamp));
    } catch (_) {
      return "Invalid date";
    }
  }

  String _timeFormatter(String timestamp) {
    try {
      return DateFormat('kk:mm').format(DateTime.parse(timestamp));
    } catch (_) {
      return "Invalid time";
    }
  }

  void showAlertDialog(BuildContext context, String doctorId, String patientId) {
    Widget cancelButton = TextButton(
      child: const Text("No"),
      onPressed: () => Navigator.of(context).pop(),
    );

    Widget continueButton = TextButton(
      child: const Text("Yes"),
      onPressed: () {
        if (_documentID != null) {
          deleteAppointment(_documentID!, doctorId, patientId);
        }
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Confirm Delete"),
      content: const Text("Are you sure you want to delete this Appointment?"),
      actions: [cancelButton, continueButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => alert,
    );
  }

  bool _checkDiff(DateTime date) {
    return DateTime.now().difference(date).inSeconds > 0;
  }

  bool _compareDate(String date) {
    return _dateFormatter(DateTime.now().toString()) == _dateFormatter(date);
  }

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .doc(user!.uid)
            .collection('pending')
            .orderBy('date')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading appointments.',
                // style: GoogleFonts.lato(fontSize: 16, color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No Appointment Scheduled',
                // style: GoogleFonts.lato(color: Colors.grey, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              if (_checkDiff(data['date'].toDate())) {
                deleteAppointment(doc.id, data['doctorId'], data['patientId']);
                return const SizedBox.shrink();
              }

              return Card(
                elevation: 2,
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isDoctor ? data['patientName'] : data['doctorName'],
                        // style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _compareDate(data['date'].toDate().toString()) ? "TODAY" : "",
                        // style: GoogleFonts.lato(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _dateFormatter(data['date'].toDate().toString()),
                    // style: GoogleFonts.lato(),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isDoctor)
                                  Text(
                                    "Patient name: ${data['patientName']}",
                                    // style: GoogleFonts.lato(fontSize: 16),
                                  ),
                                const SizedBox(height: 10),
                                Text(
                                  'Time: ${_timeFormatter(data['date'].toDate().toString())}',
                                  // style: GoogleFonts.lato(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Description : ${data['description'] ?? 'No description'}',
                                  // style: GoogleFonts.lato(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete Appointment',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _documentID = doc.id;
                              showAlertDialog(context, data['doctorId'], data['patientId']);
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
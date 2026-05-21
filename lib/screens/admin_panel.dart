import 'dart:typed_data';
//import 'dart:html' as html; // for Flutter web download

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int totalPatients = 0;
  int totalAppointments = 0;
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> patients = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      final patientsList = usersSnapshot.docs
          .where((doc) => doc['type'] == 'patient')
          .map((doc) => {
        'id': doc.id,
        'name': doc['name'],
        'email': doc['email'],
      })
          .toList();

      final doctorsList = usersSnapshot.docs
          .where((doc) => doc['type'] == 'doctor')
          .map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'rating': (doc.data().toString().contains('rating')
              ? doc['rating']?.toDouble()
              : 0.0),
        };
      })
          .toList();

      final appointmentsSnapshot =
      await _firestore.collection('appointments').get();

      setState(() {
        totalPatients = patientsList.length;
        totalAppointments = appointmentsSnapshot.size;
        doctors = doctorsList;
        patients = patientsList;
      });
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  Future<void> updateDoctorRating(String docId, double newRating) async {
    await _firestore.collection('users').doc(docId).update({
      'rating': newRating,
    });
    fetchStats();
  }

  Future<void> removeDoctor(String docId) async {
    await _firestore.collection('users').doc(docId).delete();
    fetchStats();
  }

/*
  Future<void> generatePdfReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Admin Dashboard Report',
                    style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 20),
                pw.Text('Total Patients: $totalPatients'),
                pw.Text('Total Appointments: $totalAppointments'),
                pw.SizedBox(height: 20),
                pw.Text('Doctors:', style: pw.TextStyle(fontSize: 18)),
                ...doctors.map((doc) => pw.Text(
                    '${doc['name']} - Rating: ${doc['rating'].toStringAsFixed(1)}')),
                pw.SizedBox(height: 20),
                pw.Text('Generated on: ${DateTime.now().toLocal()}'),
              ],
            ),
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();

    // Web download
    if (identical(0, 0.0)) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "admin_report.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Desktop/mobile preview
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    }
  }
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue.shade300,
      ),
      body: RefreshIndicator(
        onRefresh: fetchStats,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Card(
                elevation: 2,
                child: ListTile(
                  title: const Text('Total Patients'),
                  trailing:
                  Text('$totalPatients', style: const TextStyle(fontSize: 15.0)),
                ),
              ),
              Card(
                elevation: 2,
                child: ListTile(
                  title: const Text('Total Appointments'),
                  trailing: Text('$totalAppointments',
                      style: const TextStyle(fontSize: 15.0)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Doctors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...doctors.map((doc) {
                return Card(
                  color: doc['rating'] < 2.5 ? Colors.red[100] : Colors.white,
                  elevation: 3,
                  child: ListTile(
                    title: Text(doc['name']),
                    subtitle:
                    Text('Rating: ${doc['rating'].toStringAsFixed(1)}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.star),
                          tooltip: "Assign Rating",
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  _ratingDialog(doc['id'], doc['rating']),
                            );
                          },
                        ),
                        if (doc['rating'] < 2.5)
                          IconButton(
                            icon:
                            const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Remove Doctor",
                            onPressed: () {
                              removeDoctor(doc['id']);
                            },
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                //  generatePdfReport();
                },
                child: const Text('Download PDF Report'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PatientDetailsScreen(patients: patients),
                    ),
                  );
                },
                child: const Text('View Patient Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ratingDialog(String docId, double currentRating) {
    TextEditingController ratingController =
    TextEditingController(text: currentRating.toString());

    return AlertDialog(
      title: const Text("Assign New Rating"),
      content: TextField(
        controller: ratingController,
        keyboardType:
        const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
            hintText: "Enter rating (0.0 - 5.0)"),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            double? newRating =
            double.tryParse(ratingController.text);
            if (newRating != null &&
                newRating >= 0 &&
                newRating <= 5) {
              updateDoctorRating(docId, newRating);
              Navigator.pop(context);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class PatientDetailsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> patients;

  const PatientDetailsScreen({Key? key, required this.patients})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: Colors.blue.shade300,
      ),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            elevation: 2,
            child: ListTile(
              title: Text(patient['name']),
              subtitle: Text('Email: ${patient['email']}'),
            ),
          );
        },
      ),
    );
  }
}

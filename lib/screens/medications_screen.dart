import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final bool isTakenToday;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.isTakenToday = false,
  });

  factory Medication.fromMap(Map<String, dynamic> data, String id) {
    return Medication(
      id: id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      isTakenToday: data['isTakenToday'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': Timestamp.fromDate(startDate),
      'isTakenToday': isTakenToday,
    };
  }
}

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({Key? key}) : super(key: key);

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String patientId = FirebaseAuth.instance.currentUser!.uid;

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Medications", style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Add New Medication Form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Add New Medication", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Medicine Name")),
                    TextField(controller: _dosageController, decoration: const InputDecoration(labelText: "Dosage (e.g. 500mg)")),
                    TextField(controller: _frequencyController, decoration: const InputDecoration(labelText: "Frequency (e.g. Twice daily)")),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _addMedication,
                      child: const Text("Add Medication"),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Medications List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('patients')
                  .doc(patientId)
                  .collection('medications')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final meds = snapshot.data!.docs.map((doc) {
                  return Medication.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                if (meds.isEmpty) {
                  return const Center(child: Text("No medications added yet"));
                }

                return ListView.builder(
                  itemCount: meds.length,
                  itemBuilder: (context, index) {
                    final med = meds[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.medication, color: Colors.orange, size: 40),
                        title: Text(med.name, style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                        subtitle: Text("${med.dosage} • ${med.frequency}"),
                        trailing: ElevatedButton(
                          onPressed: () => _markAsTaken(med.id),
                          style: ElevatedButton.styleFrom(backgroundColor: med.isTakenToday ? Colors.green : Colors.blue),
                          child: Text(med.isTakenToday ? "Taken" : "Take Now"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMedication() async {
    if (_nameController.text.isEmpty) return;

    final medication = Medication(
      id: '',
      name: _nameController.text,
      dosage: _dosageController.text,
      frequency: _frequencyController.text,
      startDate: DateTime.now(),
    );

    await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('medications')
        .add(medication.toMap());

    _nameController.clear();
    _dosageController.clear();
    _frequencyController.clear();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medication Added")));
  }

  Future<void> _markAsTaken(String medId) async {
    await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('medications')
        .doc(medId)
        .update({'isTakenToday': true});
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_app1/model/vital_record.dart';

import '../../services/firebase_nursing_service.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({Key? key}) : super(key: key);

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final FirebaseNursingService _service = FirebaseNursingService();

  final _hrController = TextEditingController();
  final _tempController = TextEditingController();
  final _bpSysController = TextEditingController();
  final _bpDiaController = TextEditingController();
  final _spo2Controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vitals Monitoring")),
      body: Column(
        children: [
          // Input Form
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(controller: _hrController, decoration: const InputDecoration(labelText: "Heart Rate (bpm)")),
                    TextField(controller: _tempController, decoration: const InputDecoration(labelText: "Temperature (°C)")),
                    TextField(controller: _bpSysController, decoration: const InputDecoration(labelText: "BP Systolic")),
                    TextField(controller: _bpDiaController, decoration: const InputDecoration(labelText: "BP Diastolic")),
                    TextField(controller: _spo2Controller, decoration: const InputDecoration(labelText: "SpO2 (%)")),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveVitals,
                      child: const Text("Save Vitals"),
                    )
                  ],
                ),
              ),
            ),
          ),
          // History
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getVitalHistory(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text("HR: ${data['heartRate']} bpm | Temp: ${data['temperature']}°C"),
                      subtitle: Text(DateTime.fromMillisecondsSinceEpoch(data['timestamp'].seconds * 1000).toString()),
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

  void _saveVitals() async {
    final record = VitalRecord(
      id: '',
      patientId: FirebaseAuth.instance.currentUser!.uid,
      timestamp: DateTime.now(),
      heartRate: double.tryParse(_hrController.text) ?? 0,
      temperature: double.tryParse(_tempController.text) ?? 0,
      bloodPressureSys: double.tryParse(_bpSysController.text) ?? 0,
      bloodPressureDia: double.tryParse(_bpDiaController.text) ?? 0,
      oxygenLevel: double.tryParse(_spo2Controller.text) ?? 0,
    );

    await _service.saveVitalRecord(record);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vitals Saved!")));
    _hrController.clear();
    _tempController.clear();
    _bpSysController.clear();
    _bpDiaController.clear();
    _spo2Controller.clear();
  }
}
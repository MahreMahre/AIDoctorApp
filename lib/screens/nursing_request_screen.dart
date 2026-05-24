import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/model/nursing_request.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_nursing_service.dart';

class NursingRequestScreen extends StatefulWidget {
  const NursingRequestScreen({Key? key}) : super(key: key);

  @override
  State<NursingRequestScreen> createState() => _NursingRequestScreenState();
}

class _NursingRequestScreenState extends State<NursingRequestScreen> {
  final _serviceController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? preferredDate;
  final FirebaseNursingService _service = FirebaseNursingService();

  final List<String> services = [
    "Daily Health Checkup",
    "Wound Dressing",
    "IV Medication",
    "Blood Pressure Monitoring",
    "Injection",
    "Post-Surgery Care",
    "Elderly Care"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Nursing Care")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Service Type", style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18)),
              DropdownButtonFormField<String>(
                items: services.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => _serviceController.text = val ?? '',
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              
              Text("Preferred Date & Time", style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18)),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(preferredDate == null 
                    ? "Select Date" 
                    : DateFormat('dd MMM yyyy, hh:mm a').format(preferredDate!)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() => preferredDate = date);
                  }
                },
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Additional Details",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (preferredDate == null || _serviceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                      return;
                    }

                    final request = NursingRequest(
                      id: '',
                      patientId: FirebaseAuth.instance.currentUser!.uid,
                      nurseId: '', // Will be assigned by admin/nurse
                      requestDate: DateTime.now(),
                      preferredDate: preferredDate!,
                      serviceType: _serviceController.text,
                      description: _descriptionController.text,
                      status: 'pending',
                    );

                    await _service.createNursingRequest(request);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Submitted Successfully!")));
                  },
                  child: const Text("Submit Request", style: TextStyle(fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
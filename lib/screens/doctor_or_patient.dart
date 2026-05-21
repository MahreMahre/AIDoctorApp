import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_app1/globals.dart';
import 'package:health_app1/screens/doctor/main_page_doctor.dart';
import 'package:health_app1/screens/patient/main_page_patient.dart';

class DoctorOrPatient extends StatefulWidget {
  const DoctorOrPatient({Key? key}) : super(key: key);

  @override
  State<DoctorOrPatient> createState() => _DoctorOrPatientState();
}

class _DoctorOrPatientState extends State<DoctorOrPatient> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  void _setUser() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'User is not logged in.';
        });
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snap.exists) {
        setState(() {
          _hasError = true;
          _errorMessage = 'User record not found in the database.';
        });
        return;
      }

      final data = snap.data() as Map<String, dynamic>;

      if (!data.containsKey('type')) {
        setState(() {
          _hasError = true;
          _errorMessage = 'User type is missing.';
        });
        return;
      }

      isDoctor = data['type'] == 'doctor';

      print('isDoctor: $isDoctor');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _setUser();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                      _errorMessage = '';
                    });
                    _setUser();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return isDoctor
        ? const MainPageDoctor()
        : const MainPagePatient();
  }
}

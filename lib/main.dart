import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:health_app1/globals.dart';
import 'package:health_app1/screens/admin_panel.dart';
import 'package:health_app1/screens/doctor/main_page_doctor.dart';
import 'package:health_app1/screens/doctor_or_patient.dart';
import 'package:health_app1/screens/firebase_auth.dart';
import 'package:health_app1/screens/my_profile.dart';
import 'package:health_app1/screens/nursing/home_page.dart';
import 'package:health_app1/screens/patient/appointments.dart';
import 'package:health_app1/screens/patient/doctor_profile.dart';
import 'package:health_app1/screens/patient/main_page_patient.dart';
import 'package:health_app1/screens/skip.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const FireBaseAuth(),
        '/admin': (context) => AdminPanel(),
        '/NursingHome': (context) => const NurseHomePage(),
        '/home': (context) =>
            isDoctor ? const MainPageDoctor() : const MainPagePatient(),
        '/profile': (context) => const MyProfile(),
        '/MyAppointments': (context) => const Appointments(),
        '/DoctorProfile': (context) => DoctorProfile(),
      },
    );
  }
}

/// ✅ Auth logic goes HERE, not in MaterialApp
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Skip();
    } else {
      return const DoctorOrPatient();
    }
  }
}

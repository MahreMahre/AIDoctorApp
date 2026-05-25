import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/screens/sign_in.dart';

class NurseHomePage extends StatefulWidget {
  const NurseHomePage({Key? key}) : super(key: key);

  @override
  State<NurseHomePage> createState() => _NurseHomePageState();
}

class _NurseHomePageState extends State<NurseHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user;
  Map<String, dynamic>? nurseData;

  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadNurseData();
  }

  Future<void> _loadNurseData() async {
    if (user == null) return;

    try {
      DocumentSnapshot doc =
          await _firestore.collection("nurse").doc(user!.uid).get();

      if (!doc.exists) {
        doc =
            await _firestore.collection("users").doc(user!.uid).get();
      }

      setState(() {
        nurseData = doc.data() as Map<String, dynamic>?;
      });
    } catch (e) {
      print("Error loading nurse: $e");
    }
  }

  // ✅ SAVE ONLINE STATUS
  Future<void> _toggleOnline(bool value) async {
    setState(() => isOnline = value);

    await _firestore.collection("nurse").doc(user!.uid).update({
      "isOnline": isOnline,
    });
  }

  // ✅ LOAD REQUESTS
  Stream<QuerySnapshot> _getRequests() {
    return _firestore.collection("nurse_requests").snapshots();
  }

  // ✅ LOAD TASKS
  Stream<QuerySnapshot> _getTasks() {
    return _firestore
        .collection("nurse")
        .doc(user!.uid)
        .collection("tasks")
        .snapshots();
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignIn()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        title: Text(
          "Nurse Dashboard",
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),

      body: nurseData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [

                  const SizedBox(height: 20),

                  // PROFILE
                  _profileCard(),

                  const SizedBox(height: 20),

                  // ONLINE SWITCH
                  _onlineCard(),

                  const SizedBox(height: 20),

                  // QUICK ACTIONS
                  _quickActions(),

                  const SizedBox(height: 20),

                  // REQUESTS FROM PATIENTS
                  _sectionTitle("Patient Requests"),
                  _requestsList(),

                  const SizedBox(height: 20),

                  // TASKS
                  _sectionTitle("My Tasks"),
                  _tasksList(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ---------------- PROFILE ----------------
  Widget _profileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.indigo,
            child: Text(
              nurseData!['name']?[0] ?? "N",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nurseData!['name'] ?? '',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
              Text(nurseData!['email'] ?? ''),
              Text("Dept: ${nurseData!['department'] ?? 'General'}"),
            ],
          )
        ],
      ),
    );
  }

  // ---------------- ONLINE ----------------
  Widget _onlineCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isOnline ? "Online" : "Offline",
            style: GoogleFonts.lato(
              color: isOnline ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          Switch(
            value: isOnline,
            onChanged: _toggleOnline,
          ),
        ],
      ),
    );
  }

  // ---------------- ACTIONS ----------------
  Widget _quickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      children: [

        _action("Patients", Icons.people, () {
          Navigator.pushNamed(context, "/patients");
        }),

        _action("Requests", Icons.notifications, () {
          // already shown below
        }),

        _action("Appointments", Icons.calendar_today, () {
          Navigator.pushNamed(context, "/appointments");
        }),

        _action("Profile", Icons.person, () {
          Navigator.pushNamed(context, "/profile");
        }),
      ],
    );
  }

  Widget _action(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }

  // ---------------- REQUESTS ----------------
  Widget _requestsList() {
    return StreamBuilder(
      stream: _getRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            return ListTile(
              title: Text(doc['patientName'] ?? "Patient"),
              subtitle: Text(doc['message'] ?? ""),
              trailing: ElevatedButton(
                onPressed: () {
                  _firestore.collection("nurse_requests").doc(doc.id).update({
                    "status": "accepted",
                    "nurseId": user!.uid,
                  });
                },
                child: const Text("Accept"),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ---------------- TASKS ----------------
  Widget _tasksList() {
    return StreamBuilder(
      stream: _getTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            return ListTile(
              leading: const Icon(Icons.check_circle),
              title: Text(doc['title'] ?? ""),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
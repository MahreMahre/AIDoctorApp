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

    DocumentSnapshot doc =
        await _firestore.collection("nurse").doc(user!.uid).get();

    setState(() {
      nurseData = doc.data() as Map<String, dynamic>?;
    });
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

      // APP BAR
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

                  // PROFILE CARD
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Row(
                      children: [

                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.indigo,
                          child: Text(
                            nurseData!['name'][0],
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nurseData!['name'],
                                style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                nurseData!['email'] ?? '',
                                style: GoogleFonts.lato(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Department: ${nurseData!['department'] ?? 'N/A'}",
                                style: GoogleFonts.lato(
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ONLINE / OFFLINE TOGGLE
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isOnline ? "Online" : "Offline",
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                        Switch(
                          value: isOnline,
                          onChanged: (val) {
                            setState(() {
                              isOnline = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // QUICK ACTIONS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Quick Actions",
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      children: [

                        _actionCard("Patients", Icons.people, Colors.blue),
                        _actionCard("Requests", Icons.notifications, Colors.orange),
                        _actionCard("Appointments", Icons.calendar_today, Colors.green),
                        _actionCard("Tasks", Icons.task, Colors.purple),

                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TODAY TASKS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Today's Tasks",
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _taskItem("Check patient vitals"),
                  _taskItem("Administer medication"),
                  _taskItem("Update patient records"),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskItem(String task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.indigo),
          const SizedBox(width: 10),
          Text(task, style: GoogleFonts.lato()),
        ],
      ),
    );
  }
}
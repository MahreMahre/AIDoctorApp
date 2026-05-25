import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:health_app1/carousel_slider.dart';
import 'package:health_app1/firestore_data/notification_list.dart';
import 'package:health_app1/firestore_data/search_list.dart';
import 'package:health_app1/firestore_data/top_rated_list.dart';
import 'package:health_app1/model/card_model.dart';
import 'package:health_app1/screens/explore_list.dart';
import 'package:health_app1/screens/nursing/nurse_list_screen.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController _doctorName = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  String message = "Good";

  @override
  void initState() {
    super.initState();
    _doctorName = TextEditingController();
    _getUser();
    _setGreeting();
  }

  void _setGreeting() {
    DateTime now = DateTime.now();
    int hour = int.parse(DateFormat('kk').format(now));

    if (hour >= 5 && hour < 12) {
      message = 'Good Morning';
    } else if (hour <= 17) {
      message = 'Good Afternoon';
    } else {
      message = 'Good Evening';
    }
  }

  Future<void> _getUser() async {
    user = _auth.currentUser;
    setState(() {});
  }

  @override
  void dispose() {
    _doctorName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              message,
              style: GoogleFonts.lato(
                color: Colors.black54,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.notifications_active),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                "Hello ${user?.displayName ?? 'User'}",
                style: GoogleFonts.lato(fontSize: 18),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                "Find Doctors & Nurses\nNear You",
                style: GoogleFonts.lato(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextFormField(
                controller: _doctorName,
                decoration: InputDecoration(
                  hintText: "Search doctor or nurse",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {},
                  ),
                ),
                onFieldSubmitted: (value) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SearchList(searchKey: value),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            sectionTitle("We care for you"),
            const Carouselslider(),

            const SizedBox(height: 20),

            // ================= NURSING SECTION =================
            sectionTitle("Nursing Services"),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [

                  _nurseCard(
                    "Find Nurses",
                    "Professional nurses available near you",
                    Icons.health_and_safety,
                    Colors.green,
                    () {
                      // 🔥 REAL NURSE LIST SCREEN
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NurseListScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  _nurseCard(
                    "Home Care Service",
                    "24/7 nursing assistance at home",
                    Icons.health_and_safety,
                    Colors.blue,
                    () {},
                  ),

                  const SizedBox(height: 10),

                  _nurseCard(
                    "Emergency Nurse",
                    "Instant nurse support in emergency",
                    Icons.emergency,
                    Colors.red,
                    () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            sectionTitle("Specialists"),
            buildSpecialistList(),

            const SizedBox(height: 20),

            sectionTitle("Top Rated"),
            const SizedBox(height: 10),

            const TopRatedList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _nurseCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget buildSpecialistList() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];

          return Container(
            width: 140,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: card.backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ExploreList(type: card.title),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      card.icon,
                      color: card.backgroundColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    card.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
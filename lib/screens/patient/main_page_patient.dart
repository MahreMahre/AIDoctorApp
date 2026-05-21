import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:health_app1/screens/chat/chats.dart';
import 'package:health_app1/screens/my_profile.dart';
import 'package:health_app1/screens/patient/doctor_list.dart';
import 'package:health_app1/screens/patient/home_page.dart';
import 'package:health_app1/screens/patient/appointments.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:tabler_icons/icon_data.dart';
import 'package:typicons_flutter/typicons_flutter.dart';

import '../../chatbot_screen.dart';

class MainPagePatient extends StatefulWidget {
  const MainPagePatient({Key? key}) : super(key: key);

  @override
  State<MainPagePatient> createState() => _MainPagePatientState();
}

class _MainPagePatientState extends State<MainPagePatient>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool isAdmin = false;

  late AnimationController _fabController;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotationAnim;

  final List<Widget> _pages = [
    const HomePage(),
    const DoctorsList(),
    const Appointments(),
    const Chats(),
    const MyProfile(),
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  Future<void> _getUser() async {
    user = _auth.currentUser;
  }

  Future<void> _checkIfAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final admin = prefs.getBool('ISADMINKEY') ?? false;
    debugPrint("Is Admin? $admin");
    setState(() {
      isAdmin = admin;
    });
  }

  @override
  void initState() {
    super.initState();
    _getUser();
    _checkIfAdmin();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));

    _rotationAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _fabController, curve: Curves.elasticInOut));

    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: isAdmin
            ? AppBar(
          title: const Text("SmartCare"),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: "Admin Panel",
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
            )
          ],
        )
            : null,

        /// ✅ FAB with bounce + wiggle effect
        floatingActionButton: ScaleTransition(
          scale: _scaleAnim,
          child: RotationTransition(
            turns: _rotationAnim,
            child: FloatingActionButton(
              backgroundColor: Colors.blue.shade100,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
              child: const Icon(Icons.mark_unread_chat_alt_sharp),
              tooltip: "Ask SmartCare AI",
            ),
          ),
        ),

        backgroundColor: Colors.transparent,
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(.2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
              child: GNav(
                curve: Curves.easeOutExpo,
                rippleColor: Colors.grey.shade300,
                hoverColor: Colors.grey.shade100,
                haptic: true,
                tabBorderRadius: 20,
                gap: 5,
                activeColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                duration: const Duration(milliseconds: 200),
                tabBackgroundColor: Colors.blue.withOpacity(0.7),
                // textStyle: GoogleFonts.lato(
                //   color: Colors.white,
                // ),
                tabs: const [
                  GButton(iconSize: 28, icon: Icons.home),
                  GButton(icon: Icons.search),
                  GButton(iconSize: 28, icon: Typicons.calendar),
                  GButton(iconSize: 28, icon: Icons.chat),
                  GButton(iconSize: 28, icon: Typicons.user),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: _onItemTapped,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:health_app1/screens/chat/chats.dart';
import 'package:health_app1/screens/my_profile.dart';
import 'package:health_app1/screens/patient/appointments.dart';
import 'package:typicons_flutter/typicons_flutter.dart';

class MainPageDoctor extends StatefulWidget {
  const MainPageDoctor({Key? key}) : super(key: key);

  @override
  State<MainPageDoctor> createState() => _MainPageDoctorState();
}

class _MainPageDoctorState extends State<MainPageDoctor> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    const Chats(),
    const Appointments(),
    const MyProfile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // ✨ Premium Scaffold Background
      backgroundColor: const Color(0xFFF0F4FA), // Soft elegant blue tint

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Doctor Dashboard",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E40AF),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.notifications_outlined, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),

      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 25,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: GNav(
              curve: Curves.easeOutExpo,
              rippleColor: Colors.blue.shade100,
              hoverColor: Colors.blue.shade50,
              haptic: true,
              tabBorderRadius: 25,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 26,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: const Color(0xFF1E40AF),
          
              textStyle: GoogleFonts.poppins(

                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                GButton(icon: Icons.chat_bubble_outline_rounded, text: 'Chats'),
                GButton(icon: Typicons.calendar, text: 'Appointments'),
                GButton(icon: Typicons.user, text: 'Profile'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
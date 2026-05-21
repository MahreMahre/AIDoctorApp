import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/carousel_slider.dart';
import 'package:health_app1/firestore_data/notification_list.dart';
import 'package:health_app1/firestore_data/search_list.dart';
import 'package:health_app1/firestore_data/top_rated_list.dart';
import 'package:health_app1/model/card_model.dart';
import 'package:health_app1/screens/explore_list.dart';
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
    } else if (hour >= 12 && hour <= 17) {
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
        actions: <Widget>[Container()],
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                alignment: Alignment.center,
                child: Text(
                  message,
                  // style: GoogleFonts.lato(
                  //   color: Colors.black54,
                  //   fontSize: 20,
                  //   fontWeight: FontWeight.w400,
                  // ),
                ),
              ),
              const SizedBox(width: 55),
              IconButton(
                splashRadius: 20,
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
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overscroll) {
            overscroll.disallowIndicator();
            return true;
          },
          child: ListView(
            physics: const ClampingScrollPhysics(),
            shrinkWrap: true,
            children: [
              Column(
                children: [
                  const SizedBox(height: 30),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20, bottom: 10),
                    child: Text(
                      "Hello ${user?.displayName ?? 'User'}",
                      // style: GoogleFonts.lato(
                      //   fontSize: 18,
                      //   fontWeight: FontWeight.w500,
                      // ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20, bottom: 25),
                    child: Text(
                      "Let's Find Your\nDoctor",
                      // style: GoogleFonts.lato(
                      //   fontSize: 35,
                      //   fontWeight: FontWeight.bold,
                      // ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                    child: TextFormField(
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.search,
                      controller: _doctorName,
                      decoration: InputDecoration(
                        contentPadding:
                        const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15.0)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        hintText: 'Search doctor',
                        // hintStyle: GoogleFonts.lato(
                        //   color: Colors.black26,
                        //   fontSize: 18,
                        //   fontWeight: FontWeight.w800,
                        // ),
                        suffixIcon: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade900.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            iconSize: 20,
                            splashRadius: 20,
                            color: Colors.white,
                            icon: const Icon(Icons.search),
                            onPressed: () {},
                          ),
                        ),
                      ),
                      // style: GoogleFonts.lato(
                      //   fontSize: 18,
                      //   fontWeight: FontWeight.w800,
                      // ),
                      onFieldSubmitted: (String value) {
                        if (value.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchList(searchKey: value),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  sectionTitle("We care for you"),
                  const Carouselslider(),
                  sectionTitle("Specialists"),
                  buildSpecialistList(),
                  const SizedBox(height: 30),
                  sectionTitle("Top Rated"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: const TopRatedList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),


    );
  }

  Widget sectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        textAlign: TextAlign.center,
        // style: GoogleFonts.lato(
        //   color: Colors.blue[800],
        //   fontWeight: FontWeight.bold,
        //   fontSize: 18,
        // ),
      ),
    );
  }

// Updated buildSpecialistList() to work with the new CardModel
  Widget buildSpecialistList() {
    return Container(
      height: 150,
      padding: const EdgeInsets.only(top: 14),
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Container(
            margin: const EdgeInsets.only(right: 14),
            height: 150,
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: card.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  blurRadius: 4.0,
                  spreadRadius: 0.0,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExploreList(type: card.title),
                  ),
                );
              },
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 29,
                    child: Icon(
                      card.icon,
                      size: 26,
                      color: card.backgroundColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    card.title,
                    // style: GoogleFonts.lato(
                    //   color: Colors.white,
                    //   fontSize: 16,
                    //   fontWeight: FontWeight.w600,
                    // ),
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

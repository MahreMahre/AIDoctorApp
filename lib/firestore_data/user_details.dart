import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/globals.dart';
import 'package:health_app1/model/update_user_details.dart';

class UserDetails extends StatefulWidget {
  const UserDetails({Key? key}) : super(key: key);

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  Map<String, dynamic> details = {};
  bool _isLoading = true;
  String? errorMessage;

  Future<void> _getUser() async {
    try {
      user = _auth.currentUser;

      if (user == null) {
        setState(() {
          errorMessage = 'User not signed in.';
          _isLoading = false;
        });
        return;
      }

      DocumentSnapshot snap = await FirebaseFirestore.instance
          .collection(isDoctor ? 'doctor' : 'patient')
          .doc(user!.uid)
          .get();

      if (!snap.exists) {
        setState(() {
          errorMessage = 'User data not found.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        details = snap.data() as Map<String, dynamic>;
        _isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching user data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          // style: GoogleFonts.lato(color: Colors.red),
        ),
      );
    }

    final excludedKeys = ['profilePhoto', 'uid', 'emailVerified'];

    final validKeys = details.keys
        .where((key) => !excludedKeys.contains(key))
        .toList();

    if (validKeys.isEmpty) {
      return Center(
        child: Text(
          'No user details available.',
          // style: GoogleFonts.lato(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ListView.builder(
        controller: ScrollController(),
        shrinkWrap: true,
        itemCount: validKeys.length,
        itemBuilder: (context, index) {
          String key = validKeys[index];
          dynamic rawValue = details[key];
          String value = (rawValue == null || rawValue.toString().trim().isEmpty)
              ? 'Not Added'
              : rawValue.toString().trim();
          String label = key[0].toUpperCase() + key.substring(1);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: InkWell(
              splashColor: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateUserDetails(
                      label: label,
                      field: key,
                      value: value,
                    ),
                  ),
                ).then((_) => _getUser());
              },
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  height: MediaQuery.of(context).size.height / 14,
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        // style: GoogleFonts.lato(
                        //   color: Colors.black,
                        //   fontSize: 16,
                        //   fontWeight: FontWeight.bold,
                        // ),
                      ),
                      Tooltip(
                        message: value,
                        child: Text(
                          value.length > 20
                              ? '${value.substring(0, 20)}...'
                              : value,
                          // style: GoogleFonts.lato(
                          //   color: Colors.black54,
                          //   fontSize: 15,
                          //   fontWeight: FontWeight.bold,
                          // ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

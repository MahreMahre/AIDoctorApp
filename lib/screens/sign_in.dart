import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:health_app1/globals.dart';
import 'package:health_app1/helperFunction/sharedpref_helper.dart';
import 'package:health_app1/screens/register.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final String adminEmail = 'hassanali123@gmail.com';

  bool _isLoading = false;
  bool _obscure = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  FocusNode f1 = FocusNode();
  FocusNode f2 = FocusNode();
  FocusNode f3 = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Text(
                    "Login",
                    style: GoogleFonts.lato(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // EMAIL
                  TextFormField(
                    controller: _emailController,
                    focusNode: f1,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Email",
                      filled: true,
                      fillColor: Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Enter email" : null,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(f2),
                  ),

                  const SizedBox(height: 20),

                  // PASSWORD
                  TextFormField(
                    controller: _passwordController,
                    focusNode: f2,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: "Password",
                      filled: true,
                      fillColor: Colors.grey[300],
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) =>
                        value!.length < 6 ? "Min 6 characters" : null,
                  ),

                  const SizedBox(height: 30),

                  // LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      focusNode: f3,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          showLoaderDialog(context);
                          _signInWithEmailAndPassword();
                        }
                      },
                      child: const Text(
                        "Sign In",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Register(),
                        ),
                      );
                    },
                    child: const Text("Create new account"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- LOADER ----------------
  void showLoaderDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 15),
              Text("Logging in..."),
            ],
          ),
        );
      },
    );
  }

  // ---------------- LOGIN LOGIC ----------------
  void _signInWithEmailAndPassword() async {
    try {
      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = credential.user;

      if (user == null) return;

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      // ADMIN CHECK
      if (user.email == adminEmail) {
        Navigator.pop(context);
        await SharedPreferenceHelper().saveIsAdmin(true);
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/admin', (route) => false);
        return;
      }

      await SharedPreferenceHelper().saveIsAdmin(false);

      // FIRESTORE USER FETCH
      DocumentSnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snap.exists) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User data not found")),
        );
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      String type = data['type'] ?? 'patient';
      String name = data['name'] ?? '';

      // SAVE LOCAL
      await SharedPreferenceHelper().saveUserId(user.uid);
      await SharedPreferenceHelper().saveUserName(name);
      await SharedPreferenceHelper().saveAccountType(type == 'doctor');

      Navigator.pop(context); // close loader

      // ---------------- ROLE ROUTING ----------------
      if (type == 'doctor') {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } 
      else if (type == 'nurse') {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/NursingHome', (route) => false);
      } 
      else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }

    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Error: $e")),
      );
    }
  }
}
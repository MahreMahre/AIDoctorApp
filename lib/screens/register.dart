import 'dart:math';
import 'package:health_app1/globals.dart' as globals;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/screens/sign_in.dart';

// ... [imports same as before] ...

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
  TextEditingController();

  int type = -1;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  FocusNode f1 = FocusNode();
  FocusNode f2 = FocusNode();
  FocusNode f3 = FocusNode();
  FocusNode f4 = FocusNode();

  @override
  void dispose() {
    _displayName.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (OverscrollIndicatorNotification overscroll) {
              overscroll.disallowIndicator();
              return true;
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
                child: _signUp(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signUp() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Sign up',
              // style: GoogleFonts.lato(
              //   fontSize: 30,
              //   fontWeight: FontWeight.bold,
              // ),
            ),
            const SizedBox(height: 50),

            // Name field
            TextFormField(
              focusNode: f1,
              controller: _displayName,
              textInputAction: TextInputAction.next,
              // style: GoogleFonts.lato(
              //   fontSize: 18,
              //   fontWeight: FontWeight.w800,
              // ),
              decoration: _inputDecoration('Name'),
              onFieldSubmitted: (_) {
                f1.unfocus();
                FocusScope.of(context).requestFocus(f2);
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the Name';
                } else if (!RegExp(
                  r'^[A-Z][a-z]*(\s[A-Z][a-z]*)*$',
                ).hasMatch(value.trim())) {
                  return 'Name must start with capital letter (e.g., John Doe)';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),

            // Email
            TextFormField(
              focusNode: f2,
              controller: _emailController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              // style: GoogleFonts.lato(
              //   fontSize: 18,
              //   fontWeight: FontWeight.w800,
              // ),
              decoration: _inputDecoration('Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the Email';
                } else if (!emailValidate(value)) {
                  return 'Please enter correct Email';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                f2.unfocus();
                FocusScope.of(context).requestFocus(f3);
              },
            ),
            const SizedBox(height: 25),

            // Password
            TextFormField(
              focusNode: f3,
              controller: _passwordController,
              obscureText: !_passwordVisible,
              textInputAction: TextInputAction.next,
              // style: GoogleFonts.lato(
              //   fontSize: 18,
              //   fontWeight: FontWeight.w800,
              // ),
              decoration: _inputDecoration('Password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the Password';
                } else if (value.length < 8) {
                  return 'Password must be at least 8 characters long';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                f3.unfocus();
                FocusScope.of(context).requestFocus(f4);
              },
            ),
            const SizedBox(height: 25),

            // Confirm Password
            TextFormField(
              focusNode: f4,
              controller: _passwordConfirmController,
              obscureText: !_confirmPasswordVisible,
              textInputAction: TextInputAction.done,
              // style: GoogleFonts.lato(
              //   fontSize: 18,
              //   fontWeight: FontWeight.w800,
              // ),
              decoration: _inputDecoration('Confirm Password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _confirmPasswordVisible = !_confirmPasswordVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                } else if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              onFieldSubmitted: (_) => f4.unfocus(),
            ),
            const SizedBox(height: 25),

            // Account type buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _accountTypeButton('Doctor', 0),
                const Text('or'),
                _accountTypeButton('Patient', 1),
              ],
            ),
            const SizedBox(height: 25),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && type != -1) {
                    showLoaderDialog(context);
                    _registerAccount();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
                child: Text(
                  "Sign Up", // ✅ changed here
                  // style: GoogleFonts.lato(
                  //   color: Colors.white,
                  //   fontSize: 18.0,
                  //   fontWeight: FontWeight.bold,
                  // ),
                ),
              ),
            ),

            const SizedBox(height: 25),
            const Divider(thickness: 1.5),
            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account?",
                  // style: GoogleFonts.lato(
                  //   fontSize: 15.0,
                  //   fontWeight: FontWeight.w700,
                  // ),
                ),
                TextButton(
                  onPressed: () => _pushPage(context, const SignIn()),
                  child: Text(
                    'Sign in',
                    // style: GoogleFonts.lato(
                    //   fontSize: 15,
                    //   color: Colors.indigo[700],
                    //   fontWeight: FontWeight.w600,
                    // ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(90.0)),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[350],
      hintText: hintText,
      // hintStyle: GoogleFonts.lato(
      //   color: Colors.black26,
      //   fontSize: 18,
      //   fontWeight: FontWeight.w800,
      // ),
    );
  }

  Widget _accountTypeButton(String label, int selectedType) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2.5,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            type = selectedType;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[350],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0),
          ),
          side: BorderSide(
            width: 5.0,
            color: Colors.black38,
            style: type == selectedType ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Text(
          label,
          // style: GoogleFonts.lato(
          //   color: type == selectedType ? Colors.black38 : Colors.white,
          //   fontSize: 18.0,
          //   fontWeight: FontWeight.bold,
          // ),
        ),
      ),
    );
  }

  void showAlertDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Error!",
            // style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          content: Text("Email already Exists",),
          actions: [
            TextButton(
              child: Text(
                "OK",
                // style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(context);
                FocusScope.of(context).requestFocus(f2);
              },
            ),
          ],
        );
      },
    );
  }

  void showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 15),
          const Text("Loading..."),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => alert,
    );
  }

  bool emailValidate(String email) {
    return RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$",
    ).hasMatch(email);
  }

  void _registerAccount() async {
    User? user;
    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (error) {
      if (error.toString().contains('email-already-in-use')) {
        showAlertDialog(context);
      }
      print(error.toString());
    }

    user = credential?.user;

    if (user != null) {
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
      await user.updateDisplayName(_displayName.text);

      String name = (type == 0)
          ? 'Dr. ${_displayName.text}'
          : _displayName.text;
      String accountType = (type == 0) ? 'doctor' : 'patient';

      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'type': accountType,
        'email': user.email,
      }, SetOptions(merge: true));

      Map<String, dynamic> mp = {
        'id': user.uid,
        'type': accountType,
        'name': name,
        'birthDate': null,
        'email': user.email,
        'phone': null,
        'bio': null,
        'address': null,
        'profilePhoto': null,
      };

      if (type == 0) {
        mp.addAll({
          'openHour': "09:00",
          'closeHour': "21:00",
          'rating': double.parse(
            (3 + Random().nextDouble() * 1.9).toStringAsPrecision(2),
          ),
          'specification': null,
          'specialization': 'general',
        });
        globals.isDoctor = true;
      }

      FirebaseFirestore.instance.collection(accountType).doc(user.uid).set(mp);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    }
  }

  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
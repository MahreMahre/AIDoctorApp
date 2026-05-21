import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';

import 'register.dart';
import 'sign_in.dart';

class FireBaseAuth extends StatefulWidget {
  const FireBaseAuth({Key? key}) : super(key: key);

  @override
  State<FireBaseAuth> createState() => _FireBaseAuthState();
}

class _FireBaseAuthState extends State<FireBaseAuth> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              constraints: const BoxConstraints.expand(),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/image-medical.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HELLO',
                            // style: GoogleFonts.b612(
                            //   color: Colors.black,
                            //   fontSize: 50,
                            //   fontWeight: FontWeight.w700,
                            // ),
                          ),
                          Text(
                            'Welcome to SmartCare!',
                            // style: GoogleFonts.b612(
                            //   color: Colors.indigo[800],
                            //   fontSize: 17,
                            //   fontWeight: FontWeight.w400,
                            // ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 300),
                  Container(
                    height: 220,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black26.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _pushPage(context, const SignIn()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                              ),
                              child: Text(
                                "Sign in",
                                // style: GoogleFonts.lato(
                                //   color: Colors.white,
                                //   fontSize: 18.0,
                                //   fontWeight: FontWeight.bold,
                                // ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _pushPage(context, const Register()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                              ),
                              child: Text(
                                "Create an Account",
                                // style: GoogleFonts.lato(
                                //   color: Colors.black,
                                //   fontSize: 18.0,
                                //   fontWeight: FontWeight.bold,
                                // ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

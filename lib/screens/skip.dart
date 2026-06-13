import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';

import 'firebase_auth.dart';

class Skip extends StatefulWidget {
  const Skip({Key? key}) : super(key: key);

  @override
  State<Skip> createState() => _SkipState();
}

class _SkipState extends State<Skip> {
  List<PageViewModel> getpages() {
    return [
      PageViewModel(
        title: '',
        image: _buildImageWithGradient('assets/images/doc.png'),
        bodyWidget: _buildBodyWidget(
          title: 'Search Doctors',
          subtitle: 'Find popular doctors nearby you',
          icon: Icons.search,
        ),
        decoration: const PageDecoration(
          pageColor: Colors.transparent,
          bodyPadding: EdgeInsets.all(20),
          titlePadding: EdgeInsets.zero,
          contentMargin: EdgeInsets.zero,
        ),
      ),
      PageViewModel(
        title: '',
        image: _buildImageWithGradient('assets/images/disease.png'),
        bodyWidget: _buildBodyWidget(
          title: 'Search Disease',
          subtitle: 'Find information about diseases and treatments',
          icon: Icons.health_and_safety,
        ),
        decoration: const PageDecoration(
          pageColor: Colors.transparent,
          bodyPadding: EdgeInsets.all(20),
          titlePadding: EdgeInsets.zero,
          contentMargin: EdgeInsets.zero,
        ),
      ),
      PageViewModel(
        title: '',
        image: _buildImageWithGradient('assets/images/appointment.jpg', 
            defaultAsset: 'assets/images/doc.png'),
        bodyWidget: _buildBodyWidget(
          title: 'Book Appointments',
          subtitle: 'Easy and quick appointment booking with top doctors',
          icon: Icons.calendar_today,
        ),
        decoration: const PageDecoration(
          pageColor: Colors.transparent,
          bodyPadding: EdgeInsets.all(20),
          titlePadding: EdgeInsets.zero,
          contentMargin: EdgeInsets.zero,
        ),
      ),
      PageViewModel(
        title: '',
        image: _buildImageWithGradient('assets/images/chat.png',
            defaultAsset: 'assets/images/doc.png'),
        bodyWidget: _buildBodyWidget(
          title: 'Chat with Doctors',
          subtitle: 'Get instant consultation through chat',
          icon: Icons.chat_bubble_outline,
        ),
        decoration: const PageDecoration(
          pageColor: Colors.transparent,
          bodyPadding: EdgeInsets.all(20),
          titlePadding: EdgeInsets.zero,
          contentMargin: EdgeInsets.zero,
        ),
      ),
    ];
  }

  Widget _buildImageWithGradient(String assetPath, {String? defaultAsset}) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 250,
      width: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E).withOpacity(0.1),
            const Color(0xFF0D47A1).withOpacity(0.05),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          height: 250,
          width: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 250,
              width: 250,
              color: Colors.indigo.shade50,
              child: Icon(
                Icons.medical_services,
                size: 100,
                color: Colors.indigo.shade300,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBodyWidget({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A237E).withOpacity(0.1),
                const Color(0xFF0D47A1).withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 60,
            color: const Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.indigo.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: IntroductionScreen(
            globalBackgroundColor: Colors.transparent,
            pages: getpages(),
            showNextButton: true,
            showSkipButton: true,
            showDoneButton: true,
            next: _buildNextButton(),
            skip: _buildSkipButton(),
            done: _buildDoneButton(),
            onDone: () => _pushPage(context, const FireBaseAuth()),
            onSkip: () => _pushPage(context, const FireBaseAuth()),
            dotsDecorator: DotsDecorator(
              size: const Size.square(8),
              activeSize: const Size(20, 8),
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: Colors.grey.shade300,
              activeColor: const Color(0xFF1A237E),
              spacing: const EdgeInsets.symmetric(horizontal: 6),
            ),
            curve: Curves.easeInOut,
            // animationDuration: const Duration(milliseconds: 500),
            controlsMargin: const EdgeInsets.all(16),
            controlsPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade400, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Skip',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Next',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Get Started',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}
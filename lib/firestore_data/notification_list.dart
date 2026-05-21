import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({Key? key}) : super(key: key);

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  bool _hasError = false;
  bool _isLoading = false;

  // Simulate notification fetch (placeholder for future Firebase logic)
  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      await Future.delayed(const Duration(seconds: 1)); // Simulate load

      // Future logic: Firebase notification pull here

    } catch (e) {
      setState(() {
        _hasError = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load notifications: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          splashRadius: 20,
          icon: const Icon(Icons.arrow_back_ios, color: Colors.indigo),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          // style: GoogleFonts.lato(
          //   color: Colors.indigo,
          //   fontSize: 18,
          //   fontWeight: FontWeight.bold,
          // ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
            ? Center(
          child: Text(
            'An error occurred while loading notifications.',
            // style: GoogleFonts.lato(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        )
            : Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Our team is currently working on live push notifications.',
              // style: GoogleFonts.lato(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

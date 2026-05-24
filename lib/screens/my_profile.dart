import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/firestore_data/appointment_history_list.dart';
import 'package:health_app1/globals.dart';
import 'package:image_picker/image_picker.dart';
import 'setting.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({Key? key}) : super(key: key);

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  User? user;
  String? email, name, phone, bio, specialization;
  String image =
      'https://cdn.icon-icons.com/icons2/1378/PNG/512/avatardefault_92824.png';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection(isDoctor ? 'doctor' : 'patient')
          .doc(user!.uid)
          .get();

      if (!snap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found')),
        );
        return;
      }

      final data = snap.data()!;
      setState(() {
        email = data['email'] ?? 'Not Added';
        name = data['name'] ?? 'Name Not Added';
        phone = data['phone'] ?? 'Not Added';
        bio = data['bio'] ?? 'Not Added';
        specialization = data['specialization'];
        image = data['profilePhoto'] ?? image;
      });
    } catch (e) {
      print('Load error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading user data')),
      );
    }
  }

  Future<void> selectOrTakePhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();

      XFile? pickedFile = await picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : source,
        imageQuality: 12,
      );

      if (pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
        return;
      }

      final imageBytes = await pickedFile.readAsBytes();
      await uploadFile(imageBytes, pickedFile.name);
    } catch (e) {
      print('Image picking error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking image')),
      );
    }
  }

  Future<void> uploadFile(Uint8List img, String fileName) async {
    if (user == null) return;

    final path = 'dp/${user!.displayName ?? user!.uid}-$fileName';
    try {
      final ref = storage.ref(path);
      final snapshot = await ref.putData(img);
      final url = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection(isDoctor ? 'doctor' : 'patient')
          .doc(user!.uid)
          .set({'profilePhoto': url}, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'profilePhoto': url}, SetOptions(merge: true));

      setState(() {
        image = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated')),
      );
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading profile photo')),
      );
    }
  }

  Future<void> _showSelectionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Select photo'),
        children: [
          SimpleDialogOption(
            child: const Text('From gallery'),
            onPressed: () {
              Navigator.pop(context);
              selectOrTakePhoto(ImageSource.gallery);
            },
          ),
          SimpleDialogOption(
            child: const Text('Take a photo'),
            onPressed: () {
              Navigator.pop(context);
              selectOrTakePhoto(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: user == null
            ? const Center(child: CircularProgressIndicator())
            : NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overscroll) {
            overscroll.disallowIndicator();
            return true;
          },
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: [
              _buildHeader(context),
              _buildInfoCard(),
              _buildBioCard(),
              _buildAppointmentHistoryCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.1, 0.5],
                  colors: [Colors.indigo, Colors.indigoAccent],
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserSettings()),
                    ).then((_) => _loadUserProfile());
                  },
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              height: MediaQuery.of(context).size.height / 6,
              padding: const EdgeInsets.only(top: 75),
              child: Text(
                name ?? 'Name Not Added',
                style: GoogleFonts.lato(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
            Text(specialization?.isNotEmpty == true ? '($specialization)' : ''),
          ],
        ),
        InkWell(
          onTap: () => _showSelectionDialog(context),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal.shade50, width: 5),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(image),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return _infoCard([
      _infoRow(Icons.mail, Colors.red[900], email ?? 'Email Not Added'),
      const SizedBox(height: 15),
      _infoRow(Icons.phone, Colors.blue[800], phone ?? 'Not Added'),
    ]);
  }

  Widget _buildBioCard() {
    return _infoCard([
      _infoRow(Icons.edit, Colors.indigo[600], 'Bio', isTitle: true),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.only(left: 40),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            bio ?? 'Not Added',
            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black38),
          ),
        ),
      ),
    ], topMargin: 20);
  }

  Widget _buildAppointmentHistoryCard() {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, top: 20),
      padding: const EdgeInsets.only(left: 20, top: 20),
      height: MediaQuery.of(context).size.height / 2,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blueGrey[50],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _circleIcon(Icons.history, Colors.green[900]),
              const SizedBox(width: 10),
              const Text("Appointment History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AppointmentHistoryList()));
                    },
                    child: const Text('View all'),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          const Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: Padding(
                padding: EdgeInsets.only(right: 15),
                child: AppointmentHistoryList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children, {double topMargin = 0}) {
    return Container(
      margin: EdgeInsets.only(left: 15, right: 15, top: topMargin),
      padding: const EdgeInsets.only(left: 20),
      height: MediaQuery.of(context).size.height / 7,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blueGrey[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _infoRow(IconData icon, Color? color, String text, {bool isTitle = false}) {
    return Row(
      children: [
        _circleIcon(icon, color),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: isTitle ? FontWeight.bold : FontWeight.w600,
            color: isTitle ? Colors.black : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _circleIcon(IconData icon, Color? bgColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 27,
        width: 27,
        color: bgColor ?? Colors.grey,
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:health_app1/globals.dart';

class UpdateUserDetails extends StatefulWidget {
  final String label;
  final String field;
  final String value;

  const UpdateUserDetails({
    Key? key,
    required this.label,
    required this.field,
    required this.value,
  }) : super(key: key);

  @override
  State<UpdateUserDetails> createState() => _UpdateUserDetailsState();
}

class _UpdateUserDetailsState extends State<UpdateUserDetails> {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _textController.text = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.indigo),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.label,
          // style: GoogleFonts.lato(
          //   color: Colors.indigo,
          //   fontSize: 21,
          //   fontWeight: FontWeight.bold,
          // ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(5, 20, 5, 0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: TextFormField(
                  controller: _textController,
                  // style: GoogleFonts.lato(
                  //   fontSize: 20,
                  //   fontWeight: FontWeight.bold,
                  // ),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter ${widget.label.toLowerCase()}';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.withOpacity(0.9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      elevation: 2,
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      'Update',
                      // style: GoogleFonts.lato(
                      //   fontSize: 18,
                      //   fontWeight: FontWeight.bold,
                      // ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);
    final newValue = _textController.text.trim();

    try {
      await FirebaseFirestore.instance
          .collection(isDoctor ? 'doctor' : 'patient')
          .doc(user!.uid)
          .set({widget.field: newValue}, SetOptions(merge: true));

      if (widget.field == 'name') {
        await user!.updateDisplayName(newValue);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Information updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}

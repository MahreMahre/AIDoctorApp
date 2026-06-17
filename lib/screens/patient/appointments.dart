import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/globals.dart';
import 'package:intl/intl.dart';

class Appointments extends StatefulWidget {
  const Appointments({Key? key}) : super(key: key);

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: const Color(0xFF1E40AF),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDoctor ? 'Appointment Requests' : 'My Appointments',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E40AF),
              ),
            ),
            Text(
              isDoctor ? 'Manage patient requests' : 'Manage your appointments',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        padding: const EdgeInsets.only(right: 16, left: 16, top: 16),
        child: const AppointmentList(),
      ),
    );
  }
}

// Updated AppointmentList with Doctor Request Management
class AppointmentList extends StatefulWidget {
  const AppointmentList({Key? key}) : super(key: key);

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String? _documentID;
  bool _isUploading = false;

  final TextEditingController _easypaisaController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Future<void> _getUser() async {
    user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
    }
  }

  Future<void> deleteAppointment(String docID, String doctorId, String patientId) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(doctorId)
          .collection('pending')
          .doc(docID)
          .delete();

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(patientId)
          .collection('pending')
          .doc(docID)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Appointment deleted successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting appointment: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> updateAppointmentStatus(String docID, String status, String doctorId, String patientId) async {
    try {
      // Update in doctor's collection
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(doctorId)
          .collection('pending')
          .doc(docID)
          .update({'status': status});

      // Update in patient's collection
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(patientId)
          .collection('pending')
          .doc(docID)
          .update({'status': status});

      // Update in all collection
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(doctorId)
          .collection('all')
          .doc(docID)
          .update({'status': status});

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(patientId)
          .collection('all')
          .doc(docID)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Appointment ${status.toLowerCase()} successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating appointment: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> submitPayment(String docID, String doctorId, String patientId) async {
    final easypaisaNumber = _easypaisaController.text.trim();
    final amount = _amountController.text.trim();

    if (easypaisaNumber.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all payment details"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (easypaisaNumber.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 11-digit EasyPaisa number"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final paymentData = {
        'appointmentId': docID,
        'patientId': patientId,
        'doctorId': doctorId,
        'easypaisaNumber': easypaisaNumber,
        'amount': double.parse(amount),
        'paymentDate': Timestamp.now(),
        'status': 'pending',
        'paymentMethod': 'EasyPaisa',
      };

      await FirebaseFirestore.instance
          .collection('payments')
          .doc(docID)
          .set(paymentData);

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(doctorId)
          .collection('pending')
          .doc(docID)
          .update({'paymentStatus': 'pending', 'hasPayment': true});

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(patientId)
          .collection('pending')
          .doc(docID)
          .update({'paymentStatus': 'pending', 'hasPayment': true});

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment submitted successfully! Waiting for confirmation."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      _easypaisaController.clear();
      _amountController.clear();
      
      setState(() {});
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting payment: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showPaymentDialog(String docID, String doctorId, String patientId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payment, color: Colors.green.shade700, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                "Payment Details",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: const Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pay via EasyPaisa",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _easypaisaController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: "EasyPaisa Number",
                  hintText: "Enter 11-digit number",
                  prefixIcon: Icon(Icons.phone_android, color: const Color(0xFF1E40AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF1E40AF), width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount (PKR)",
                  hintText: "Enter amount",
                  prefixIcon: Icon(Icons.currency_rupee, color: const Color(0xFF1E40AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF1E40AF), width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Your payment will be verified within 24 hours",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _easypaisaController.clear();
                _amountController.clear();
              },
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                submitPayment(docID, doctorId, patientId);
              },
              child: Text(
                "Submit Payment",
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  String _dateFormatter(DateTime date) {
    try {
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return "Invalid date";
    }
  }

  String _timeFormatter(DateTime date) {
    try {
      return DateFormat('h:mm a').format(date);
    } catch (_) {
      return "Invalid time";
    }
  }

  void showDeleteDialog(BuildContext context, String doctorId, String patientId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                "Confirm Delete",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: const Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to delete this appointment?",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "No",
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (_documentID != null) {
                  deleteAppointment(_documentID!, doctorId, patientId);
                }
                Navigator.of(context).pop();
              },
              child: Text(
                "Yes, Delete",
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _checkDiff(DateTime date) {
    return DateTime.now().difference(date).inSeconds > 0;
  }

  bool _compareDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(DateTime.now()) == DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  @override
  void dispose() {
    _easypaisaController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: user == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
              ),
            )
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .doc(user!.uid)
                  .collection('pending')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading appointments',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDoctor ? Icons.medical_services : Icons.calendar_today,
                            size: 64,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isDoctor ? 'No Appointment Requests' : 'No Appointment Scheduled',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isDoctor ? 'Patient requests will appear here' : 'Your appointments will appear here',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final appointmentDate = (data['date'] as Timestamp).toDate();

                    if (_checkDiff(appointmentDate)) {
                      deleteAppointment(doc.id, data['doctorId'], data['patientId']);
                      return const SizedBox.shrink();
                    }

                    return _buildAppointmentCard(doc.id, data, appointmentDate);
                  },
                );
              },
            ),
    );
  }

  Widget _buildAppointmentCard(String docId, Map<String, dynamic> data, DateTime appointmentDate) {
    final isToday = _compareDate(appointmentDate);
    final name = isDoctor ? data['patientName'] : data['doctorName'];
    final role = isDoctor ? 'Patient' : 'Doctor';
    final status = data['status']?.toString()?.toLowerCase() ?? 'pending';
    final paymentStatus = data['paymentStatus']?.toString()?.toLowerCase() ?? 'none';
    final hasPayment = data['hasPayment'] ?? false;
    final isPatient = !isDoctor;
    final isDoctorUser = isDoctor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isToday
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                        )
                      : null,
                  color: isToday ? null : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isToday ? Colors.white24 : const Color(0xFF1E40AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        isDoctorUser ? Icons.person_outline : Icons.person_outline,
                        color: isToday ? Colors.white : const Color(0xFF1E40AF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isToday ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "TODAY",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildInfoRow(
                                icon: Icons.calendar_today,
                                label: "Date",
                                value: _dateFormatter(appointmentDate),
                                iconColor: const Color(0xFF1E40AF),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.access_time,
                                label: "Time",
                                value: _timeFormatter(appointmentDate),
                                iconColor: const Color(0xFF1E40AF),
                              ),
                              const SizedBox(height: 12),
                              if (data['description'] != null && data['description'].isNotEmpty)
                                _buildInfoRow(
                                  icon: Icons.description_outlined,
                                  label: "Description",
                                  value: data['description'],
                                  iconColor: const Color(0xFF1E40AF),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Status Badge
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(status), size: 16, color: _getStatusColor(status)),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(status),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 12),
                    
                    // Action Buttons - Doctor Side
                    if (isDoctorUser && status == 'pending') ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => updateAppointmentStatus(docId, 'confirmed', data['doctorId'], data['patientId']),
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: Text(
                                "Confirm",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _documentID = docId;
                                showDeleteDialog(context, data['doctorId'], data['patientId']);
                              },
                              icon: const Icon(Icons.cancel, size: 20),
                              label: Text(
                                "Reject",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Action Buttons - Patient Side
                    if (isPatient && status == 'pending') ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (!hasPayment)
                            _buildActionButton(
                              icon: Icons.payment,
                              label: "Pay Now",
                              color: Colors.green,
                              onPressed: () => showPaymentDialog(docId, data['doctorId'], data['patientId']),
                            ),
                          if (hasPayment)
                            _buildActionButton(
                              icon: paymentStatus == 'pending' ? Icons.pending : Icons.check_circle,
                              label: paymentStatus == 'pending' ? "Payment Pending" : "Paid",
                              color: paymentStatus == 'pending' ? Colors.orange : Colors.green,
                              onPressed: null,
                            ),
                          _buildActionButton(
                            icon: Icons.cancel,
                            label: "Cancel",
                            color: Colors.red,
                            isDestructive: true,
                            onPressed: () {
                              _documentID = docId;
                              showDeleteDialog(context, data['doctorId'], data['patientId']);
                            },
                          ),
                        ],
                      ),
                    ],

                    // Confirmed Status for Patients
                    if (isPatient && status == 'confirmed') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "✅ Appointment Confirmed",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    "Your appointment has been approved by the doctor",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Rejected Status for Patients
                    if (isPatient && status == 'cancelled') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "❌ Appointment Rejected",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    "Your appointment request was declined",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool isDestructive = false,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red.shade50 : color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.pending_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'completed':
        return Icons.task_alt;
      default:
        return Icons.circle_outlined;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}
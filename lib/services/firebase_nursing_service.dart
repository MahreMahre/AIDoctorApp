import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_app1/model/nursing_request.dart';
import 'package:health_app1/model/vital_record.dart';


class FirebaseNursingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _patientId => _auth.currentUser!.uid;

  // Book Nursing Request
  Future<void> createNursingRequest(NursingRequest request) async {
    await _firestore.collection('nursing_requests').add(request.toMap());
  }

  // Get Patient's Requests
  Stream<QuerySnapshot> getMyNursingRequests() {
    return _firestore
        .collection('nursing_requests')
        .where('patientId', isEqualTo: _patientId)
        .orderBy('requestDate', descending: true)
        .snapshots();
  }

  // Save Vital Records
  Future<void> saveVitalRecord(VitalRecord record) async {
    await _firestore.collection('vital_records').add(record.toMap());
  }

  // Get Vitals History
  Stream<QuerySnapshot> getVitalHistory() {
    return _firestore
        .collection('vital_records')
        .where('patientId', isEqualTo: _patientId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get Available Nurses
  Stream<QuerySnapshot> getAvailableNurses() {
    return _firestore
        .collection('nurses')
        .where('isAvailable', isEqualTo: true)
        .snapshots();
  }
}
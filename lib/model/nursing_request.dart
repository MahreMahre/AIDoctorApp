class NursingRequest {
  final String id;
  final String patientId;
  final String nurseId;
  final DateTime requestDate;
  final DateTime preferredDate;
  final String serviceType; // "Wound Care", "IV Therapy", "Daily Checkup", etc.
  final String description;
  final String status; // pending, accepted, completed, cancelled

  NursingRequest({
    required this.id,
    required this.patientId,
    required this.nurseId,
    required this.requestDate,
    required this.preferredDate,
    required this.serviceType,
    required this.description,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'nurseId': nurseId,
      'requestDate': requestDate,
      'preferredDate': preferredDate,
      'serviceType': serviceType,
      'description': description,
      'status': status,
    };
  }
}
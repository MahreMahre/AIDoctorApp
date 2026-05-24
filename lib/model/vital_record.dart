class VitalRecord {
  final String id;
  final String patientId;
  final DateTime timestamp;
  final double heartRate;
  final double temperature;
  final double bloodPressureSys;
  final double bloodPressureDia;
  final double oxygenLevel;
  final String notes;

  VitalRecord({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.heartRate,
    required this.temperature,
    required this.bloodPressureSys,
    required this.bloodPressureDia,
    required this.oxygenLevel,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'timestamp': timestamp,
      'heartRate': heartRate,
      'temperature': temperature,
      'bloodPressureSys': bloodPressureSys,
      'bloodPressureDia': bloodPressureDia,
      'oxygenLevel': oxygenLevel,
      'notes': notes,
    };
  }
}
class Message {
  final String senderId;
  final String message;
  final String time;
  final String type; // 'text' or 'prescription'
  final String? prescriptionId;
  final String? prescriptionUrl;
  final String? prescriptionName;

  Message({
    required this.senderId,
    required this.message,
    required this.time,
    this.type = 'text',
    this.prescriptionId,
    this.prescriptionUrl,
    this.prescriptionName,
  });

  factory Message.fromJson(Map<dynamic, dynamic> json) {
    return Message(
      senderId: json['senderId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      prescriptionId: json['prescriptionId']?.toString(),
      prescriptionUrl: json['prescriptionUrl']?.toString(),
      prescriptionName: json['prescriptionName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'message': message,
    'time': time,
    'type': type,
    if (prescriptionId != null) 'prescriptionId': prescriptionId,
    if (prescriptionUrl != null) 'prescriptionUrl': prescriptionUrl,
    if (prescriptionName != null) 'prescriptionName': prescriptionName,
  };
}
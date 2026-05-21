class Message {
  final String senderId;
  final String message;
  final String time;

  Message({
    required this.senderId,
    required this.message,
    required this.time,
  });

  factory Message.fromJson(Map<dynamic, dynamic> json) {
    return Message(
      senderId: json['senderId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'message': message,
    'time': time,
  };
}

import 'package:cloud_firestore/cloud_firestore.dart' as store;
import 'package:firebase_database/firebase_database.dart';
import 'package:health_app1/screens/chat/message.dart';

class MessageDao {
  late DatabaseReference _messageRef;
  final String user1;
  final String user2;

  MessageDao({required this.user1, required this.user2}) {
    var users = [user1, user2];
    users.sort();

    String chatRoomId = users.join('-');

    // create gateway of two chats
    createGateWay();

    _messageRef =
        FirebaseDatabase.instance.ref('chats').child(chatRoomId).child('chat');
  }

  Future<void> createGateWay() async {
    try {
      final snap1 = await store.FirebaseFirestore.instance
          .collection('users')
          .doc(user1)
          .get();
      final snap2 = await store.FirebaseFirestore.instance
          .collection('users')
          .doc(user2)
          .get();

      if (!snap1.exists || !snap2.exists) return;

      final user1Info = snap1.data() as Map<String, dynamic>? ?? {};
      final user2Info = snap2.data() as Map<String, dynamic>? ?? {};

      final user1Data = {
        'uid': user1,
        'name': user1Info['name'] ?? '',
        'photo': user1Info['profilePhoto'] ?? '',
      };

      final user2Data = {
        'uid': user2,
        'name': user2Info['name'] ?? '',
        'photo': user2Info['profilePhoto'] ?? '',
      };

      FirebaseDatabase.instance
          .ref('users')
          .child(user1)
          .child(user2)
          .set(user2Data);

      FirebaseDatabase.instance
          .ref('users')
          .child(user2)
          .child(user1)
          .set(user1Data);
    } catch (e) {
      print('Gateway creation error: $e');
    }
  }

  void saveMessage(Message message) {
    _messageRef.push().set(message.toJson());
  }

  Query getMessageQuery() {
    return _messageRef;
  }
}

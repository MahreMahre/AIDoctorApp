import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NurseChatScreen extends StatefulWidget {
  final String nurseId;
  final String nurseName;

  const NurseChatScreen({
    Key? key,
    required this.nurseId,
    required this.nurseName,
  }) : super(key: key);

  @override
  State<NurseChatScreen> createState() => _NurseChatScreenState();
}

class _NurseChatScreenState extends State<NurseChatScreen> {
  final TextEditingController _message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get chatId {
    return _auth.currentUser!.uid + "_" + widget.nurseId;
  }

  void sendMessage() {
    if (_message.text.isEmpty) return;

    _firestore.collection("chats").doc(chatId).collection("messages").add({
      "senderId": _auth.currentUser!.uid,
      "receiverId": widget.nurseId,
      "message": _message.text,
      "time": FieldValue.serverTimestamp(),
    });

    _message.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nurseName),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection("chats")
                  .doc(chatId)
                  .collection("messages")
                  .orderBy("time")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var msgs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    var msg = msgs[index];

                    bool isMe = msg['senderId'] ==
                        _auth.currentUser!.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['message'],
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
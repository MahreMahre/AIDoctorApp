import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'message.dart';
import 'message_dao.dart';

class ChatRoom extends StatefulWidget {
  final String user2Id;
  final String user2Name;
  final String profileUrl;

  const ChatRoom({
    Key? key,
    required this.user2Id,
    required this.user2Name,
    required this.profileUrl,
  }) : super(key: key);

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? user;
  MessageDao? messageDao;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    user = _auth.currentUser;
    if (user != null) {
      messageDao = MessageDao(user1: user!.uid, user2: widget.user2Id);
    }
    setState(() {
      isLoading = false;
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || messageDao == null || user == null) return;

    final message = Message(
      message: text,
      senderId: user!.uid,
      time: DateTime.now().toUtc().toIso8601String(),
    );

    messageDao!.saveMessage(message);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.profileUrl)),
            const SizedBox(width: 10),
            Text(
              widget.user2Name.length > 12
                  ? widget.user2Name.substring(0, 12)
                  : widget.user2Name,
            ),
          ],
        ),
        actions: const [
          Icon(Icons.call),
          SizedBox(width: 10),
          Icon(Icons.videocam),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return FirebaseAnimatedList(
      controller: _scrollController,
      query: messageDao!.getMessageQuery(),
      itemBuilder: (context, snapshot, animation, index) {
        if (snapshot.value == null || snapshot.value is! Map) {
          return const SizedBox.shrink();
        }

        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final msg = Message.fromJson(data);

        return MessageWidget(
          message: msg.message,
          time: msg.time,
          isMe: msg.senderId == user!.uid,
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return BottomAppBar(
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.grey[200],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(Icons.insert_emoticon),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: "Type a message",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;

  const MessageWidget({
    Key? key,
    required this.message,
    required this.time,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      margin: EdgeInsets.fromLTRB(isMe ? 60 : 8, 5, isMe ? 8 : 60, 5),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: isMe ? const Radius.circular(15) : Radius.zero,
            topRight: isMe ? Radius.zero : const Radius.circular(15),
            bottomLeft: const Radius.circular(15),
            bottomRight: const Radius.circular(15),
          ),
          color: isMe ? Colors.blue[300] : Colors.grey[300],
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

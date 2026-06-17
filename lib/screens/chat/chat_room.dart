import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ==================== MESSAGE MODEL ====================
class Message {
  final String senderId;
  final String message;
  final String time;
  final String type;
  final String? prescriptionId;
  final String? prescriptionUrl;
  final String? imageUrl;

  Message({
    required this.senderId,
    required this.message,
    required this.time,
    this.type = 'text',
    this.prescriptionId,
    this.prescriptionUrl,
    this.imageUrl,
  });

  factory Message.fromJson(Map<dynamic, dynamic> json) {
    return Message(
      senderId: json['senderId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      prescriptionId: json['prescriptionId']?.toString(),
      prescriptionUrl: json['prescriptionUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'message': message,
    'time': time,
    'type': type,
    if (prescriptionId != null) 'prescriptionId': prescriptionId,
    if (prescriptionUrl != null) 'prescriptionUrl': prescriptionUrl,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

// ==================== MESSAGE DAO ====================
class MessageDao {
  final String user1;
  final String user2;

  MessageDao({required this.user1, required this.user2});

  DatabaseReference getMessageQuery() {
    String chatId = _getChatId(user1, user2);
    return FirebaseDatabase.instance.ref('messages/$chatId');
  }

  void saveMessage(Message message) {
    String chatId = _getChatId(user1, user2);
    DatabaseReference ref = FirebaseDatabase.instance.ref('messages/$chatId');
    ref.push().set(message.toJson());
  }

  String _getChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }
}

// ==================== CHAT ROOM ====================
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
  final FocusNode _focusNode = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? user;
  MessageDao? messageDao;
  bool isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initializeChat() async {
    user = _auth.currentUser;
    if (user != null) {
      messageDao = MessageDao(user1: user!.uid, user2: widget.user2Id);
    }
    setState(() {
      isLoading = false;
    });
    _scrollToBottom();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || messageDao == null || user == null || _isSending) return;

    setState(() {
      _isSending = true;
    });

    final message = Message(
      message: text,
      senderId: user!.uid,
      time: DateTime.now().toUtc().toIso8601String(),
      type: 'text',
    );

     messageDao!.saveMessage(message);
    
    setState(() {
      _messageController.clear();
      _isSending = false;
    });
    
    _scrollToBottom();
  }

  // ========== PRESCRIPTION UPLOAD (DOCTOR) ==========
  Future<void> _sendPrescription() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile == null) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      File file = File(pickedFile.path);
      String fileName = 'prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String filePath = 'chat_prescriptions/${widget.user2Id}/$fileName';
      
      Reference ref = _storage.ref().child(filePath);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      
      String doctorName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Doctor' : 'Doctor';
      
      Map<String, dynamic> prescriptionData = {
        'prescriptionId': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': user!.uid,
        'receiverId': widget.user2Id,
        'doctorName': doctorName,
        'prescriptionUrl': downloadUrl,
        'uploadedAt': Timestamp.now(),
        'status': 'active',
        'medicines': [],
        'diagnosis': '',
        'notes': '',
      };
      
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(widget.user2Id)
          .collection('chat_prescriptions')
          .doc(prescriptionData['prescriptionId'])
          .set(prescriptionData);
      
      final message = Message(
        message: '📋 Prescription uploaded',
        senderId: user!.uid,
        time: DateTime.now().toUtc().toIso8601String(),
        type: 'prescription',
        prescriptionId: prescriptionData['prescriptionId'],
        prescriptionUrl: downloadUrl,
      );
      
     messageDao!.saveMessage(message);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Prescription sent successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading prescription: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // ========== SYMPTOM PHOTO UPLOAD (PATIENT - CAMERA) ==========
  Future<void> _sendSymptomPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    
    if (pickedFile == null) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      File file = File(pickedFile.path);
      String fileName = 'symptom_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String filePath = 'symptom_photos/${widget.user2Id}/$fileName';
      
      Reference ref = _storage.ref().child(filePath);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      final message = Message(
        message: '📸 Symptom Photo',
        senderId: user!.uid,
        time: DateTime.now().toUtc().toIso8601String(),
        type: 'image',
        imageUrl: downloadUrl,
      );
      
 messageDao!.saveMessage(message);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Symptom photo sent successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading photo: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // ========== SYMPTOM PHOTO UPLOAD (PATIENT - GALLERY) ==========
  Future<void> _pickSymptomPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile == null) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      File file = File(pickedFile.path);
      String fileName = 'symptom_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String filePath = 'symptom_photos/${widget.user2Id}/$fileName';
      
      Reference ref = _storage.ref().child(filePath);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      final message = Message(
        message: '📸 Symptom Photo',
        senderId: user!.uid,
        time: DateTime.now().toUtc().toIso8601String(),
        type: 'image',
        imageUrl: downloadUrl,
      );
      
   messageDao!.saveMessage(message);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Symptom photo sent successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading photo: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // ========== SHOW PHOTO OPTIONS (PATIENT) ==========
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Upload Symptom Photo",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(
                  icon: Icons.camera_alt,
                  label: "Camera",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _sendSymptomPhoto();
                  },
                ),
                _buildPhotoOption(
                  icon: Icons.photo_library,
                  label: "Gallery",
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickSymptomPhoto();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _viewPrescription(String prescriptionId, String prescriptionUrl) {
    if (prescriptionUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Prescription URL is empty"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionViewerChat(
          prescriptionId: prescriptionId,
          prescriptionUrl: prescriptionUrl,
          doctorName: widget.user2Name,
        ),
      ),
    );
  }

  void _viewImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image URL is empty"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          imageUrl: imageUrl,
          title: "Symptom Photo",
        ),
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      final DateTime time = DateTime.parse(timeString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return DateFormat('h:mm a').format(time);
      } else if (difference.inDays < 7) {
        return DateFormat('EEE h:mm a').format(time);
      } else {
        return DateFormat('MMM d, h:mm a').format(time);
      }
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isUploading)
            LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
            ),
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Color(0xFF1E40AF), size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E40AF).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey[100],
              backgroundImage: widget.profileUrl.isNotEmpty
                  ? NetworkImage(widget.profileUrl)
                  : null,
              child: widget.profileUrl.isEmpty
                  ? Icon(Icons.person, size: 24, color: Colors.grey.shade400)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user2Name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Online",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return FirebaseAnimatedList(
      controller: _scrollController,
      query: messageDao!.getMessageQuery(),
      defaultChild: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
        ),
      ),
      itemBuilder: (context, snapshot, animation, index) {
        if (snapshot.value == null || snapshot.value is! Map) {
          return const SizedBox.shrink();
        }

        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final msg = Message.fromJson(data);

        return SizeTransition(
          sizeFactor: animation,
          child: MessageWidget(
            message: msg.message,
            time: _formatTime(msg.time),
            isMe: msg.senderId == user!.uid,
            showStatus: index == 0 && msg.senderId == user!.uid,
            type: msg.type ?? 'text',
            prescriptionId: msg.prescriptionId,
            prescriptionUrl: msg.prescriptionUrl,
            imageUrl: msg.imageUrl,
            onPrescriptionTap: () {
              if (msg.prescriptionUrl != null && msg.prescriptionUrl!.isNotEmpty) {
                _viewPrescription(msg.prescriptionId ?? '', msg.prescriptionUrl!);
              }
            },
            onImageTap: () {
              if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) {
                _viewImage(msg.imageUrl!);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    final isPatient = user?.uid != widget.user2Id;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // PATIENT: Camera Button for Symptom Photos
              if (isPatient)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                    onPressed: _isUploading ? null : _showPhotoOptions,
                    tooltip: 'Upload Symptom Photo',
                  ),
                ),
              
              // DOCTOR: Prescription Upload Button
              if (!isPatient)
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.medical_information, color: Colors.white, size: 22),
                    onPressed: _isUploading ? null : _sendPrescription,
                    tooltip: 'Upload Prescription',
                  ),
                ),
              
              const SizedBox(width: 8),
              
              // Message Input Field
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined, size: 22),
                        color: Colors.grey.shade500,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: _messageController.text.trim().isEmpty 
                              ? Colors.grey.shade400 
                              : const Color(0xFF1E40AF),
                          size: 22,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MESSAGE WIDGET ====================
class MessageWidget extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;
  final bool showStatus;
  final String type;
  final String? prescriptionId;
  final String? prescriptionUrl;
  final String? imageUrl;
  final VoidCallback? onPrescriptionTap;
  final VoidCallback? onImageTap;

  const MessageWidget({
    Key? key,
    required this.message,
    required this.time,
    required this.isMe,
    this.showStatus = false,
    this.type = 'text',
    this.prescriptionId,
    this.prescriptionUrl,
    this.imageUrl,
    this.onPrescriptionTap,
    this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      margin: EdgeInsets.fromLTRB(isMe ? 60 : 16, 8, isMe ? 16 : 60, 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _showMessageOptions(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey.shade200, Colors.grey.shade100],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe 
                        ? const Color(0xFF1E40AF).withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: type == 'prescription'
                  ? _buildPrescriptionContent()
                  : type == 'image'
                      ? _buildImageContent()
                      : _buildTextContent(context),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              if (showStatus && isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    final hasLink = message.contains('http://') || message.contains('https://');
    
    if (hasLink) {
      return GestureDetector(
        onTap: () => _openLink(context),
        child: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: isMe ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationColor: isMe ? Colors.white70 : Colors.blue,
          ),
        ),
      );
    }
    
    return Text(
      message,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: isMe ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPrescriptionContent() {
    return InkWell(
      onTap: onPrescriptionTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf,
            color: isMe ? Colors.white : const Color(0xFF1E40AF),
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 Prescription',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : const Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to view prescription',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isMe ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.visibility,
            color: isMe ? Colors.white70 : const Color(0xFF1E40AF),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    return InkWell(
      onTap: onImageTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image,
            color: isMe ? Colors.white : const Color(0xFF1E40AF),
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📸 Symptom Photo',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : const Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to view image',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isMe ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.visibility,
            color: isMe ? Colors.white70 : const Color(0xFF1E40AF),
            size: 18,
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Message Options",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildOptionTile(
              icon: Icons.copy,
              label: "Copy Message",
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _copyMessage(context);
              },
            ),
            
            const Divider(),
            
            if (_hasLinks())
              _buildOptionTile(
                icon: Icons.open_in_browser,
                label: "Open Link",
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _openLink(context);
                },
              ),
            
            if (_hasLinks()) const Divider(),
            
            _buildOptionTile(
              icon: Icons.share,
              label: "Share Message",
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _shareMessage(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  bool _hasLinks() {
    return message.contains('http://') || message.contains('https://');
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Message copied to clipboard!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openLink(BuildContext context) async {
    final RegExp urlRegex = RegExp(r'(https?://[^\s]+)');
    final Iterable<RegExpMatch> matches = urlRegex.allMatches(message);
    
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No link found in this message"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final String url = matches.first.group(0)!;
    
    try {
      final Uri uri = Uri.parse(url);
      final bool canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not open link: $url"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error opening link: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Message copied to clipboard! You can paste it anywhere."),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ==================== IMAGE VIEWER ====================
class ImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageViewer({
    Key? key,
    required this.imageUrl,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ==================== PRESCRIPTION VIEWER ====================
class PrescriptionViewerChat extends StatelessWidget {
  final String prescriptionId;
  final String prescriptionUrl;
  final String doctorName;

  const PrescriptionViewerChat({
    Key? key,
    required this.prescriptionId,
    required this.prescriptionUrl,
    required this.doctorName,
  }) : super(key: key);

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
              'E-Prescription',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E40AF),
              ),
            ),
            Text(
              'Prescribed by $doctorName',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Doctor Info Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.medical_services, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescribed by',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctorName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Prescription Image
            Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    prescriptionUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 400,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 400,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load prescription',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is an official prescription issued by your doctor. Please keep it for your records.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
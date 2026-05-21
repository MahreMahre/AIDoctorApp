// chatbot_screen.dart (Updated: Removed image, added TTS, saved history to SharedPrefs)
import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

class GeminiService {
  final model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: 'AIzaSyBgMAMmHOlUcqSnbYaz12SZujDcztHZ7a8',
  );

  late final ChatSession chat;

  GeminiService() {
    chat = model.startChat();
  }

  Future<String> sendPrompt(String prompt) async {
    try {
      final content = Content.text(prompt);
      final response = await chat.sendMessage(content);
      return response.text ?? "I couldn't understand that.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final GeminiService _gemini = GeminiService();
  final FlutterTts _flutterTts = FlutterTts();
  final List<Map<String, String>> _messages = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;

  final List<String> healthTips = [
    "Drink at least 8 glasses of water daily",
    "Get 7–8 hours of quality sleep",
    "Exercise 30 minutes a day, 5 days a week",
    "Eat more fruits and vegetables",
    "Limit sugar and salt intake",
    "Manage stress through mindfulness or hobbies"
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Add initial SmartCare bot message
    _messages.add({
      'role': 'bot',
      'text': "Hello! This is Symptom Checkerhi Bot. How may I help you today?",
    });

    // Save to shared prefs if needed

  }


  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getString('chat_history');
    if (history != null) {
      setState(() {
        _messages.addAll(List<Map<String, String>>.from(json.decode(history)));
      });
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', json.encode(_messages));
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _sendMessage({String? input}) async {
    final text = input ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({ 'role': 'user', 'text': text });
      _controller.clear();
    });
    await _saveChatHistory();

    final response = await _gemini.sendPrompt(text);

    setState(() {
      _messages.add({ 'role': 'bot', 'text': response });
    });
    _speak(response);
    await _saveChatHistory();
  }

  void _startListening() async {
    if (!_isListening && !_speech.isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          setState(() => _controller.text = result.recognizedWords);
        });
      }
    } else if (_speech.isListening) {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _showHealthTips() {
    final tipText = "**Basic Healthcare Tips:**\n\n${healthTips.map((e) => '- $e').join('\n')}";
    setState(() {
      _messages.add({ 'role': 'bot', 'text': tipText });
    });
    _speak("Here are some health tips for you.");
    _saveChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade100,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        title: Text(
          "AI Symptoms Checker",
          // style: GoogleFonts.lato(
          //   color: Colors.black,
          //   fontWeight: FontWeight.bold,
          //   fontSize: 20,
          // ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.mic), onPressed: _startListening),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "tips") {
                _showHealthTips();
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: "tips", child: Text("Show Health Tips")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.all(12),
                    margin:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: MarkdownBody(
                      data: msg['text'] ?? '',
                      styleSheet: MarkdownStyleSheet(
                        // p: GoogleFonts.lato(fontSize: 16),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                     // listBullet: GoogleFonts.lato(fontSize: 16),
                      ), 
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    // style: GoogleFonts.lato(),
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      // hintStyle: GoogleFonts.lato(color: Colors.black45),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

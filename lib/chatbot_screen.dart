import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _tts = FlutterTts();

  final List<Map<String, String>> _messages = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;

  bool showQuestionnaire = true;

  final List<Map<String, dynamic>> questions = [
    {"q": "Do you have fever?", "selected": false},
    {"q": "Do you have headache?", "selected": false},
    {"q": "Do you have cough or cold?", "selected": false},
    {"q": "Do you feel body pain or fatigue?", "selected": false},
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadChat();

    _messages.add({
      "role": "bot",
      "text": "👋 Hi! I am your Offline Symptom Checker Assistant."
    });
  }

  // ---------------- CHAT SAVE ----------------
  Future<void> _loadChat() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("chat_history");
    if (data != null) {
      _messages.addAll(List<Map<String, String>>.from(json.decode(data)));
      setState(() {});
    }
  }

  Future<void> _saveChat() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("chat_history", json.encode(_messages));
  }

  // ---------------- TTS ----------------
  void _speak(String text) async {
    await _tts.speak(text);
  }

  // ---------------- SYMPTOM LOGIC (NO AI) ----------------
  String getSymptomResponse(String text) {
    text = text.toLowerCase();

    // HIGH FEVER
    if (text.contains("high fever") || text.contains("very hot") || text.contains("103")) {
      return "⚠️ Possible: Severe Fever / Infection\n\nAdvice:\n- Take paracetamol\n- Drink fluids\n- Visit doctor if >3 days";
    }

    // FEVER
    if (text.contains("fever") || text.contains("temperature")) {
      return "🤒 Possible: Viral Fever\n\nAdvice:\n- Rest\n- Hydration\n- Paracetamol if needed";
    }

    // HEADACHE
    if (text.contains("headache") || text.contains("head pain")) {
      return "🤕 Possible: Stress / Migraine\n\nAdvice:\n- Rest in dark room\n- Drink water\n- Reduce screen time";
    }

    // COUGH
    if (text.contains("cough") || text.contains("cold")) {
      return "🤧 Possible: Cold / Flu\n\nAdvice:\n- Warm fluids\n- Steam inhalation\n- Rest";
    }

    // BODY PAIN
    if (text.contains("body pain") || text.contains("muscle pain")) {
      return "💢 Possible: Viral infection / Fatigue\n\nAdvice:\n- Rest\n- Warm bath\n- Pain relief medicine";
    }

    // STOMACH PAIN
    if (text.contains("stomach") || text.contains("abdominal pain")) {
      return "🤢 Possible: Gas / Indigestion\n\nAdvice:\n- Light food\n- Avoid oily food\n- Drink warm water";
    }

    // BREATHING
    if (text.contains("breath") || text.contains("breathing issue")) {
      return "🚨 Possible: Respiratory issue\n\nAdvice:\n- Seek medical help immediately";
    }

    return "❗ I couldn't identify exact symptoms.\nPlease describe more clearly (fever, cough, headache etc).";
  }

  // ---------------- SEND MESSAGE ----------------
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
    });

    _controller.clear();

    final response = getSymptomResponse(text);

    setState(() {
      _messages.add({"role": "bot", "text": response});
    });

    _speak(response);
    await _saveChat();
  }

  // ---------------- QUESTIONNAIRE ----------------
  void _submitQuestionnaire() {
    String input = questions
        .map((e) => "${e['q']} : ${e['selected'] ? "Yes" : "No"}")
        .join("\n");

    setState(() => showQuestionnaire = false);

    _sendMessage("Symptom Report:\n$input");
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Offline Symptom Checker"),
        backgroundColor: Colors.blue.shade200,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              _messages.clear();
              setState(() {});
              final prefs = await SharedPreferences.getInstance();
              prefs.remove("chat_history");
            },
          )
        ],
      ),

      body: Column(
        children: [
          // ---------------- QUESTIONNAIRE ----------------
          if (showQuestionnaire)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🩺 Quick Health Check",
                    style: GoogleFonts.lato(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...questions.map((q) {
                    return Row(
                      children: [
                        Expanded(child: Text(q["q"])),
                        Checkbox(
                          value: q["selected"],
                          onChanged: (v) {
                            setState(() => q["selected"] = v);
                          },
                        )
                      ],
                    );
                  }),

                  ElevatedButton(
                    onPressed: _submitQuestionnaire,
                    child: const Text("Check Symptoms"),
                  )
                ],
              ),
            ),

          // ---------------- CHAT ----------------
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: MarkdownBody(data: msg["text"] ?? ""),
                  ),
                );
              },
            ),
          ),

          // ---------------- INPUT ----------------
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Describe your symptoms...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
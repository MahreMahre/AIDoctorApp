import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userType;
  
  const ChatScreen({
    super.key, 
    required this.userId,
    this.userType = 'patient',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  final GoogleTranslator _translator = GoogleTranslator();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _messages = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isTranslating = false;
  bool _speechAvailable = false;
  bool _isThinking = false;
  String _selectedLanguage = 'en';
  final ScrollController _scrollController = ScrollController();
  
  // AI Configuration
  late GenerativeModel _aiModel;
  final String _apiKey = 'YOUR_GEMINI_API_KEY';
  
  final Map<String, String> _languages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'ur': 'Urdu',
  };

  bool showQuestionnaire = true;

  final List<Map<String, dynamic>> questions = [
    {"q": "Do you have fever?", "selected": false, "icon": Icons.thermostat},
    {"q": "Do you have headache?", "selected": false, "icon": Icons.healing},
    {"q": "Do you have cough or cold?", "selected": false, "icon": Icons.medical_information},
    {"q": "Do you feel body pain or fatigue?", "selected": false, "icon": Icons.fitness_center},
  ];

  List<Map<String, dynamic>> _suggestedDoctors = [];
  bool _loadingDoctors = false;
  Map<String, dynamic>? _selectedDoctor;
  
  List<Map<String, dynamic>> _userAppointments = [];
  bool _loadingAppointments = false;

  // Doctor specialization mapping with exact keywords
  final Map<String, List<String>> _symptomToSpecialization = {
    'heart': ['cardiologist', 'cardiology'],
    'chest pain': ['cardiologist', 'cardiology'],
    'palpitations': ['cardiologist', 'cardiology'],
    'fever': ['general physician', 'internal medicine', 'general'],
    'temperature': ['general physician', 'internal medicine', 'general'],
    'headache': ['neurologist', 'general'],
    'migraine': ['neurologist', 'general'],
    'cough': ['pulmonologist', 'ent', 'general'],
    'cold': ['ent', 'general', 'pulmonologist'],
    'sore throat': ['ent', 'general'],
    'pain': ['orthopedic', 'neurologist', 'general'],
    'muscle pain': ['orthopedic', 'general'],
    'joint pain': ['orthopedic', 'rheumatologist', 'general'],
    'body pain': ['general', 'orthopedic'],
    'stomach': ['gastroenterologist', 'general'],
    'abdominal': ['gastroenterologist', 'general'],
    'nausea': ['gastroenterologist', 'general'],
    'vomiting': ['gastroenterologist', 'general'],
    'breath': ['pulmonologist', 'cardiologist', 'general'],
    'breathing': ['pulmonologist', 'cardiologist', 'general'],
    'chest': ['cardiologist', 'pulmonologist', 'general'],
    'allergy': ['allergist', 'ent', 'dermatologist'],
    'skin': ['dermatologist', 'general'],
    'rash': ['dermatologist', 'general'],
    'eye': ['ophthalmologist', 'general'],
    'vision': ['ophthalmologist', 'general'],
    'ear': ['ent', 'general'],
    'hearing': ['ent', 'general'],
    'throat': ['ent', 'general'],
    'joint': ['orthopedic', 'rheumatologist', 'general'],
    'diabetes': ['endocrinologist', 'general'],
    'blood sugar': ['endocrinologist', 'general'],
    'thyroid': ['endocrinologist', 'general'],
    'mental': ['psychiatrist', 'psychologist', 'general'],
    'depression': ['psychiatrist', 'psychologist', 'general'],
    'anxiety': ['psychiatrist', 'psychologist', 'general'],
    'stress': ['psychiatrist', 'psychologist', 'general'],
    'pregnancy': ['gynecologist', 'obstetrician', 'general'],
    'women': ['gynecologist', 'general'],
    'menstrual': ['gynecologist', 'general'],
    'child': ['pediatrician', 'general'],
    'baby': ['pediatrician', 'general'],
    'kidney': ['nephrologist', 'general'],
    'urine': ['nephrologist', 'general'],
    'liver': ['gastroenterologist', 'hepatologist', 'general'],
    'jaundice': ['gastroenterologist', 'hepatologist', 'general'],
    'back pain': ['orthopedic', 'neurologist', 'general'],
    'neck pain': ['orthopedic', 'neurologist', 'general'],
    'dizziness': ['neurologist', 'general'],
    'fainting': ['neurologist', 'cardiologist', 'general'],
    'sleep': ['psychiatrist', 'neurologist', 'general'],
    'insomnia': ['psychiatrist', 'neurologist', 'general'],
    'weight loss': ['endocrinologist', 'gastroenterologist', 'general'],
    'weight gain': ['endocrinologist', 'general'],
    'infection': ['general', 'infectious disease'],
    'wound': ['general', 'surgeon'],
    'injury': ['orthopedic', 'general'],
    'fracture': ['orthopedic', 'general'],
    'burn': ['general', 'dermatologist'],
    'cancer': ['oncologist', 'general'],
    'tumor': ['oncologist', 'general'],
    'blood': ['hematologist', 'general'],
    'anemia': ['hematologist', 'general'],
    'stroke': ['neurologist', 'cardiologist'],
    'paralysis': ['neurologist', 'general'],
    'seizure': ['neurologist', 'general'],
    'epilepsy': ['neurologist', 'general'],
  };

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _initSpeech();
    _loadChat();
    _loadUserAppointments();
    _addWelcomeMessage();
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
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

  void _addWelcomeMessage() {
    _messages.add({
      "role": "bot",
      "text": "👋 Hi! I'm your AI Health Assistant.\n\nI can:\n✅ Analyze your symptoms\n✅ Provide medical advice\n✅ Recommend specialist doctors\n✅ Book appointments\n✅ Understand voice commands\n✅ Translate messages\n\n**How to use:**\n• Describe your symptoms like \"I have heart pain\"\n• Type \"find doctor\" to see all doctors\n• Long press any message to translate\n• Tap microphone for voice input\n\nHow can I help you today?",
      "timestamp": DateTime.now(),
      "originalText": "👋 Hi! I'm your AI Health Assistant powered by Google Gemini.\n\nI can:\n✅ Analyze your symptoms\n✅ Provide medical advice\n✅ Recommend specialist doctors\n✅ Book appointments\n✅ Understand voice commands\n✅ Translate messages\n\n**How to use:**\n• Describe your symptoms like \"I have heart pain\"\n• Type \"find doctor\" to see all doctors\n• Long press any message to translate\n• Tap microphone for voice input\n\nHow can I help you today?"
    });
    _scrollToBottom();
  }

  // ---------------- AI INITIALIZATION ----------------
  void _initializeAI() {
    try {
      _aiModel = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 1,
          topP: 1,
          maxOutputTokens: 2048,
        ),
      );
    } catch (e) {
      print('Error initializing AI: $e');
    }
  }

  // ---------------- AI RESPONSE ----------------
  Future<String> _getAIResponse(String userMessage) async {
    try {
      String chatContext = '';
      for (var msg in _messages.reversed.take(6)) {
        chatContext = '${msg['role']}: ${msg['text']}\n$chatContext';
      }
      
      const systemPrompt = """
      You are a professional medical assistant AI. Your role:
      1. Analyze symptoms carefully and provide helpful medical advice
      2. Never give emergency medical advice - always tell users to call emergency services for emergencies
      3. Recommend seeing a doctor for serious symptoms
      4. Be empathetic, professional, and friendly
      5. Provide health tips and preventive measures
      6. Keep responses concise but informative (max 200 words)
      7. Always start with emoji related to symptoms
      
      Remember: You are not a replacement for professional medical advice.
      Always recommend consulting healthcare professionals when needed.
      """;
      
      final prompt = "$systemPrompt\n\nChat History:\n$chatContext\n\nUser: $userMessage\n\nAssistant:";
      
      final response = await _aiModel.generateContent([Content.text(prompt)]);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('AI Error: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  String _getFallbackResponse(String userMessage) {
    String lowerMsg = userMessage.toLowerCase();
    
    if (lowerMsg.contains('heart') || lowerMsg.contains('chest pain')) {
      return "❤️ **Heart Health**\n\n• Rest immediately\n• Avoid strenuous activity\n• Monitor symptoms\n\n**IMPORTANT:** If severe, call emergency services immediately.\n\nConsult a **Cardiologist** for proper evaluation.\n\n**Finding Cardiologists near you...**";
    } else if (lowerMsg.contains('fever')) {
      return "🤒 **Fever Analysis**\n\n• **Rest** and stay hydrated\n• Take **paracetamol** if needed\n• Monitor temperature regularly\n• Consult a **General Physician** if fever persists >3 days\n\n**Finding General Physicians for you...**";
    } else if (lowerMsg.contains('headache')) {
      return "🤕 **Headache Relief Tips**\n\n• Rest in a dark, quiet room\n• Stay hydrated\n• Apply cold compress\n• Limit screen time\n\nIf severe or persistent, consult a **Neurologist**.\n\n**Finding Neurologists near you...**";
    } else {
      return "Thank you for sharing. I'm analyzing your symptoms and finding the right specialist for you...";
    }
  }

  // ---------------- DOCTOR FUNCTIONS ----------------
  void _showDoctorDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.indigo],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medical_services, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '👨‍⚕️ Available Doctors',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('type', isEqualTo: 'doctor')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final doctors = snapshot.data!.docs;
                    
                    if (doctors.isEmpty) {
                      return const Center(child: Text('No doctors found'));
                    }
                    
                    return ListView.builder(
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final data = doctors[index].data() as Map<String, dynamic>;
                        final doctor = {
                          'id': doctors[index].id,
                          'name': data['name'] ?? 'Unknown',
                          'specialization': data['specialization'] ?? 'general',
                          'specification': data['specification'] ?? '',
                          'rating': data['rating'] ?? 4.0,
                          'email': data['email'] ?? 'N/A',
                          'openHour': data['openHour'] ?? '09:00 AM',
                          'closeHour': data['closeHour'] ?? '09:00 PM',
                          'address': data['address'] ?? 'Address not specified',
                          'bio': data['bio'] ?? 'Experienced doctor',
                          'phone': data['phone'] ?? 'Not available',
                          'profilePhoto': data['profilePhoto'] ?? '',
                        };
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundImage: doctor['profilePhoto'] != null && doctor['profilePhoto'].isNotEmpty
                                  ? NetworkImage(doctor['profilePhoto'])
                                  : null,
                              backgroundColor: Colors.blue.shade100,
                              child: doctor['profilePhoto'] == null || doctor['profilePhoto'].isEmpty
                                  ? Text(doctor['name'][0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            title: Text(
                              'Dr. ${doctor['name']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (doctor['specification'] != null && doctor['specification'].isNotEmpty)
                                        ? doctor['specification'].toString().toUpperCase()
                                        : doctor['specialization'].toString().toUpperCase(),
                                    style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                                    const SizedBox(width: 4),
                                    Text('${doctor['rating']}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text('${doctor['openHour']} - ${doctor['closeHour']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(doctor['address'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    ),
                                  ],
                                ),
                                if (doctor['phone'] != 'Not available')
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(doctor['phone'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                _bookAppointment(context, doctor, "General consultation");
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('Book', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getMatchingSpecializations(String symptoms) {
    String lowerSymptoms = symptoms.toLowerCase();
    Set<String> matchingSpecs = {};
    
    // Check each symptom keyword
    _symptomToSpecialization.forEach((symptom, specializations) {
      if (lowerSymptoms.contains(symptom)) {
        matchingSpecs.addAll(specializations);
      }
    });
    
    // If no match found, return general physicians only
    if (matchingSpecs.isEmpty) {
      matchingSpecs.add('general');
      matchingSpecs.add('general physician');
    }
    
    return matchingSpecs.toList();
  }

  bool _isDoctorMatching(String doctorSpec, List<String> requiredSpecs) {
    String lowerSpec = doctorSpec.toLowerCase();
    for (String required in requiredSpecs) {
      if (lowerSpec.contains(required) || required.contains(lowerSpec)) {
        return true;
      }
    }
    return false;
  }

  void _showDoctorRecommendations(String symptoms) async {
    setState(() {
      _loadingDoctors = true;
      _suggestedDoctors = [];
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('type', isEqualTo: 'doctor')
          .get();

      final allDoctors = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'specialization': (data['specialization'] ?? '').toString().toLowerCase(),
          'specification': (data['specification'] ?? '').toString().toLowerCase(),
          'rating': data['rating'] ?? 4.0,
          'email': data['email'] ?? 'N/A',
          'openHour': data['openHour'] ?? '09:00 AM',
          'closeHour': data['closeHour'] ?? '09:00 PM',
          'address': data['address'] ?? 'Address not specified',
          'bio': data['bio'] ?? 'Experienced doctor',
          'phone': data['phone'] ?? 'Not available',
          'profilePhoto': data['profilePhoto'] ?? '',
        };
      }).toList();

      // Get matching specializations based on symptoms
      List<String> matchingSpecializations = _getMatchingSpecializations(symptoms);
      
      final List<Map<String, dynamic>> matchedDoctors = [];
      final Set<String> addedDoctorIds = {}; // To avoid duplicates
      
      // First pass: Exact specialization match
      for (var doc in allDoctors) {
        final spec = doc['specialization'] as String;
        final specification = doc['specification'] as String;
        final combinedSpec = '$spec $specification';
        
        for (String requiredSpec in matchingSpecializations) {
          if (_isDoctorMatching(combinedSpec, [requiredSpec])) {
            if (!addedDoctorIds.contains(doc['id'])) {
              doc['priorityScore'] = 10;
              matchedDoctors.add(doc);
              addedDoctorIds.add(doc['id']);
              break;
            }
          }
        }
      }
      
      // Second pass: Partial match (if no exact matches found)
      if (matchedDoctors.isEmpty) {
        for (var doc in allDoctors) {
          final spec = doc['specialization'] as String;
          final specification = doc['specification'] as String;
          final combinedSpec = '$spec $specification';
          
          for (String requiredSpec in matchingSpecializations) {
            if (combinedSpec.contains(requiredSpec.split(' ').first) || 
                requiredSpec.contains(spec.split(' ').first)) {
              if (!addedDoctorIds.contains(doc['id'])) {
                doc['priorityScore'] = 5;
                matchedDoctors.add(doc);
                addedDoctorIds.add(doc['id']);
                break;
              }
            }
          }
        }
      }
      
      // Sort by priority score
      matchedDoctors.sort((a, b) => (b['priorityScore'] ?? 0).compareTo(a['priorityScore'] ?? 0));
      
      setState(() {
        _suggestedDoctors = matchedDoctors;
        _loadingDoctors = false;
      });
      
      if (_suggestedDoctors.isNotEmpty) {
        // Get specialist names for display
        String specialistNames = matchingSpecializations
            .where((s) => s != 'general' && s != 'general physician')
            .take(3)
            .map((s) => s.split(' ').map((word) => 
                word[0].toUpperCase() + word.substring(1)).join(' '))
            .join(', ');
        
        if (specialistNames.isEmpty) {
          specialistNames = 'General Physicians';
        }
        
        _addBotMessage("👨‍⚕️ **${specialistNames}**\n\nI've found ${matchedDoctors.length} doctor(s) who specialize in your symptoms.\n\nPlease select a doctor below to book an appointment:");
      } else {
        // Fallback: Show top rated general doctors
        final generalDoctors = allDoctors
            .where((doc) => 
                (doc['specialization'] as String).contains('general') || 
                (doc['specification'] as String).contains('general'))
            .take(5)
            .toList();
        
        setState(() {
          _suggestedDoctors = generalDoctors;
          _loadingDoctors = false;
        });
        
        if (_suggestedDoctors.isNotEmpty) {
          _addBotMessage("👨‍⚕️ **General Physicians**\n\nI've found some General Physicians who can help with your symptoms.\n\nPlease select a doctor below to book an appointment:");
        } else {
          setState(() {
            _suggestedDoctors = [];
            _loadingDoctors = false;
          });
          _addBotMessage("No doctors found matching your symptoms. Please try describing your symptoms differently or type 'find doctor' to see all available doctors.");
        }
      }
      
    } catch (e) {
      setState(() {
        _suggestedDoctors = [];
        _loadingDoctors = false;
      });
      _showSnackBar('Error fetching doctors: $e');
    }
  }

  // ---------------- SPEECH TO TEXT ----------------
  Future<void> _initSpeech() async {
    await _r9yMnTm4NSzvG9rrwjM2ec8xZgh1cafXH8();
    
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'notListening' && _isListening) {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        print('Speech error: $error');
        setState(() => _isListening = false);
        _showSnackBar('Speech error: ${error.errorMsg}');
      },
    );
    
    if (!_speechAvailable) {
      _showSnackBar('Speech recognition not available');
    }
  }
  
  Future<void> _r9yMnTm4NSzvG9rrwjM2ec8xZgh1cafXH8() async {
    PermissionStatus status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (!status.isGranted) {
      _showSnackBar('Microphone permission is required for voice input');
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await _initSpeech();
    }
    
    if (!_speechAvailable) {
      _showSnackBar('Speech recognition is not available');
      return;
    }
    
    if (_speech.isListening) {
      _stopListening();
      return;
    }
    
    setState(() => _isListening = true);
    
    try {
      await _speech.listen(
        onResult: (result) {
          print('Speech result: ${result.recognizedWords}');
          setState(() {
            _controller.text = result.recognizedWords;
          });
          
          if (result.finalResult && _controller.text.isNotEmpty) {
            _stopListening();
            _sendMessage(_controller.text);
            _controller.clear();
          }
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: (level) {},
      );
    } catch (e) {
      print('Error starting speech: $e');
      setState(() => _isListening = false);
      _showSnackBar('Error starting voice input');
    }
  }

  void _stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
    setState(() => _isListening = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ---------------- TRANSLATION ----------------
  Future<String> _translateText(String text, String targetLang) async {
    if (targetLang == 'en') return text;
    
    try {
      final translation = await _translator.translate(text, to: targetLang);
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  Future<void> _translateMessage(int index, String text, String targetLang) async {
    setState(() => _isTranslating = true);
    final translated = await _translateText(text, targetLang);
    setState(() {
      _messages[index]['translatedText'] = translated;
      _messages[index]['translationLang'] = targetLang;
      _isTranslating = false;
    });
  }

  void _showTranslationDialog(Map<String, dynamic> message, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Translate Message',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Original: ${message['text']}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Select Language:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.entries.map((lang) {
                return FilterChip(
                  label: Text(lang.value),
                  selected: _selectedLanguage == lang.key,
                  onSelected: (selected) {
                    setState(() => _selectedLanguage = lang.key);
                    Navigator.pop(context);
                    _translateMessage(index, message['text'], lang.key);
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.blue.shade100,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TEXT TO SPEECH ----------------
  void _speak(String text) async {
    try {
      await _tts.setLanguage(_selectedLanguage);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.speak(text);
    } catch (e) {
      print('TTS error: $e');
    }
  }

  // ---------------- CHAT SAVE ----------------
  Future<void> _loadChat() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("chat_history_${widget.userId}");
    if (data != null) {
      List<dynamic> decoded = json.decode(data);
      _messages.addAll(decoded.map((item) {
        return {
          'role': item['role'],
          'text': item['text'],
          'timestamp': item['timestamp'] != null ? DateTime.parse(item['timestamp']) : null,
          'originalText': item['originalText'],
        };
      }).toList());
      setState(() {});
      _scrollToBottom();
    }
  }

  Future<void> _saveChat() async {
    final prefs = await SharedPreferences.getInstance();
    final saveMessages = _messages.map((msg) {
      return {
        'role': msg['role'],
        'text': msg['text'],
        'timestamp': msg['timestamp']?.toIso8601String(),
        'originalText': msg['originalText'],
      };
    }).toList();
    await prefs.setString("chat_history_${widget.userId}", json.encode(saveMessages));
  }

  // ---------------- APPOINTMENTS ----------------
  Future<void> _loadUserAppointments() async {
    setState(() => _loadingAppointments = true);
    
    try {
      final appointmentsQuery = await FirebaseFirestore.instance
          .collection('Appointments')
          .where('patientId', isEqualTo: widget.userId)
          .orderBy('appointmentDate', descending: false)
          .get();
      
      setState(() {
        _userAppointments = appointmentsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'doctorId': data['doctorId'],
            'doctorName': data['doctorName'],
            'appointmentDate': data['appointmentDate'],
            'appointmentTime': data['appointmentTime'],
            'status': data['status'] ?? 'pending',
            'symptoms': data['symptoms'],
            'notes': data['notes'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading appointments: $e');
    } finally {
      setState(() => _loadingAppointments = false);
    }
  }

  Future<void> _bookAppointment(BuildContext context, Map<String, dynamic> doctor, String symptoms) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      await FirebaseFirestore.instance.collection('Appointments').add({
        'patientId': widget.userId,
        'doctorId': doctor['id'],
        'doctorName': doctor['name'],
        'patientName': await _getUserName(widget.userId),
        'appointmentDate': Timestamp.fromDate(date),
        'appointmentTime': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        'symptoms': symptoms,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
      
      Navigator.pop(context);
      await _loadUserAppointments();
      
      _showSnackBar('✅ Appointment booked successfully!');
      _addBotMessage("✅ **Appointment Confirmed!**\n\nYour appointment with **Dr. ${doctor['name']}** has been booked for **${DateFormat('MMM dd, yyyy').format(date)}** at **${time.format(context)}**.");
      
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar('Error booking appointment: $e');
    }
  }
  
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.data()?['name'] ?? 'Patient';
    } catch (e) {
      return 'Patient';
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              await FirebaseFirestore.instance.collection('Appointments').doc(appointmentId).update({
                'status': 'cancelled',
                'cancelledAt': Timestamp.now(),
              });
              await _loadUserAppointments();
              Navigator.pop(context);
              _showSnackBar('Appointment cancelled successfully');
              _addBotMessage("Your appointment has been cancelled.");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_today, size: 24, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Text('My Appointments', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: _loadingAppointments
                    ? const Center(child: CircularProgressIndicator())
                    : _userAppointments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text('No appointments found', style: GoogleFonts.poppins(color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('Book your first appointment!', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _userAppointments.length,
                            itemBuilder: (context, index) {
                              final appointment = _userAppointments[index];
                              final statusColor = appointment['status'] == 'pending' ? Colors.orange : 
                                  appointment['status'] == 'confirmed' ? Colors.green : Colors.red;
                              final appointmentDate = appointment['appointmentDate'] as Timestamp?;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: statusColor.withOpacity(0.2),
                                    child: Icon(Icons.medical_services, color: statusColor),
                                  ),
                                  title: Text('Dr. ${appointment['doctorName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (appointmentDate != null)
                                        Text('Date: ${DateFormat('MMM dd, yyyy').format(appointmentDate.toDate())}'),
                                      Text('Time: ${appointment['appointmentTime']}'),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          appointment['status'].toString().toUpperCase(),
                                          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: appointment['status'] == 'pending'
                                      ? TextButton.icon(
                                          onPressed: () => _cancelAppointment(appointment['id']),
                                          icon: const Icon(Icons.cancel, size: 16),
                                          label: const Text('Cancel'),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({
        "role": "bot", 
        "text": text,
        "timestamp": DateTime.now(),
        "originalText": text
      });
    });
    _speak(text);
    _saveChat();
    _scrollToBottom();
  }

  // ---------------- SEND MESSAGE ----------------
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        "role": "user", 
        "text": text, 
        "timestamp": DateTime.now(),
        "originalText": text
      });
      _isThinking = true;
    });
    _scrollToBottom();

    _controller.clear();

    if (text.toLowerCase().contains('find doctor') || text.toLowerCase().contains('show doctors')) {
      _showDoctorDialog();
      setState(() {
        _messages.add({
          "role": "bot", 
          "text": "👨‍⚕️ I've opened the doctor finder for you. Please select a doctor from the list to book an appointment.\n\nYou can also describe your symptoms and I'll recommend the right specialist!",
          "timestamp": DateTime.now(),
          "originalText": "👨‍⚕️ I've opened the doctor finder for you. Please select a doctor from the list to book an appointment.\n\nYou can also describe your symptoms and I'll recommend the right specialist!"
        });
        _isThinking = false;
      });
      _scrollToBottom();
      return;
    }

    final aiResponse = await _getAIResponse(text);

    setState(() {
      _messages.add({
        "role": "bot", 
        "text": aiResponse, 
        "timestamp": DateTime.now(),
        "originalText": aiResponse
      });
      _isThinking = false;
    });
    _scrollToBottom();

    _speak(aiResponse);
    await _saveChat();

    // Show doctor recommendations based on symptoms
    if (text.length > 10 && !text.toLowerCase().contains('hello') && !text.toLowerCase().contains('hi')) {
      await Future.delayed(const Duration(milliseconds: 800));
      _showDoctorRecommendations(text);
    }
  }

  void _submitQuestionnaire() {
    String symptoms = questions
        .where((e) => e['selected'] == true)
        .map((e) => e['q'])
        .join(", ");
    
    setState(() => showQuestionnaire = false);

    if (symptoms.isEmpty) {
      _sendMessage("I have no symptoms to report");
    } else {
      _sendMessage(symptoms);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.cyan, Colors.lightBlue],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.shade300,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome, 
                          color: Colors.white, 
                          size: isSmallScreen ? 16 : 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isSmallScreen)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "AI Symptom Checker",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Healthcare Assistant',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      if (isSmallScreen)
                        Text(
                          "AI Checker",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.language, 
                                color: Colors.white, 
                                size: isSmallScreen ? 18 : 20,
                              ),
                              onSelected: (value) => setState(() => _selectedLanguage = value),
                              itemBuilder: (context) => _languages.entries.map((lang) {
                                return PopupMenuItem(
                                  value: lang.key,
                                  child: Row(
                                    children: [
                                      Text(lang.value),
                                      if (_selectedLanguage == lang.key) 
                                        const Icon(Icons.check, color: Colors.green, size: 16),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.calendar_today, 
                                color: Colors.white, 
                                size: isSmallScreen ? 18 : 20,
                              ),
                              onPressed: _showAppointmentsDialog,
                              tooltip: 'My Appointments',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.delete_outline, 
                                color: Colors.white, 
                                size: isSmallScreen ? 18 : 20,
                              ),
                              onPressed: () async {
                                _messages.clear();
                                _suggestedDoctors.clear();
                                _selectedDoctor = null;
                                setState(() {});
                                final prefs = await SharedPreferences.getInstance();
                                prefs.remove("chat_history_${widget.userId}");
                                _addWelcomeMessage();
                                _showSnackBar('Chat history cleared');
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (showQuestionnaire && widget.userType == 'patient')
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          "Quick Health Check",
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...questions.map((q) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: CheckboxListTile(
                        value: q["selected"],
                        onChanged: (v) => setState(() => q["selected"] = v),
                        title: Text(q["q"]),
                        secondary: Icon(q["icon"], color: Colors.blue.shade400),
                        activeColor: Colors.blue,
                      ),
                    )),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _submitQuestionnaire,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Check Symptoms"),
                    )
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length + (_isThinking ? 1 : 0),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                  top: 8,
                ),
                itemBuilder: (context, i) {
                  if (i == _messages.length && _isThinking) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('AI is analyzing your symptoms...'),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final msg = _messages[i];
                  final isUser = msg["role"] == "user";
                  final hasTranslation = msg['translatedText'] != null;
                  final timestamp = msg["timestamp"] as DateTime?;
                  
                  return GestureDetector(
                    onLongPress: () => _showTranslationDialog(msg, i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: isUser
                                ? LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                  )
                                : LinearGradient(
                                    colors: [Colors.grey.shade100, Colors.grey.shade50],
                                  ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MarkdownBody(
                                data: hasTranslation ? msg['translatedText'] : msg["text"] ?? "",
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    color: isUser ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                  ),
                                  strong: TextStyle(
                                    color: isUser ? Colors.white : Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (hasTranslation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isUser ? Colors.white24 : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Original:',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isUser ? Colors.white70 : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          msg['text'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: isUser ? Colors.white70 : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (timestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat('HH:mm').format(timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isUser ? Colors.white70 : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Doctor Recommendations Section - Fixed bottom overlay issue
            if (_suggestedDoctors.isNotEmpty)
              Container(
                height: 380,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade400, Colors.teal.shade400],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.medical_services, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "👨‍⚕️ Recommended Doctors",
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Based on your symptoms",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedDoctor != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Selected",
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 0),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _suggestedDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _suggestedDoctors[index];
                          final isSelected = _selectedDoctor != null && _selectedDoctor!['id'] == doctor['id'];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              elevation: isSelected ? 4 : 1,
                              color: isSelected ? Colors.green.shade50 : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isSelected ? BorderSide(color: Colors.green.shade400, width: 2) : BorderSide.none,
                              ),
                              child: InkWell(
                                onTap: () => setState(() => _selectedDoctor = doctor),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isSelected 
                                                ? [Colors.green.shade400, Colors.teal.shade400]
                                                : [Colors.blue.shade400, Colors.indigo.shade400],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: CircleAvatar(
                                          backgroundColor: Colors.transparent,
                                          radius: 25,
                                          child: Text(
                                            doctor['name'][0],
                                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    "Dr. ${doctor['name']}",
                                                    style: TextStyle(
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                      fontSize: isSmallScreen ? 12 : 14,
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                                                    const SizedBox(width: 2),
                                                    Text(" ${doctor['rating']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isSelected ? Colors.green.shade100 : Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                (doctor['specification'] != null && doctor['specification'].isNotEmpty)
                                                    ? doctor['specification'].toString().toUpperCase()
                                                    : doctor['specialization'].toString().toUpperCase(),
                                                style: TextStyle(
                                                  color: isSelected ? Colors.green.shade700 : Colors.blue.shade700,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${doctor['openHour']} - ${doctor['closeHour']}",
                                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    doctor['address'],
                                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_circle, color: Colors.green, size: 30)
                                      else
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Colors.blue, Colors.indigo],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () => setState(() => _selectedDoctor = doctor),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            ),
                                            child: Text(
                                              "Select", 
                                              style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_selectedDoctor != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final symptoms = _messages.lastWhere(
                              (msg) => msg["role"] == "user",
                              orElse: () => {"text": "General consultation"},
                            )["text"];
                            _bookAppointment(context, _selectedDoctor!, symptoms);
                            setState(() {
                              _suggestedDoctors = [];
                              _selectedDoctor = null;
                            });
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            "Book Appointment",
                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
            // Loading Indicator
            if (_loadingDoctors)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Finding doctors near you...'),
                  ],
                ),
              ),

            // Input Container - Fixed to bottom
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: isSmallScreen ? "Describe symptoms..." : "Describe your symptoms...",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () => _controller.clear(),
                                )
                              : null,
                        ),
                        onSubmitted: (text) => _sendMessage(text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isListening 
                                ? [Colors.red.shade400, Colors.red.shade600]
                                : [Colors.blue.shade400, Colors.blue.shade600],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                          onPressed: _startListening,
                          iconSize: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      if (_isListening)
                        SizedBox(
                          width: isSmallScreen ? 45 : 55,
                          height: isSmallScreen ? 45 : 55,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(_controller.text),
                      iconSize: isSmallScreen ? 20 : 24,
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
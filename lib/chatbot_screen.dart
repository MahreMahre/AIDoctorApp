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


class ChatScreen extends StatefulWidget {
  final String userId;
  final String userType; // 'patient' or 'doctor' or 'nurse'
  
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

  final List<Map<String, dynamic>> _messages = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isTranslating = false;
  String _selectedLanguage = 'en';
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
    {"q": "Do you have fever?", "selected": false},
    {"q": "Do you have headache?", "selected": false},
    {"q": "Do you have cough or cold?", "selected": false},
    {"q": "Do you feel body pain or fatigue?", "selected": false},
  ];

  // Doctor suggestions
  List<Map<String, dynamic>> _suggestedDoctors = [];
  bool _loadingDoctors = false;
  Map<String, dynamic>? _selectedDoctor;
  
  // Appointments
  List<Map<String, dynamic>> _userAppointments = [];
  bool _loadingAppointments = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadChat();
    _loadUserAppointments();
    _messages.add({
      "role": "bot",
      "text": "👋 Hi! I am your Symptom Checker Assistant. I can understand voice commands and translate messages. How can I help you today?",
      "timestamp": DateTime.now(),
      "originalText": "👋 Hi! I am your Symptom Checker Assistant. I can understand voice commands and translate messages. How can I help you today?"
    });
  }

  // ---------------- SPEECH TO TEXT INIT ----------------
  void _initSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'notListening' && _isListening) {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        print('Speech error: $error');
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech error: $error')),
        );
      },
    );
    
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  // ---------------- VOICE INPUT ----------------
  void _startListening() async {
    if (!_speech.isAvailable) {
      _initSpeech();
    }
    
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _isListening = false;
            if (result.finalResult) {
              _controller.text = result.recognizedWords;
              _sendMessage(_controller.text);
              _controller.clear();
            }
          });
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'en_US',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _stopListening() {
    if (_speech.isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Translate Message',
              style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Original: ${message['text']}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            const Text('Select Language:'),
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
    await _tts.setLanguage(_selectedLanguage);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  // ---------------- CHAT SAVE ----------------
  Future<void> _loadChat() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("chat_history_${widget.userId}");
    if (data != null) {
      _messages.addAll(List<Map<String, dynamic>>.from(json.decode(data)));
      setState(() {});
    }
  }

  Future<void> _saveChat() async {
    final prefs = await SharedPreferences.getInstance();
    // Save only necessary fields
    final saveMessages = _messages.map((msg) {
      return {
        'role': msg['role'],
        'text': msg['text'],
        'timestamp': msg['timestamp']?.toIso8601String(),
        'originalText': msg['originalText'],
      };
    }).toList();
    prefs.setString("chat_history_${widget.userId}", json.encode(saveMessages));
  }

  // ---------------- LOAD USER APPOINTMENTS ----------------
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

  // ---------------- FETCH DOCTORS FROM FIREBASE ----------------
  Future<void> _fetchAndSuggestDoctors(String symptoms) async {
    setState(() => _loadingDoctors = true);

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
          'rating': data['rating'] ?? 4.0,
          'email': data['email'] ?? 'N/A',
          'openHour': data['openHour'] ?? '09:00',
          'closeHour': data['closeHour'] ?? '21:00',
          'address': data['address'] ?? 'Address not specified',
          'bio': data['bio'] ?? 'Experienced doctor',
          'phone': data['phone'] ?? 'Not available',
          'profilePhoto': data['profilePhoto'] ?? '',
        };
      }).toList();

      // Advanced matching logic with priority scoring
      final lowerSymptoms = symptoms.toLowerCase();
      final List<Map<String, dynamic>> matchedDoctors = [];
      
      for (var doc in allDoctors) {
        int priorityScore = 0;
        final spec = doc['specialization'] as String;
        
        if (lowerSymptoms.contains('fever') && (spec.contains('general') || spec.contains('physician'))) {
          priorityScore += 3;
        }
        if (lowerSymptoms.contains('headache') && (spec.contains('neurologist') || spec.contains('general'))) {
          priorityScore += 3;
        }
        if ((lowerSymptoms.contains('cough') || lowerSymptoms.contains('cold')) && (spec.contains('ent') || spec.contains('pulmonologist') || spec.contains('general'))) {
          priorityScore += 3;
        }
        if ((lowerSymptoms.contains('pain') || lowerSymptoms.contains('fatigue')) && (spec.contains('orthopedic') || spec.contains('general') || spec.contains('rheumatologist'))) {
          priorityScore += 2;
        }
        if (lowerSymptoms.contains('stomach') && (spec.contains('gastroenterologist') || spec.contains('general'))) {
          priorityScore += 3;
        }
        if (lowerSymptoms.contains('breath') && (spec.contains('pulmonologist') || spec.contains('cardiologist'))) {
          priorityScore += 4;
        }
        
        if (priorityScore > 0) {
          doc['priorityScore'] = priorityScore;
          matchedDoctors.add(doc);
        }
      }
      
      // Sort by priority score (highest first)
      matchedDoctors.sort((a, b) => (b['priorityScore'] ?? 0).compareTo(a['priorityScore'] ?? 0));
      
      setState(() {
        _suggestedDoctors = matchedDoctors.isNotEmpty ? matchedDoctors : allDoctors.take(5).toList();
        _selectedDoctor = null;
      });
      
      // Add bot message about doctor suggestions
      if (_suggestedDoctors.isNotEmpty) {
        final doctorListMessage = "👨‍⚕️ Based on your symptoms, I've found ${_suggestedDoctors.length} doctor(s) who can help you.\n\nPlease select a doctor from the list below to view their details and book an appointment.";
        _addBotMessage(doctorListMessage);
      }
    } catch (e) {
      setState(() {
        _suggestedDoctors = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching doctors: $e')),
      );
    } finally {
      setState(() => _loadingDoctors = false);
    }
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
  }

  // ---------------- BOOK APPOINTMENT ----------------
  Future<void> _bookAppointment(BuildContext context, Map<String, dynamic> doctor, String symptoms) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    
    // Date picker
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date == null) return;
    selectedDate = date;
    
    // Time picker
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time == null) return;
    selectedTime = time;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final appointmentData = {
        'patientId': widget.userId,
        'doctorId': doctor['id'],
        'doctorName': doctor['name'],
        'patientName': await _getUserName(widget.userId),
        'appointmentDate': Timestamp.fromDate(selectedDate),
        'appointmentTime': '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
        'symptoms': symptoms,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'notes': '',
      };
      
      await FirebaseFirestore.instance.collection('Appointments').add(appointmentData);
      
      // Add to local list
      setState(() {
        _userAppointments.add({
          'id': 'temp',
          'doctorId': doctor['id'],
          'doctorName': doctor['name'],
          'appointmentDate': selectedDate,
          'appointmentTime': '${selectedTime?.hour.toString().padLeft(2, '0')}:${selectedTime?.minute.toString().padLeft(2, '0')}',
          'status': 'pending',
          'symptoms': symptoms,
        });
      });
      
      Navigator.pop(context); // Close loading dialog
      
      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Appointment Booked Successfully!'),
              const SizedBox(height: 16),
              Text('Dr. ${doctor['name']}'),
              Text('Date: ${DateFormat('MMM dd, yyyy').format(selectedDate!)}'),
              Text('Time: ${selectedTime?.format(context)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
      // Add confirmation to chat
      _addBotMessage("✅ Your appointment with Dr. ${doctor['name']} has been booked for ${DateFormat('MMM dd, yyyy').format(selectedDate)} at ${selectedTime.format(context)}.\n\nYou can view all your appointments in the My Appointments section.");
      
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e')),
      );
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

  // ---------------- CANCEL APPOINTMENT ----------------
  Future<void> _cancelAppointment(String appointmentId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              
              try {
                await FirebaseFirestore.instance.collection('Appointments').doc(appointmentId).update({
                  'status': 'cancelled',
                  'cancelledAt': Timestamp.now(),
                });
                
                await _loadUserAppointments();
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled successfully')),
                );
                
                _addBotMessage("Your appointment has been cancelled. Would you like to book another one?");
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error cancelling appointment: $e')),
                );
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  // ---------------- SYMPTOM LOGIC ----------------
  String getSymptomResponse(String text) {
    text = text.toLowerCase();
    String response = "❗ I couldn't identify exact symptoms.\nPlease describe more clearly.";

    if (text.contains("high fever") || text.contains("very hot") || text.contains("103")) {
      response = "⚠️ Possible: Severe Fever / Infection\n\nAdvice:\n- Take paracetamol\n- Drink fluids\n- Visit doctor if >3 days";
    } else if (text.contains("fever") || text.contains("temperature")) {
      response = "🤒 Possible: Viral Fever\n\nAdvice:\n- Rest\n- Hydration\n- Paracetamol if needed";
    } else if (text.contains("headache") || text.contains("head pain")) {
      response = "🤕 Possible: Stress / Migraine\n\nAdvice:\n- Rest in dark room\n- Drink water\n- Reduce screen time";
    } else if (text.contains("cough") || text.contains("cold")) {
      response = "🤧 Possible: Cold / Flu\n\nAdvice:\n- Warm fluids\n- Steam inhalation\n- Rest";
    } else if (text.contains("body pain") || text.contains("muscle pain")) {
      response = "💢 Possible: Viral infection / Fatigue\n\nAdvice:\n- Rest\n- Warm bath\n- Pain relief medicine";
    } else if (text.contains("stomach") || text.contains("abdominal pain")) {
      response = "🤢 Possible: Gas / Indigestion\n\nAdvice:\n- Light food\n- Avoid oily food\n- Drink warm water";
    } else if (text.contains("breath") || text.contains("breathing issue")) {
      response = "🚨 Possible: Respiratory issue\n\nAdvice:\n- Seek medical help immediately";
    } else if (text.contains("my appointments") || text.contains("view appointments")) {
      _showAppointmentsDialog();
      return "📅 Here are your upcoming appointments:";
    } else if (text.contains("translate") || text.contains("translation")) {
      return "🌐 To translate a message, tap on any message and select 'Translate' from the menu.";
    } else if (text.contains("voice") || text.contains("speak")) {
      return "🎤 You can use voice input by tapping the microphone button next to the text field. Just speak clearly and I'll convert your speech to text!";
    }

    // Fetch doctors after response
    if (!text.contains("appointment") && !text.contains("thank") && !text.contains("translate") && !text.contains("voice")) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchAndSuggestDoctors(text);
      });
    }

    return response;
  }
  
  void _showAppointmentsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'My Appointments',
                    style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: _loadingAppointments
                    ? const Center(child: CircularProgressIndicator())
                    : _userAppointments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No appointments found',
                                  style: GoogleFonts.lato(fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Book your first appointment by selecting a doctor',
                                  style: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _userAppointments.length,
                            itemBuilder: (context, index) {
                              final appointment = _userAppointments[index];
                              final statusColor = appointment['status'] == 'pending' 
                                  ? Colors.orange 
                                  : appointment['status'] == 'confirmed'
                                  ? Colors.green
                                  : Colors.red;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: statusColor.withOpacity(0.2),
                                    child: Icon(
                                      appointment['status'] == 'pending' 
                                          ? Icons.pending
                                          : appointment['status'] == 'confirmed'
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: statusColor,
                                    ),
                                  ),
                                  title: Text(
                                    'Dr. ${appointment['doctorName']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Date: ${DateFormat('MMM dd, yyyy').format(appointment['appointmentDate'].toDate())}'),
                                      Text('Time: ${appointment['appointmentTime']}'),
                                      Text('Status: ${appointment['status'].toString().toUpperCase()}'),
                                      if (appointment['symptoms'] != null)
                                        Text('Symptoms: ${appointment['symptoms']}'),
                                    ],
                                  ),
                                  trailing: appointment['status'] == 'pending'
                                      ? TextButton(
                                          onPressed: () => _cancelAppointment(appointment['id']),
                                          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
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
    });

    _controller.clear();

    final response = getSymptomResponse(text);

    setState(() {
      _messages.add({
        "role": "bot", 
        "text": response, 
        "timestamp": DateTime.now(),
        "originalText": response
      });
    });

    _speak(response);
    await _saveChat();
  }

  // ---------------- QUESTIONNAIRE ----------------
  void _submitQuestionnaire() {
    String symptoms = questions
        .where((e) => e['selected'] == true)
        .map((e) => e['q'])
        .join(", ");
    
    setState(() => showQuestionnaire = false);

    if (symptoms.isEmpty) {
      _sendMessage("I have no symptoms to report");
    } else {
      _sendMessage("Symptom Report: $symptoms");
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Symptom Checker"),
        backgroundColor: Colors.blue.shade200,
        actions: [
          // Language selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (value) {
              setState(() => _selectedLanguage = value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language changed to ${_languages[value]}')),
              );
            },
            itemBuilder: (context) => _languages.entries.map((lang) {
              return PopupMenuItem(
                value: lang.key,
                child: Row(
                  children: [
                    Text(lang.value),
                    if (_selectedLanguage == lang.key)
                      const Icon(Icons.check, color: Colors.green),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showAppointmentsDialog,
            tooltip: 'My Appointments',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              _messages.clear();
              _suggestedDoctors.clear();
              _selectedDoctor = null;
              setState(() {});
              final prefs = await SharedPreferences.getInstance();
              prefs.remove("chat_history_${widget.userId}");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared')),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Info banner for voice and translation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.blue.shade100,
            child: Row(
              children: [
                const Icon(Icons.info, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🎤 Tap microphone to speak | 🌐 Long press message to translate',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          
          // Questionnaire
          if (showQuestionnaire && widget.userType == 'patient')
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🩺 Quick Health Check",
                    style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Check Symptoms"),
                  )
                ],
              ),
            ),

          // Chat
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isUser = msg["role"] == "user";
                final hasTranslation = msg['translatedText'] != null;
                
                return GestureDetector(
                  onLongPress: () => _showTranslationDialog(msg, i),
                  child: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarkdownBody(data: hasTranslation ? msg['translatedText'] : msg["text"] ?? ""),
                          if (hasTranslation)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Original:',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                    ),
                                    Text(
                                      msg['text'],
                                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (msg["timestamp"] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                DateFormat('HH:mm').format(msg["timestamp"]),
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Doctor Suggestions Section
          if (_suggestedDoctors.isNotEmpty || _loadingDoctors)
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              padding: const EdgeInsets.all(12),
              color: Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        "👨‍⚕️ Suggested Doctors",
                        style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_selectedDoctor != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Selected: Dr. ${_selectedDoctor!['name']}",
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loadingDoctors)
                    const Center(child: CircularProgressIndicator()),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestedDoctors.length,
                      itemBuilder: (context, index) {
                        final doctor = _suggestedDoctors[index];
                        final isSelected = _selectedDoctor != null && _selectedDoctor!['id'] == doctor['id'];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          color: isSelected ? Colors.green.shade100 : Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Colors.green : Colors.blue,
                              child: Text(
                                doctor['name'][0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Dr. ${doctor['name']}",
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.star, size: 16, color: Colors.amber),
                                    Text(" ${doctor['rating']}"),
                                  ],
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor['specialization'].toString().toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "🕐 ${doctor['openHour']} - ${doctor['closeHour']}",
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  "📍 ${doctor['address']}",
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : ElevatedButton(
                                    onPressed: () => setState(() => _selectedDoctor = doctor),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    child: const Text("Select"),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_selectedDoctor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final symptoms = _messages.lastWhere(
                            (msg) => msg["role"] == "user",
                            orElse: () => {"text": "General consultation"},
                          )["text"];
                          _bookAppointment(context, _selectedDoctor!, symptoms);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text("Book Appointment"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Input with voice button
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: widget.userType == 'patient' 
                          ? "Type or tap microphone to speak..."
                          : "Type your message...",
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Voice input button
                Container(
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                    onPressed: _isListening ? _stopListening : _startListening,
                    tooltip: _isListening ? 'Stop listening' : 'Start voice input',
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _sendMessage(_controller.text),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
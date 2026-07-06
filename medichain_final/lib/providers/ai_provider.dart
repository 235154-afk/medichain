// lib/providers/ai_provider.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  // Gemini API key — replace with your own (free at aistudio.google.com)
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static const String _systemContext = '''
You are MediBot, an AI assistant for MediChain — a blockchain-based medicine
authenticity and cold-chain tracker for Pakistan. You help users:
1. Understand if a medicine is authentic or counterfeit
2. Explain cold-chain temperature requirements for different medicines
3. Guide users on how to verify medicine batches on blockchain
4. Explain what blockchain verification means
5. Advice on spotting fake medicines
6. Explain supply chain steps
7. Answer general medicine storage questions

Cold-chain requirements:
- Insulin: 2C to 8C (refrigerated)
- Vaccines: 2C to 8C
- Most tablets: 15C to 25C
- Biologics: 2C to 8C

Always respond helpfully and clearly. Keep answers concise and practical.
''';

  AiProvider() {
    _messages.add(ChatMessage(
      text:
          "Hi! I am MediBot, your AI medicine safety assistant.\n\nI can help you:\n• Verify medicine authenticity\n• Understand cold-chain requirements\n• Spot fake medicines\n• Navigate MediChain features\n\nHow can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    _messages.add(ChatMessage(
      text: userText.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isTyping = true;
    notifyListeners();

    try {
      final response = await _callGemini(userText.trim());
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      final localResp = _localAiResponse(userText.trim());
      _messages.add(ChatMessage(
        text: localResp,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }

    _isTyping = false;
    notifyListeners();
  }

  Future<String> _callGemini(String userText) async {
    final response = await http.post(
      Uri.parse('$_apiUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    '$_systemContext\n\nUser: $userText\n\nMediBot:'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 500,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }

  String _localAiResponse(String query) {
    final q = query.toLowerCase();

    if (q.contains('insulin')) {
      return 'Insulin Cold Chain:\n\nInsulin must be stored at 2C to 8C (refrigerated).\n\n• Never freeze insulin\n• Once opened, keep at room temp below 25C for max 28 days\n• Discard if exposed above 30C\n\nOn MediChain, check the temperature logs — any red entries mean cold chain was broken.';
    }
    if (q.contains('fake') || q.contains('counterfeit') || q.contains('authentic')) {
      return 'How to Spot Fake Medicines:\n\n• Batch number should match MediChain record\n• Check manufacturer name and DRAP license\n• Expiry date must be clear, not smudged\n• Packaging quality and spelling\n• Seal must be intact\n\nOn MediChain scan:\n• Green = Verified authentic\n• Red = Not found or Recalled\n• Yellow = Cold chain breach\n\nIf in doubt, do NOT use the medicine. Report to DRAP: 0800-03727';
    }
    if (q.contains('verify') || q.contains('scan') || q.contains('check')) {
      return 'How to Verify a Medicine:\n\n1. Tap Scan QR on home screen\n2. Scan QR code on medicine box\n3. OR type batch number manually\n4. MediChain checks Ethereum blockchain\n5. You will see:\n   • Manufacturer details\n   • Full supply chain journey\n   • Temperature log history\n   • Expiry date\n\nThe history is permanent and cannot be faked!';
    }
    if (q.contains('vaccine')) {
      return 'Vaccine Cold Chain:\n\nMost vaccines require 2C to 8C storage.\n\n• Polio OPV: -20C or 2-8C\n• BCG: 2C to 8C\n• Hepatitis B: 2C to 8C, never freeze\n\nMediChain records every temperature reading so you can see if your vaccine was stored correctly throughout its journey.';
    }
    if (q.contains('blockchain') || q.contains('how does') || q.contains('what is')) {
      return 'How MediChain Blockchain Works:\n\nThink of blockchain as a permanent public notebook nobody can erase:\n\n1. Manufacturer registers medicine batch — gets unique ID\n2. Distributor receives it and signs on blockchain\n3. Pharmacy receives it and signs on blockchain\n4. You scan and see complete journey\n\nBecause it is on Ethereum:\n• Nobody can delete or change records\n• Every step is permanent\n• Anyone can verify anywhere\n\nFake medicines cannot be added because only verified licensed actors can register batches.';
    }
    if (q.contains('temperature') || q.contains('temp') || q.contains('cold')) {
      return 'Medicine Temperature Guide:\n\nInsulin and Vaccines: 2C to 8C\nMost Tablets: 15C to 25C\nBiologics: 2C to 8C\nSuppositories: Below 25C\n\nOn MediChain temp logs:\n• Green = Normal, safe range\n• Yellow = Warning, slight breach\n• Red = Critical, serious breach\n\nIf you see red logs, consult your pharmacist before using.';
    }
    if (q.contains('drap') || q.contains('pakistan')) {
      return 'DRAP and Pakistan Medicine Regulations:\n\nDRAP (Drug Regulatory Authority of Pakistan) registers all legitimate medicines.\n\nEvery authentic medicine should have:\n• DRAP registration number\n• Licensed manufacturer\n• Batch number matching MediChain record\n\nReport fake medicines:\n• DRAP Helpline: 0800-03727\n• Website: drap.gov.pk\n\nMediChain works alongside DRAP — regulators can audit the entire supply chain in real time.';
    }
    if (q.contains('hello') || q.contains('hi') || q.contains('help')) {
      return 'Hello! How can I help you?\n\nI can assist with:\n\n• Verify medicine — how to scan\n• Temperature — cold chain requirements\n• Fake medicines — how to spot them\n• Blockchain — how MediChain works\n• DRAP — Pakistani medicine regulations\n\nJust ask me anything about medicine safety!';
    }

    return 'I understand you are asking about "$query".\n\nMediChain helps verify medicine authenticity through blockchain. Every registered medicine batch has:\n• A unique batch ID on Ethereum\n• Complete supply chain history\n• Temperature logs\n• Expiry date verification\n\nTo verify a specific medicine, tap Scan QR on the home screen and scan the QR code on your medicine package.\n\nAsk me about temperature requirements, fake medicine signs, or how our blockchain system works!';
  }

  List<String> get quickSuggestions => [
        'How to verify a medicine?',
        'Insulin cold chain temp?',
        'How to spot fake medicines?',
        'What is blockchain verification?',
        'Vaccine storage requirements',
        'Report fake medicine in Pakistan',
      ];

  void clearChat() {
    _messages.clear();
    _messages.add(ChatMessage(
      text: 'Chat cleared. How can I help you with medicine safety?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}

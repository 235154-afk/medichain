// lib/providers/ai_provider.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool   isUser;
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

  List<ChatMessage> get messages  => _messages;
  bool              get isTyping  => _isTyping;

  // Gemini API key — replace with your own (free tier available)
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static const String _systemContext = '''
You are MediBot, an AI assistant for MediChain — a blockchain-based medicine 
authenticity and cold-chain tracker for Pakistan. You help users:

1. Understand if a medicine is authentic or counterfeit
2. Explain cold-chain temperature requirements for different medicines
3. Guide users on how to verify medicine batches
4. Explain blockchain verification and what it means
5. Give advice on spotting fake medicines
6. Explain supply chain steps (manufacturer → distributor → pharmacy)
7. Answer general medicine storage and handling questions

Common Pakistani medicines and their cold-chain requirements:
- Insulin: 2°C to 8°C (refrigerated) — very sensitive
- Vaccines (most): 2°C to 8°C
- Biologics: 2°C to 8°C 
- Most tablets/capsules: 15°C to 25°C (room temperature)
- Some antibiotics: 15°C to 25°C

Red flags for fake medicines in Pakistan:
- No batch number or blurred batch number
- Price too low compared to market
- Packaging quality poor, spelling mistakes
- No manufacturer address or DRAP license
- QR code does not scan or gives wrong info
- Medicine color/smell different from usual

Always respond in a helpful, clear way. If asked in Urdu or mix of English/Urdu, 
respond in simple English. Keep answers concise and practical for common people.
''';

  AiProvider() {
    // Add welcome message
    _messages.add(const ChatMessage(
      text: "👋 Hello! I'm MediBot, your AI medicine safety assistant.\n\nI can help you:\n• Verify medicine authenticity\n• Understand cold-chain requirements\n• Spot fake medicines\n• Navigate MediChain features\n\nHow can I help you today?",
      isUser: false,
      timestamp: Duration(seconds: 0) as DateTime,
    ));
    // fix: proper init
    _messages.clear();
    _messages.add(ChatMessage(
      text: "👋 Hello! I'm MediBot, your AI medicine safety assistant.\n\nI can help you:\n• Verify medicine authenticity\n• Understand cold-chain requirements\n• Spot fake medicines\n• Navigate MediChain features\n\nHow can I help you today?",
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
      // Fallback to local AI responses when API unavailable
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
              {'text': '$_systemContext\n\nUser: $userText\n\nMediBot:'}
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

  // Local AI for offline / no API key scenarios
  String _localAiResponse(String query) {
    final q = query.toLowerCase();

    if (q.contains('insulin') || q.contains('insulin')) {
      return '🌡️ **Insulin Cold Chain Requirements**\n\nInsulin must be stored at **2°C to 8°C** (refrigerated).\n\n• Never freeze insulin\n• Once opened, can be kept at room temp (below 25°C) for up to 28 days\n• Discard if exposed to temperature above 30°C\n\nOn MediChain, check the temperature logs tab — any red ⚠️ entries mean the cold chain was broken.';
    }

    if (q.contains('fake') || q.contains('counterfeit') || q.contains('authentic')) {
      return '🔍 **How to Spot Fake Medicines**\n\n**Check these on the physical package:**\n• Batch number — should match MediChain record\n• Manufacturer name and DRAP license\n• Expiry date — clear, not smudged\n• Packaging quality and spelling\n• Seal intact\n\n**On MediChain scan:**\n• ✅ Green = Verified authentic\n• ❌ Red = Not found / Recalled\n• ⚠️ Yellow = Cold chain breach detected\n\nIf in doubt, do NOT use the medicine and report to DRAP.';
    }

    if (q.contains('verify') || q.contains('scan') || q.contains('check')) {
      return '📱 **How to Verify a Medicine**\n\n1. Tap **Scan QR** on the home screen\n2. Scan the QR code on the medicine box\n3. OR type the batch number manually\n4. MediChain checks the Ethereum blockchain\n5. You\'ll see:\n   • ✅ Manufacturer details\n   • 📦 Full supply chain journey\n   • 🌡️ Temperature log history\n   • ⏰ Expiry date\n\nThe entire history is permanent and cannot be faked!';
    }

    if (q.contains('vaccine') || q.contains('vaccine')) {
      return '💉 **Vaccine Cold Chain**\n\nMost vaccines require **2°C to 8°C** storage.\n\n• Polio (OPV): Can be stored at -20°C or 2-8°C\n• BCG: 2°C to 8°C\n• Hepatitis B: 2°C to 8°C — never freeze\n\nIn Pakistan, vaccine cold chain failures are a major problem. MediChain records every temperature reading so you can see if your vaccine was stored correctly throughout its journey.';
    }

    if (q.contains('blockchain') || q.contains('how does') || q.contains('what is')) {
      return '⛓️ **How MediChain Blockchain Works**\n\nThink of blockchain as a permanent, public notebook that nobody can erase:\n\n1. **Manufacturer** registers the medicine batch — gets a unique ID\n2. **Distributor** receives it and signs on blockchain\n3. **Pharmacy** receives it and signs on blockchain\n4. **You** scan and see the complete journey\n\nBecause it\'s on Ethereum blockchain:\n• ❌ Nobody can delete or change records\n• ✅ Every step is permanent\n• 🌍 Anyone can verify anywhere\n\nFake medicines cannot be added because only verified, licensed actors can register batches.';
    }

    if (q.contains('temperature') || q.contains('temp') || q.contains('cold')) {
      return '🌡️ **Medicine Temperature Guide**\n\n| Type | Temp Range |\n|------|------------|\n| Insulin / Vaccines | 2°C – 8°C |\n| Biologics | 2°C – 8°C |\n| Most tablets | 15°C – 25°C |\n| Some antibiotics | 15°C – 25°C |\n| Suppositories | Below 25°C |\n\n**On MediChain temp logs:**\n• 🟢 Normal — safe range\n• 🟡 Warning — slight breach\n• 🔴 Critical — serious breach, use caution\n\nIf you see red logs, consult your pharmacist before using.';
    }

    if (q.contains('drap') || q.contains('license') || q.contains('pakistan')) {
      return '🇵🇰 **DRAP & Pakistan Medicine Regulations**\n\nDRAP (Drug Regulatory Authority of Pakistan) registers all legitimate medicines.\n\n**Every authentic medicine should have:**\n• DRAP registration number\n• Licensed manufacturer\n• Batch number matching MediChain record\n\n**Report fake medicines to:**\n• DRAP Helpline: 0800-03727\n• Website: drap.gov.pk\n\nMediChain works alongside DRAP — regulators can audit the entire supply chain in real time using our platform.';
    }

    if (q.contains('hello') || q.contains('hi') || q.contains('salaam') || q.contains('help')) {
      return '👋 **Hello! How can I help you?**\n\nI can assist with:\n\n🔍 **Verify medicine** — explain how to scan\n🌡️ **Temperature** — cold chain requirements\n💊 **Fake medicines** — how to spot them\n⛓️ **Blockchain** — how MediChain works\n🇵🇰 **DRAP** — Pakistani medicine regulations\n\nJust ask me anything about medicine safety!';
    }

    return '💊 I understand you\'re asking about **"$query"**.\n\nHere\'s what I can tell you:\n\nMediChain helps verify medicine authenticity through blockchain. Every registered medicine batch has:\n• A unique batch ID on Ethereum\n• Complete supply chain history\n• Temperature logs\n• Expiry date verification\n\nTo verify a specific medicine, tap **Scan QR** on the home screen and scan the QR code on your medicine package.\n\nNeed more specific help? Ask me about temperature requirements, fake medicine signs, or how our blockchain system works!';
  }

  // Quick suggestion chips
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
      text: "Chat cleared. How can I help you with medicine safety?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}

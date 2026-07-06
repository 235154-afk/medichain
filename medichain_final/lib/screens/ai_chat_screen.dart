// lib/screens/ai_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_widgets.dart';
import '../providers/ai_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _msgCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    context.read<AiProvider>().sendMessage(text);
    Future.delayed(const Duration(milliseconds: 400), _scrollBottom);
  }

  void _scrollBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    return Scaffold(
      backgroundColor: MC.bg,
      appBar: AppBar(
        backgroundColor: MC.card,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [MC.violet, MC.p]), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MediBot AI', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Medicine Safety Assistant', style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: MC.t2),
            onPressed: () => context.read<AiProvider>().clearChat(),
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(children: [
        // Suggestion chips
        if (ai.messages.length <= 1)
          _SuggestionChips(suggestions: ai.quickSuggestions, onTap: (s) {
            context.read<AiProvider>().sendMessage(s);
            Future.delayed(const Duration(milliseconds: 400), _scrollBottom);
          }),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: ai.messages.length + (ai.isTyping ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == ai.messages.length && ai.isTyping) return _TypingBubble();
              final msg = ai.messages[i];
              return _MsgBubble(message: msg, key: ValueKey(i));
            },
          ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MC.card,
            border: Border(top: BorderSide(color: MC.cyan.withOpacity(0.1))),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: GoogleFonts.inter(color: MC.t1, fontSize: 14),
                onSubmitted: (_) => _send(),
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Ask about medicine safety, cold chain...',
                  hintStyle: GoogleFonts.inter(color: MC.t3, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [MC.violet, MC.p]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MsgBubble extends StatelessWidget {
  final ChatMessage message;
  const _MsgBubble({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [MC.violet, MC.p]), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? const LinearGradient(colors: MC.gradP) : null,
                color: isUser ? null : MC.card2,
                borderRadius: BorderRadius.only(
                  topLeft:     Radius.circular(isUser ? 18 : 4),
                  topRight:    Radius.circular(isUser ? 4 : 18),
                  bottomLeft:  const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
                border: isUser ? null : Border.all(color: MC.cyan.withOpacity(0.1)),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  color: isUser ? Colors.white : MC.t1,
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: MC.p.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_rounded, color: MC.p, size: 16),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [MC.violet, MC.p]), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: MC.card2, borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4), topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
        )),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 7, height: 7,
            decoration: const BoxDecoration(color: MC.cyan, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).moveY(begin: 0, end: -6,
            duration: Duration(milliseconds: 400 + i * 100), curve: Curves.easeInOut),
        )),
      ),
    ],
  );
}

class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const _SuggestionChips({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      children: suggestions.map((s) => GestureDetector(
        onTap: () => onTap(s),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: MC.p.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: MC.p.withOpacity(0.3)),
          ),
          child: Text(s, style: GoogleFonts.inter(color: MC.p, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      )).toList(),
    ),
  );
}

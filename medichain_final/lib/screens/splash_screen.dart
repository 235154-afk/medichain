// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/shared_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MC.bg,
      body: Stack(children: [
        // Animated background particles
        ...List.generate(8, (i) => Positioned(
          left: (i * 47.3) % MediaQuery.of(context).size.width,
          top:  (i * 83.7) % MediaQuery.of(context).size.height,
          child: Container(
            width: 4 + (i % 3) * 3.0,
            height: 4 + (i % 3) * 3.0,
            decoration: BoxDecoration(
              color: [MC.p, MC.cyan, MC.violet][i % 3].withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: -20, duration: Duration(seconds: 2 + i), curve: Curves.easeInOut),
        )),

        // Center content
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Logo
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: MC.gradP, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: MC.p.withOpacity(0.4), blurRadius: 30, spreadRadius: -5)],
            ),
            child: const Icon(Icons.medication_liquid_rounded, color: Colors.white, size: 44),
          )
          .animate().scale(duration: 600.ms, curve: Curves.elasticOut)
          .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // App name
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: MC.gradC).createShader(b),
            child: Text('MediChain',
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1)),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

          const SizedBox(height: 10),
          Text('Medicine Authenticity on Blockchain',
            style: GoogleFonts.inter(color: MC.t2, fontSize: 15))
          .animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 60),

          // Loading indicator
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: MC.card2,
                valueColor: const AlwaysStoppedAnimation(MC.cyan),
                minHeight: 3,
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 16),
          Text('Connecting to Ethereum Sepolia...',
            style: GoogleFonts.inter(color: MC.t3, fontSize: 12))
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 800.ms),

          const SizedBox(height: 60),

          // Blockchain network badges
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _NetBadge(Icons.link_rounded, 'Ethereum'),
            const SizedBox(width: 12),
            _NetBadge(Icons.security_rounded, 'Sepolia'),
            const SizedBox(width: 12),
            _NetBadge(Icons.verified_rounded, 'Verified'),
          ]).animate().fadeIn(delay: 800.ms),
        ])),
      ]),
    );
  }
}

class _NetBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _NetBadge(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: MC.card,
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: MC.cyan.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: MC.cyan),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.inter(color: MC.t2, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

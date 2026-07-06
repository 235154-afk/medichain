import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/wallet_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/ai_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/register_batch_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/cold_chain_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/batch_detail_screen.dart';
import 'screens/actor_register_screen.dart';
import 'screens/recall_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MediChainApp());
}

class MediChainApp extends StatelessWidget {
  const MediChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
      ],
      child: MaterialApp.router(
        title: 'MediChain',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routerConfig: _router,
      ),
    );
  }

  ThemeData _buildTheme() {
    const bg       = Color(0xFF060B18);
    const card     = Color(0xFF0C1425);
    const card2    = Color(0xFF111D35);
    const primary  = Color(0xFF2563EB);
    const cyan     = Color(0xFF38BDF8);
    const violet   = Color(0xFF7C3AED);
    const success  = Color(0xFF10B981);
    const warning  = Color(0xFFF59E0B);
    const danger   = Color(0xFFEF4444);
    const text1    = Color(0xFFF0F6FF);
    const text2    = Color(0xFF94A3B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        background: bg,
        surface: card,
        primary: primary,
        secondary: cyan,
        tertiary: violet,
        error: danger,
        onPrimary: Colors.white,
        onBackground: text1,
        onSurface: text1,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge:  GoogleFonts.spaceGrotesk(color: text1, fontWeight: FontWeight.w700, fontSize: 32),
          displayMedium: GoogleFonts.spaceGrotesk(color: text1, fontWeight: FontWeight.w700, fontSize: 26),
          displaySmall:  GoogleFonts.spaceGrotesk(color: text1, fontWeight: FontWeight.w600, fontSize: 22),
          headlineLarge: GoogleFonts.spaceGrotesk(color: text1, fontWeight: FontWeight.w700, fontSize: 20),
          headlineMedium:GoogleFonts.spaceGrotesk(color: text1, fontWeight: FontWeight.w600, fontSize: 18),
          titleLarge:    GoogleFonts.spaceGrotesk(color: text1, fontWeight: FontWeight.w600, fontSize: 16),
          titleMedium:   GoogleFonts.inter(color: text1, fontWeight: FontWeight.w500, fontSize: 14),
          bodyLarge:     GoogleFonts.inter(color: text1, fontSize: 16),
          bodyMedium:    GoogleFonts.inter(color: text2, fontSize: 14),
          bodySmall:     GoogleFonts.inter(color: text2, fontSize: 12),
          labelLarge:    GoogleFonts.inter(color: text1, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: text1, fontWeight: FontWeight.w700, fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: text1),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cyan.withOpacity(0.12), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cyan.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cyan.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: text2, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: text2.withOpacity(0.6), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card2,
        contentTextStyle: GoogleFonts.inter(color: text1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/',        builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/home',    builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/scan',    builder: (c, s) => const ScanScreen()),
      GoRoute(path: '/verify',  builder: (c, s) => VerifyScreen(batchId: s.uri.queryParameters['id'] ?? '')),
      GoRoute(path: '/register-batch', builder: (c, s) => const RegisterBatchScreen()),
      GoRoute(path: '/transfer',       builder: (c, s) => const TransferScreen()),
      GoRoute(path: '/cold-chain',     builder: (c, s) => const ColdChainScreen()),
      GoRoute(path: '/dashboard',      builder: (c, s) => const DashboardScreen()),
      GoRoute(path: '/admin',          builder: (c, s) => const AdminScreen()),
      GoRoute(path: '/ai-chat',        builder: (c, s) => const AiChatScreen()),
      GoRoute(path: '/batch/:id',      builder: (c, s) => BatchDetailScreen(batchId: s.pathParameters['id'] ?? '0')),
      GoRoute(path: '/actor-register', builder: (c, s) => const ActorRegisterScreen()),
      GoRoute(path: '/recall',         builder: (c, s) => const RecallScreen()),
    ],
  );
}

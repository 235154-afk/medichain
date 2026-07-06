// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_widgets.dart';
import '../providers/wallet_provider.dart';
import '../providers/medicine_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIdx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallet = context.read<WalletProvider>();
      if (wallet.isConnected) {
        context.read<MedicineProvider>().loadAnalytics(wallet);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: MC.bg,
      appBar: _buildAppBar(wallet),
      body: _buildBody(wallet),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(WalletProvider wallet) => AppBar(
    backgroundColor: MC.card.withOpacity(0.95),
    elevation: 0,
    title: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: MC.gradP),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(Icons.medication_liquid_rounded, color: Colors.white, size: 17),
      ),
      const SizedBox(width: 9),
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(colors: MC.gradC).createShader(b),
        child: Text('MediChain',
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
      ),
    ]),
    actions: [
      // AI Chat button
      IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: MC.violet.withOpacity(0.15),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: MC.violet.withOpacity(0.3)),
          ),
          child: const Icon(Icons.smart_toy_rounded, color: MC.violet, size: 18),
        ),
        onPressed: () => context.push('/ai-chat'),
        tooltip: 'AI Assistant',
      ),
      // Wallet button
      GestureDetector(
        onTap: () => _showWalletSheet(context),
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: wallet.isConnected ? MC.g.withOpacity(0.12) : MC.p.withOpacity(0.12),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: wallet.isConnected ? MC.g.withOpacity(0.4) : MC.p.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(wallet.isConnected ? Icons.account_balance_wallet_rounded : Icons.wallet_rounded,
              size: 14, color: wallet.isConnected ? MC.g : MC.p),
            const SizedBox(width: 6),
            Text(wallet.isConnected ? wallet.shortAddress : 'Connect',
              style: GoogleFonts.inter(
                color: wallet.isConnected ? MC.g : MC.p,
                fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ],
  );

  Widget _buildBody(WalletProvider wallet) {
    return SingleChildScrollView(
      child: Column(children: [
        // Hero banner
        _HeroBanner(wallet: wallet),

        // Quick actions grid
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _QuickActions(),
            const SizedBox(height: 20),

            // Stats row
            if (wallet.isConnected) _StatsRow(),

            const SizedBox(height: 20),

            // How it works
            _HowItWorks(),

            const SizedBox(height: 20),

            // Recent features
            _FeatureCards(),

            const SizedBox(height: 100),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBottomNav() => Container(
    decoration: BoxDecoration(
      color: MC.card,
      border: Border(top: BorderSide(color: MC.cyan.withOpacity(0.1))),
    ),
    child: BottomNavigationBar(
      currentIndex: _navIdx,
      onTap: (i) {
        setState(() => _navIdx = i);
        const routes = ['/home', '/scan', '/dashboard', '/ai-chat'];
        context.go(routes[i]);
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: MC.cyan,
      unselectedItemColor: MC.t3,
      selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: 'AI Chat'),
      ],
    ),
  );

  Widget _buildFAB() => FloatingActionButton.extended(
    onPressed: () => context.push('/scan'),
    backgroundColor: MC.p,
    icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
    label: Text('Scan Medicine', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
  ).animate().scale(delay: 600.ms, curve: Curves.elasticOut);

  void _showWalletSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MC.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _WalletSheet(),
    );
  }
}

// ── HERO BANNER ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final WalletProvider wallet;
  const _HeroBanner({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MC.p.withOpacity(0.8), MC.violet.withOpacity(0.6)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MC.cyan.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text('Blockchain Powered', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 14),
        Text('Verify Medicine\nAuthenticity', style: GoogleFonts.spaceGrotesk(
          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.15)),
        const SizedBox(height: 8),
        Text('Scan any medicine QR code to\ninstantly verify on Ethereum blockchain.',
          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/scan'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: MC.p, size: 18),
                  const SizedBox(width: 8),
                  Text('Scan QR', style: GoogleFonts.inter(color: MC.p, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/verify?id='),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Search', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }
}

// ── QUICK ACTIONS ────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final List<_QAItem> items = const [
    _QAItem(icon: Icons.qr_code_scanner_rounded, label: 'Scan\nQR Code', route: '/scan', colors: MC.gradP),
    _QAItem(icon: Icons.search_rounded,           label: 'Search\nBatch',  route: '/verify?id=', colors: MC.gradC),
    _QAItem(icon: Icons.thermostat_rounded,       label: 'Cold\nChain',    route: '/cold-chain', colors: MC.gradG),
    _QAItem(icon: Icons.admin_panel_settings_rounded, label: 'Admin\nPanel', route: '/admin', colors: MC.gradO),
    _QAItem(icon: Icons.add_box_rounded,          label: 'Register\nBatch', route: '/register-batch', colors: [MC.violet, MC.p]),
    _QAItem(icon: Icons.swap_horiz_rounded,       label: 'Transfer\nBatch', route: '/transfer', colors: [MC.cyan, MC.g]),
  ];

  const _QuickActions();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Quick Actions', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: items.asMap().map((i, item) => MapEntry(i,
          GestureDetector(
            onTap: () => context.push(item.route),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: item.colors),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 10),
                Text(item.label, style: GoogleFonts.inter(color: MC.t1, fontSize: 11, fontWeight: FontWeight.w500, height: 1.3),
                  textAlign: TextAlign.center, maxLines: 2),
              ]),
            ),
          ).animate(delay: Duration(milliseconds: 100 * i)).fadeIn().scale(begin: const Offset(0.8, 0.8)),
        )).values.toList(),
      ),
    ],
  );
}

class _QAItem {
  final IconData icon;
  final String label;
  final String route;
  final List<Color> colors;
  const _QAItem({required this.icon, required this.label, required this.route, required this.colors});
}

// ── STATS ROW ────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<MedicineProvider>().analytics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Platform Stats', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: StatCard(label: 'Batches', value: '${analytics?.batches ?? 0}', icon: Icons.medication_rounded, colors: MC.gradP)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(label: 'Transfers', value: '${analytics?.transfers ?? 0}', icon: Icons.swap_horiz_rounded, colors: MC.gradC)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(label: 'Recalls', value: '${analytics?.recalls ?? 0}', icon: Icons.warning_rounded, colors: MC.gradR)),
        ]),
      ],
    );
  }
}

// ── HOW IT WORKS ─────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const steps = [
    ('1', 'Manufacturer registers', 'Batch gets unique ID on Ethereum', Icons.factory_rounded, MC.p),
    ('2', 'Supply chain transfers', 'Each handoff signed on-chain', Icons.local_shipping_rounded, MC.cyan),
    ('3', 'Cold-chain logged', 'IoT temperature data on blockchain', Icons.thermostat_rounded, MC.g),
    ('4', 'Patient scans QR', 'Instant blockchain verification', Icons.qr_code_scanner_rounded, MC.o),
  ];

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(eyebrow: 'Process', title: 'How It Works'),
      const SizedBox(height: 20),
      ...steps.asMap().map((i, s) => MapEntry(i, ChainStep(
        title: s.$2, subtitle: s.$3,
        time: 'Step ${s.$1}',
        icon: s.$4,
        isLast: i == steps.length - 1,
        isDone: true,
      ))).values.toList(),
    ]),
  );
}

// ── FEATURE CARDS ─────────────────────────────────────────────
class _FeatureCards extends StatelessWidget {
  const _FeatureCards();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Key Features', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      ...([
        ('🔐', 'Tamper-Proof Records', 'Every batch permanently stored on Ethereum — nobody can alter history', MC.p),
        ('🌡️', 'Cold Chain Tracking', 'Real-time temperature monitoring with on-chain breach alerts', MC.cyan),
        ('🤖', 'AI Assistant', 'MediBot helps you understand cold chain, spot fakes, navigate the app', MC.violet),
        ('📱', 'Instant QR Scan', 'Scan any medicine QR and verify authenticity in 3 seconds', MC.g),
      ].asMap().map((i, f) => MapEntry(i,
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text(f.$1, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.$2, style: GoogleFonts.spaceGrotesk(color: MC.t1, fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Text(f.$3, style: GoogleFonts.inter(color: MC.t2, fontSize: 12, height: 1.5)),
            ])),
          ]),
        ).animate(delay: Duration(milliseconds: 150 * i)).fadeIn().slideX(begin: 0.1),
      )).values.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w)).toList()),
    ],
  );
}

// ── WALLET BOTTOM SHEET ──────────────────────────────────────
class _WalletSheet extends StatefulWidget {
  const _WalletSheet();
  @override State<_WalletSheet> createState() => _WalletSheetState();
}

class _WalletSheetState extends State<_WalletSheet> {
  final _keyCtrl = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: MC.t3, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text(wallet.isConnected ? 'Wallet Connected' : 'Connect Wallet',
          style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (wallet.isConnected) ...[
          AddressDisplay(address: wallet.walletAddress),
          const SizedBox(height: 8),
          Text(wallet.balanceStr, style: GoogleFonts.spaceGrotesk(color: MC.cyan, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          GradBtn(label: 'Disconnect Wallet', colors: MC.gradR, icon: Icons.logout_rounded,
            onTap: () { wallet.disconnect(); Navigator.pop(context); }),
        ] else ...[
          Text('Enter your Sepolia testnet private key to connect.',
            style: GoogleFonts.inter(color: MC.t2, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          MCInput(
            label: 'Private Key',
            hint: '0x... or hex string',
            controller: _keyCtrl,
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18, color: MC.t2),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: MC.o.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MC.o.withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: MC.o),
              const SizedBox(width: 8),
              Expanded(child: Text('Use only test wallet private keys. Never use real funds on testnet.',
                style: GoogleFonts.inter(color: MC.o, fontSize: 11))),
            ]),
          ),
          const SizedBox(height: 16),
          if (wallet.isLoading)
            const CircularProgressIndicator(color: MC.cyan)
          else
            GradBtn(label: 'Connect Wallet', icon: Icons.account_balance_wallet_rounded,
              loading: wallet.isLoading,
              onTap: () async {
                await wallet.connectWithPrivateKey(_keyCtrl.text.trim());
                if (wallet.isConnected && context.mounted) Navigator.pop(context);
              }),
        ],
      ]),
    );
  }
}

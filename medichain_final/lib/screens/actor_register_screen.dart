import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_widgets.dart';
import '../providers/wallet_provider.dart';
import '../providers/medicine_provider.dart';

class ActorRegisterScreen extends StatefulWidget {
  const ActorRegisterScreen({super.key});
  @override State<ActorRegisterScreen> createState() => _ActorRegisterScreenState();
}

class _ActorRegisterScreenState extends State<ActorRegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _licCtrl  = TextEditingController();
  int   _role     = 1;
  bool  _loading  = false;
  bool  _done     = false;

  Future<void> _submit() async {
    final wallet = context.read<WalletProvider>();
    if (!wallet.isConnected) { _snack('Connect wallet first'); return; }
    if (_nameCtrl.text.isEmpty || _licCtrl.text.isEmpty) {
      _snack('Fill all fields', isErr: true); return;
    }
    setState(() => _loading = true);
    try {
      await context.read<MedicineProvider>().registerActor(wallet,
        name: _nameCtrl.text.trim(),
        licenseNumber: _licCtrl.text.trim(),
        role: _role,
      );
      setState(() => _done = true);
      _snack('Registered! Awaiting admin verification.');
    } catch (e) {
      _snack('Error: ${e.toString()}', isErr: true);
    }
    setState(() => _loading = false);
  }

  void _snack(String msg, {bool isErr = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isErr ? MC.r : MC.g));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MC.bg,
    appBar: AppBar(
      backgroundColor: MC.card, title: const Text('Register as Actor'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _done ? _SuccessCard() : GlassCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle(eyebrow: 'Supply Chain Actor', title: 'Join MediChain'),
        const SizedBox(height: 20),
        MCInput(label: 'Organization Name *', hint: 'PharmaPak Ltd', controller: _nameCtrl),
        const SizedBox(height: 14),
        MCInput(label: 'DRAP License Number *', hint: 'DRAP-MFG-2025-001', controller: _licCtrl),
        const SizedBox(height: 20),
        Text('Your Role in Supply Chain',
          style: GoogleFonts.inter(color: MC.t2, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        ...([
          ('🏭 Manufacturer', 'Creates and registers medicine batches', 1, MC.p),
          ('🚚 Distributor',  'Transports batches between locations',   2, MC.cyan),
          ('💊 Pharmacy',     'Final delivery point to patients',       3, MC.g),
        ]).map((r) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _role == r.$3 ? r.$4.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _role == r.$3 ? r.$4.withOpacity(0.4) : MC.border),
          ),
          child: RadioListTile<int>(
            value: r.$3, groupValue: _role,
            onChanged: (v) => setState(() => _role = v!),
            title: Text(r.$1, style: GoogleFonts.inter(color: MC.t1, fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(r.$2, style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
            activeColor: r.$4, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        )),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MC.o.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: MC.o.withOpacity(0.2))),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 15, color: MC.o),
            const SizedBox(width: 8),
            Expanded(child: Text('After registration, admin must verify your account before you can use blockchain functions.',
              style: GoogleFonts.inter(color: MC.o, fontSize: 11, height: 1.4))),
          ]),
        ),
        const SizedBox(height: 20),
        GradBtn(label: 'Register on Blockchain', icon: Icons.badge_rounded, loading: _loading, onTap: _submit),
      ])),
    ),
  );
}

class _SuccessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GlassCard(
    borderColor: MC.g.withOpacity(0.4),
    child: Column(children: [
      const SizedBox(height: 20),
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: MC.g.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.verified_user_rounded, color: MC.g, size: 40),
      ),
      const SizedBox(height: 16),
      Text('Registration Submitted!',
        style: GoogleFonts.spaceGrotesk(color: MC.g, fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Your account is pending admin verification.\nYou will be able to use all features once verified.',
        style: GoogleFonts.inter(color: MC.t2, fontSize: 13, height: 1.6), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      GradBtn(label: 'Go to Dashboard', icon: Icons.bar_chart_rounded,
        onTap: () => context.go('/dashboard')),
      const SizedBox(height: 10),
    ]),
  );
}

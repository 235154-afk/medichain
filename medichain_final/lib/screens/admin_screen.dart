import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_widgets.dart';
import '../providers/wallet_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _passCtrl   = TextEditingController();
  final _walletCtrl = TextEditingController();
  bool _authed  = false;
  bool _loading = false;
  bool _obscure = true;

  void _login() {
    if (_passCtrl.text.trim() == 'admin2025') {
      setState(() => _authed = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password'), backgroundColor: MC.r));
    }
  }

  Future<void> _verifyActor(bool approve) async {
    final wallet = context.read<WalletProvider>();
    if (!wallet.isConnected) { _snack('Connect wallet'); return; }
    if (_walletCtrl.text.isEmpty) { _snack('Enter wallet address', isErr: true); return; }
    setState(() => _loading = true);
    try {
      await wallet.sendTransaction('verifyActor', [_walletCtrl.text.trim(), approve]);
      _snack('Actor ${approve ? "verified ✅" : "rejected ❌"}');
      _walletCtrl.clear();
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
      backgroundColor: MC.card,
      title: const Text('Admin Panel'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      actions: _authed ? [
        TextButton.icon(
          onPressed: () => setState(() => _authed = false),
          icon: const Icon(Icons.logout_rounded, size: 16, color: MC.r),
          label: Text('Logout', style: GoogleFonts.inter(color: MC.r, fontSize: 13)),
        ),
      ] : null,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: !_authed ? _buildLoginForm() : _buildAdminPanel(),
    ),
  );

  Widget _buildLoginForm() => Column(children: [
    const SizedBox(height: 40),
    Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: MC.gradO),
        borderRadius: BorderRadius.circular(22)),
      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 40),
    ),
    const SizedBox(height: 20),
    Text('Admin Access', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 24, fontWeight: FontWeight.w800)),
    const SizedBox(height: 6),
    Text('MediChain Regulator Panel', style: GoogleFonts.inter(color: MC.t2, fontSize: 14)),
    const SizedBox(height: 32),
    GlassCard(child: Column(children: [
      MCInput(
        label: 'Admin Password',
        hint: 'Enter password  (demo: admin2025)',
        controller: _passCtrl,
        obscure: _obscure,
        suffix: IconButton(
          icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: 18, color: MC.t2),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      const SizedBox(height: 16),
      GradBtn(label: 'Login as Admin', icon: Icons.lock_open_rounded, colors: MC.gradO, onTap: _login),
    ])),
  ]);

  Widget _buildAdminPanel() => Column(children: [
    GlassCard(
      borderColor: MC.o.withOpacity(0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: MC.o.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.admin_panel_settings_rounded, color: MC.o, size: 22)),
          const SizedBox(width: 12),
          Text('Verify / Reject Actor', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        MCInput(label: 'Actor Wallet Address', hint: '0x...', controller: _walletCtrl),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: GradBtn(
            label: 'Verify ✅', icon: Icons.verified_rounded,
            loading: _loading, colors: MC.gradG,
            onTap: () => _verifyActor(true))),
          const SizedBox(width: 12),
          Expanded(child: GradBtn(
            label: 'Reject ❌', icon: Icons.cancel_rounded,
            loading: _loading, colors: MC.gradR,
            onTap: () => _verifyActor(false))),
        ]),
      ]),
    ),
    const SizedBox(height: 16),
    GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Quick Actions', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      ...[
        ('Register Medicine Batch', Icons.add_box_rounded, MC.p, '/register-batch'),
        ('Issue Batch Recall',      Icons.warning_rounded, MC.r, '/recall'),
        ('View Analytics Dashboard',Icons.bar_chart_rounded, MC.cyan, '/dashboard'),
        ('Cold Chain Temperature Log', Icons.thermostat_rounded, MC.g, '/cold-chain'),
        ('Register as Supply Actor', Icons.badge_rounded, MC.violet, '/actor-register'),
      ].map((a) => ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: a.$3.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(a.$2, color: a.$3, size: 18)),
        title: Text(a.$1, style: GoogleFonts.inter(color: MC.t1, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right_rounded, color: MC.t3, size: 18),
        onTap: () => context.push(a.$4),
        contentPadding: EdgeInsets.zero,
      )),
    ])),
    const SizedBox(height: 80),
  ]);
}

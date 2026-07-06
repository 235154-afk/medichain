import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_widgets.dart';
import '../providers/wallet_provider.dart';
import '../providers/medicine_provider.dart';

class RecallScreen extends StatefulWidget {
  const RecallScreen({super.key});
  @override State<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends State<RecallScreen> {
  final _batchCtrl  = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool  _loading    = false;
  bool  _done       = false;
  String _txHash    = '';

  Future<void> _submit() async {
    final wallet = context.read<WalletProvider>();
    if (!wallet.isConnected) { _snack('Connect wallet first'); return; }
    if (_batchCtrl.text.isEmpty || _reasonCtrl.text.isEmpty) {
      _snack('Fill all fields', isErr: true); return;
    }
    setState(() => _loading = true);
    try {
      final tx = await context.read<MedicineProvider>().recallBatch(
        wallet, BigInt.parse(_batchCtrl.text.trim()), _reasonCtrl.text.trim());
      setState(() { _txHash = tx; _done = true; });
      _snack('Recall issued on blockchain! ⚠️');
    } catch (e) {
      _snack('Error: ${e.toString()}', isErr: true);
    }
    setState(() => _loading = false);
  }

  void _snack(String msg, {bool isErr = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isErr ? MC.r : MC.o));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MC.bg,
    appBar: AppBar(
      backgroundColor: MC.card, title: const Text('Issue Recall'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MC.r.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MC.r.withOpacity(0.3))),
          child: Row(children: [
            const Icon(Icons.warning_rounded, color: MC.r, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(
              'Recalls are permanent and public on blockchain. All patients, pharmacies, and distributors will see this recall immediately.',
              style: GoogleFonts.inter(color: MC.r, fontSize: 12, height: 1.5))),
          ]),
        ),
        const SizedBox(height: 16),
        if (_done) GlassCard(
          borderColor: MC.o.withOpacity(0.4),
          child: Column(children: [
            const SizedBox(height: 10),
            const Icon(Icons.warning_amber_rounded, color: MC.o, size: 44),
            const SizedBox(height: 10),
            Text('Recall Issued!',
              style: GoogleFonts.spaceGrotesk(color: MC.o, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Batch #${_batchCtrl.text} has been recalled on the blockchain.',
              style: GoogleFonts.inter(color: MC.t2, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (_txHash.isNotEmpty) TxHashLink(txHash: _txHash),
            const SizedBox(height: 10),
          ]),
        )
        else GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle(eyebrow: 'Regulator / Admin Only', title: 'Issue Recall'),
          const SizedBox(height: 20),
          MCInput(
            label: 'Batch ID *', hint: '1',
            controller: _batchCtrl, keyboard: TextInputType.number),
          const SizedBox(height: 14),
          MCInput(
            label: 'Reason for Recall *',
            hint: 'Contamination detected in batch during quality check...',
            controller: _reasonCtrl, maxLines: 4),
          const SizedBox(height: 20),
          GradBtn(
            label: 'Issue Recall On-Chain',
            icon: Icons.warning_rounded,
            loading: _loading,
            colors: MC.gradR,
            onTap: _submit,
          ),
        ])),
        const SizedBox(height: 80),
      ]),
    ),
  );
}

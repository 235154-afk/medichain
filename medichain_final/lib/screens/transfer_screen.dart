import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_widgets.dart';
import '../providers/wallet_provider.dart';
import '../providers/medicine_provider.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});
  @override State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _form      = GlobalKey<FormState>();
  final _batchCtrl = TextEditingController();
  final _toCtrl    = TextEditingController();
  final _locCtrl   = TextEditingController();
  final _noteCtrl  = TextEditingController();
  final _tempCtrl  = TextEditingController(text: '40');
  bool _loading = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final wallet = context.read<WalletProvider>();
    if (!wallet.isConnected) { _snack('Connect wallet first'); return; }
    setState(() => _loading = true);
    try {
      final tx = await context.read<MedicineProvider>().transferBatch(wallet,
        batchId:     BigInt.parse(_batchCtrl.text.trim()),
        toAddress:   _toCtrl.text.trim(),
        location:    _locCtrl.text.trim(),
        notes:       _noteCtrl.text.trim(),
        currentTemp: int.tryParse(_tempCtrl.text) ?? 40,
      );
      _snack('Transfer successful! TX: ${tx.substring(0, 10)}...');
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
      backgroundColor: MC.card, title: const Text('Transfer Batch'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(key: _form, child: Column(children: [
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle(eyebrow: 'Supply Chain', title: 'Transfer Batch'),
          const SizedBox(height: 20),
          MCInput(label: 'Batch ID *', hint: '1', controller: _batchCtrl,
            keyboard: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          MCInput(label: 'Recipient Wallet Address *', hint: '0x...', controller: _toCtrl,
            validator: (v) => (v?.length ?? 0) < 10 ? 'Enter valid address' : null),
          const SizedBox(height: 14),
          MCInput(label: 'Current Location *', hint: 'Karachi Warehouse, Sindh', controller: _locCtrl,
            validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          MCInput(label: 'Notes', hint: 'Batch handed to distributor', controller: _noteCtrl),
          const SizedBox(height: 14),
          MCInput(label: 'Current Temp (°C × 10)', hint: '40 = 4.0°C', controller: _tempCtrl,
            keyboard: TextInputType.number),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MC.cyan.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
            child: Text('Temperature is recorded on-chain for cold-chain compliance.',
              style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
          ),
        ])),
        const SizedBox(height: 20),
        GradBtn(
          label: 'Transfer on Blockchain',
          icon: Icons.swap_horiz_rounded,
          loading: _loading,
          onTap: _submit,
        ),
        const SizedBox(height: 80),
      ])),
    ),
  );
}

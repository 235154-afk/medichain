import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_widgets.dart';
import '../providers/wallet_provider.dart';
import '../providers/medicine_provider.dart';

class RegisterBatchScreen extends StatefulWidget {
  const RegisterBatchScreen({super.key});
  @override State<RegisterBatchScreen> createState() => _RegisterBatchScreenState();
}

class _RegisterBatchScreenState extends State<RegisterBatchScreen> {
  final _form       = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _batchCtrl  = TextEditingController();
  final _mfgCtrl    = TextEditingController();
  final _compCtrl   = TextEditingController();
  final _qtyCtrl    = TextEditingController();
  final _minTCtrl   = TextEditingController(text: '20');
  final _maxTCtrl   = TextEditingController(text: '80');

  DateTime _mfgDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _expDate = DateTime.now().add(const Duration(days: 730));
  bool _loading = false;
  String _txHash = '';

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final wallet = context.read<WalletProvider>();
    if (!wallet.isConnected) { _snack('Connect wallet first'); return; }
    setState(() { _loading = true; _txHash = ''; });
    try {
      final tx = await context.read<MedicineProvider>().registerBatch(wallet,
        name:         _nameCtrl.text.trim(),
        batchNumber:  _batchCtrl.text.trim(),
        manufacturer: _mfgCtrl.text.trim(),
        composition:  _compCtrl.text.trim(),
        mfgDate:      _mfgDate,
        expDate:      _expDate,
        quantity:     int.tryParse(_qtyCtrl.text) ?? 0,
        minTemp:      int.tryParse(_minTCtrl.text) ?? 20,
        maxTemp:      int.tryParse(_maxTCtrl.text) ?? 80,
      );
      setState(() { _txHash = tx; });
      _snack('Batch registered on blockchain! ✅');
    } catch (e) {
      _snack('Error: ${e.toString()}', isErr: true);
    }
    setState(() => _loading = false);
  }

  void _snack(String msg, {bool isErr = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isErr ? MC.r : MC.g));
  }

  Future<void> _pickDate(bool isExp) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isExp ? _expDate : _mfgDate,
      firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: MC.p)),
        child: child!),
    );
    if (d != null) setState(() => isExp ? _expDate = d : _mfgDate = d);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MC.bg,
    appBar: AppBar(
      backgroundColor: MC.card, title: const Text('Register Medicine Batch'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(key: _form, child: Column(children: [
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle(eyebrow: 'Manufacturer Only', title: 'Register New Batch'),
          const SizedBox(height: 20),
          MCInput(label: 'Medicine Name *', hint: 'Insulin Glargine', controller: _nameCtrl,
            validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          MCInput(label: 'Batch Number *', hint: 'BN-2025-001', controller: _batchCtrl,
            validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          MCInput(label: 'Manufacturer Name *', hint: 'PharmaPak Ltd', controller: _mfgCtrl,
            validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          MCInput(label: 'Composition', hint: 'Insulin Glargine 100 IU/mL', controller: _compCtrl),
          const SizedBox(height: 14),
          MCInput(label: 'Quantity (Units) *', hint: '1000', controller: _qtyCtrl,
            keyboard: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 20),
          Text('Temperature Range (°C × 10)',
            style: GoogleFonts.inter(color: MC.t2, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: MCInput(label: 'Min Temp (×10)', hint: '20 = 2.0°C', controller: _minTCtrl, keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: MCInput(label: 'Max Temp (×10)', hint: '80 = 8.0°C', controller: _maxTCtrl, keyboard: TextInputType.number)),
          ]),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: MC.cyan.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
            child: Text('Insulin range 2°C–8°C → enter Min: 20, Max: 80',
              style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
          ),
          const SizedBox(height: 20),
          Text('Dates', style: GoogleFonts.inter(color: MC.t2, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _DateTile('Mfg Date', _mfgDate, () => _pickDate(false))),
            const SizedBox(width: 12),
            Expanded(child: _DateTile('Exp Date', _expDate, () => _pickDate(true))),
          ]),
        ])),
        if (_txHash.isNotEmpty) ...[
          const SizedBox(height: 16),
          GlassCard(
            borderColor: MC.g.withOpacity(0.4),
            child: Column(children: [
              const Icon(Icons.check_circle_rounded, color: MC.g, size: 40),
              const SizedBox(height: 10),
              Text('Batch Registered!',
                style: GoogleFonts.spaceGrotesk(color: MC.g, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Transaction Hash:', style: GoogleFonts.inter(color: MC.t3, fontSize: 12)),
              const SizedBox(height: 4),
              TxHashLink(txHash: _txHash),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        GradBtn(label: 'Register on Blockchain', icon: Icons.add_rounded, loading: _loading, onTap: _submit),
        const SizedBox(height: 80),
      ])),
    ),
  );
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateTile(this.label, this.date, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MC.card2, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MC.cyan.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 13, color: MC.cyan),
          const SizedBox(width: 6),
          Text('${date.day}/${date.month}/${date.year}',
            style: GoogleFonts.inter(color: MC.t1, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ]),
    ),
  );
}

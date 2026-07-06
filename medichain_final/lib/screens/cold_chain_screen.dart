import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_widgets.dart';
import '../providers/wallet_provider.dart';
import '../providers/medicine_provider.dart';

class ColdChainScreen extends StatefulWidget {
  const ColdChainScreen({super.key});
  @override State<ColdChainScreen> createState() => _ColdChainScreenState();
}

class _ColdChainScreenState extends State<ColdChainScreen> {
  final _batchCtrl = TextEditingController();
  final _tempCtrl  = TextEditingController();
  final _locCtrl   = TextEditingController();
  bool _loading    = false;

  Future<void> _logTemp() async {
    final wallet = context.read<WalletProvider>();
    if (!wallet.isConnected) { _snack('Connect wallet first'); return; }
    if (_batchCtrl.text.isEmpty || _tempCtrl.text.isEmpty) {
      _snack('Fill all required fields', isErr: true); return;
    }
    setState(() => _loading = true);
    try {
      final tx = await context.read<MedicineProvider>().logTemperature(wallet,
        batchId:     BigInt.parse(_batchCtrl.text.trim()),
        temperature: int.parse(_tempCtrl.text.trim()),
        location:    _locCtrl.text.trim(),
      );
      _snack('Temperature logged on blockchain! TX: ${tx.substring(0, 10)}...');
      _batchCtrl.clear(); _tempCtrl.clear(); _locCtrl.clear();
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
      backgroundColor: MC.card, title: const Text('Cold Chain Monitor'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Temperature Reference Guide',
            style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _TempRef('Insulin & Vaccines', '2°C – 8°C', 'Enter: 20 – 80', MC.cyan),
          _TempRef('Most Tablets',       '15°C – 25°C','Enter: 150 – 250', MC.g),
          _TempRef('Biologics',          '2°C – 8°C', 'Enter: 20 – 80', MC.violet),
          _TempRef('Suppositories',      '< 25°C',    'Enter: < 250', MC.o),
        ])),
        const SizedBox(height: 16),
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle(eyebrow: 'IoT / Manual Entry', title: 'Log Temperature'),
          const SizedBox(height: 20),
          MCInput(label: 'Batch ID *', hint: '1', controller: _batchCtrl, keyboard: TextInputType.number),
          const SizedBox(height: 14),
          MCInput(label: 'Temperature (°C × 10) *', hint: '40 = 4.0°C  |  250 = 25.0°C',
            controller: _tempCtrl, keyboard: TextInputType.number),
          const SizedBox(height: 14),
          MCInput(label: 'Location', hint: 'Cold storage, Lahore', controller: _locCtrl),
          const SizedBox(height: 20),
          GradBtn(
            label: 'Log Temperature On-Chain',
            icon: Icons.thermostat_rounded,
            loading: _loading,
            colors: MC.gradG,
            onTap: _logTemp,
          ),
        ])),
        const SizedBox(height: 80),
      ]),
    ),
  );
}

class _TempRef extends StatelessWidget {
  final String name, range, hint;
  final Color color;
  const _TempRef(this.name, this.range, this.hint, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.inter(color: MC.t1, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(hint, style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
      ])),
      Text(range, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}

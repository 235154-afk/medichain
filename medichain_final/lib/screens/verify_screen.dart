// lib/screens/verify_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/shared_widgets.dart';
import '../providers/wallet_provider.dart';
import '../providers/medicine_provider.dart';
import '../models/medicine_batch.dart';

class VerifyScreen extends StatefulWidget {
  final String batchId;
  const VerifyScreen({super.key, required this.batchId});
  @override State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _idCtrl = TextEditingController();
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    if (widget.batchId.isNotEmpty) {
      _idCtrl.text = widget.batchId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
    }
  }

  Future<void> _verify() async {
    final wallet = context.read<WalletProvider>();
    final med    = context.read<MedicineProvider>();
    if (!wallet.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect wallet first to verify on blockchain.')));
      return;
    }
    setState(() => _searched = true);
    await med.verifyBatch(wallet, _idCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final med = context.watch<MedicineProvider>();
    return Scaffold(
      backgroundColor: MC.bg,
      appBar: AppBar(
        backgroundColor: MC.card,
        title: const Text('Verify Medicine'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Search bar
          GlassCard(
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _idCtrl,
                    style: GoogleFonts.inter(color: MC.t1),
                    decoration: InputDecoration(
                      hintText: 'Enter batch number or ID...',
                      hintStyle: GoogleFonts.inter(color: MC.t3),
                      prefixIcon: const Icon(Icons.search_rounded, color: MC.t2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _verify,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: MC.gradP), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.verified_rounded, color: Colors.white),
                  ),
                ),
              ]),
              if (!_searched) ...[
                const SizedBox(height: 14),
                Text('Enter a batch number (e.g. BN-2025-001) or numeric batch ID to verify on the Ethereum blockchain.',
                  style: GoogleFonts.inter(color: MC.t2, fontSize: 12, height: 1.5), textAlign: TextAlign.center),
              ],
            ]),
          ),

          const SizedBox(height: 20),

          // Loading
          if (med.isLoading)
            _LoadingVerify(),

          // Error
          if (!med.isLoading && med.error.isNotEmpty && _searched)
            _ErrorResult(error: med.error),

          // Result
          if (!med.isLoading && med.currentBatch != null && _searched)
            _VerifyResult(batch: med.currentBatch!, transfers: med.transfers, tempLogs: med.tempLogs),
        ]),
      ),
    );
  }
}

class _LoadingVerify extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(children: [
      const SizedBox(height: 20),
      const CircularProgressIndicator(color: MC.cyan, strokeWidth: 2),
      const SizedBox(height: 16),
      Text('Querying Ethereum blockchain...', style: GoogleFonts.inter(color: MC.t2, fontSize: 14)),
      const SizedBox(height: 6),
      Text('This may take a few seconds', style: GoogleFonts.inter(color: MC.t3, fontSize: 12)),
      const SizedBox(height: 20),
    ]),
  );
}

class _ErrorResult extends StatelessWidget {
  final String error;
  const _ErrorResult({required this.error});

  @override
  Widget build(BuildContext context) => GlassCard(
    borderColor: MC.r.withOpacity(0.4),
    child: Column(children: [
      Container(
        width: 70, height: 70,
        decoration: BoxDecoration(color: MC.r.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.cancel_rounded, color: MC.r, size: 36),
      ),
      const SizedBox(height: 14),
      Text('Not Found on Blockchain', style: GoogleFonts.spaceGrotesk(color: MC.r, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('This medicine could not be verified. It may be counterfeit, incorrectly labeled, or not registered.',
        style: GoogleFonts.inter(color: MC.t2, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: MC.r.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MC.r.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('⚠️ Warning Signs to Check:', style: GoogleFonts.inter(color: MC.r, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          ...['Blurry or missing batch number','Price too low vs market','Poor packaging quality','No DRAP license number']
            .map((w) => Padding(padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.close_rounded, size: 13, color: MC.r),
                const SizedBox(width: 6),
                Text(w, style: GoogleFonts.inter(color: MC.t2, fontSize: 12)),
              ]))),
        ]),
      ),
      const SizedBox(height: 14),
      Text('Report to DRAP: 0800-03727', style: GoogleFonts.inter(color: MC.o, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
}

class _VerifyResult extends StatelessWidget {
  final MedicineBatch batch;
  final List<TransferEvent> transfers;
  final List<TempLog> tempLogs;

  const _VerifyResult({required this.batch, required this.transfers, required this.tempLogs});

  Color get statusColor {
    if (batch.status == BatchStatus.recalled) return MC.r;
    if (batch.isExpired) return MC.r;
    if (batch.status == BatchStatus.delivered) return MC.g;
    return MC.cyan;
  }

  bool get hasTempBreach => tempLogs.any((t) => t.status != TempStatus.normal);

  @override
  Widget build(BuildContext context) => Column(children: [
    // Main result card
    GlassCard(
      borderColor: statusColor.withOpacity(0.4),
      child: Column(children: [
        // Status icon
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle,
            border: Border.all(color: statusColor.withOpacity(0.3), width: 2)),
          child: Icon(
            batch.status == BatchStatus.recalled ? Icons.cancel_rounded :
            batch.isExpired ? Icons.timer_off_rounded : Icons.verified_rounded,
            color: statusColor, size: 40,
          ),
        ).animate().scale(curve: Curves.elasticOut),

        const SizedBox(height: 14),
        Text(
          batch.status == BatchStatus.recalled ? '⚠️ RECALLED' :
          batch.isExpired ? '❌ EXPIRED' : '✅ AUTHENTIC',
          style: GoogleFonts.spaceGrotesk(color: statusColor, fontSize: 22, fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 6),
        const BlockchainBadge(),

        const SizedBox(height: 20),

        // Medicine info
        _InfoRow('Medicine Name', batch.name),
        _InfoRow('Batch Number', batch.batchNumber),
        _InfoRow('Manufacturer', batch.manufacturer),
        _InfoRow('Composition', batch.composition),
        _InfoRow('Manufactured', _fmt(batch.mfgDate)),
        _InfoRow('Expires', _fmt(batch.expDate)),
        _InfoRow('Quantity', '${batch.quantity} units'),
        _InfoRow('Temp Range', batch.tempRange),
        _InfoRow('Status', batch.status.label),

        if (hasTempBreach) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: MC.o.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MC.o.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.thermostat_rounded, color: MC.o, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('⚠️ Cold chain breach detected in temperature logs. Consult your pharmacist.',
                style: GoogleFonts.inter(color: MC.o, fontSize: 12, height: 1.4))),
            ]),
          ),
        ],

        // QR code
        const SizedBox(height: 20),
        Text('Share Verification QR', style: GoogleFonts.inter(color: MC.t2, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: QrImageView(
            data: 'medichain://verify/${batch.id}',
            version: QrVersions.auto, size: 140,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: MC.bg),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: MC.p),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 500.ms),

    const SizedBox(height: 16),

    // Supply chain timeline
    if (transfers.isNotEmpty) GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Supply Chain Journey', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...transfers.asMap().map((i, t) => MapEntry(i, ChainStep(
          title: _roleLabel(t.toRole.index),
          subtitle: t.location.isEmpty ? 'Location not specified' : t.location,
          time: _fmtDt(t.timestamp),
          icon: _roleIcon(t.toRole.index),
          isLast: i == transfers.length - 1,
        ))).values.toList(),
      ]),
    ),

    const SizedBox(height: 16),

    // Temperature logs
    if (tempLogs.isNotEmpty) GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Temperature Log', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...tempLogs.take(10).map((log) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            TempChip(temp: log.tempStr, statusIdx: log.status.index),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(log.location, style: GoogleFonts.inter(color: MC.t1, fontSize: 12)),
              Text(_fmtDt(log.timestamp), style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
            ])),
          ]),
        )),
      ]),
    ),

    const SizedBox(height: 80),
  ]);

  Widget _InfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120, child: Text(label, style: GoogleFonts.inter(color: MC.t3, fontSize: 12))),
      const SizedBox(width: 10),
      Expanded(child: Text(value, style: GoogleFonts.inter(color: MC.t1, fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _fmtDt(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2,'0')}';

  String _roleLabel(int i) => ['','Manufacturer','Distributor','Pharmacy','Regulator'][i.clamp(0,4)];
  IconData _roleIcon(int i) => [Icons.circle, Icons.factory_rounded, Icons.local_shipping_rounded, Icons.local_pharmacy_rounded, Icons.admin_panel_settings_rounded][i.clamp(0,4)];
}

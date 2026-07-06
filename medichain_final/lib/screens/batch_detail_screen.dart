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

class BatchDetailScreen extends StatefulWidget {
  final String batchId;
  const BatchDetailScreen({super.key, required this.batchId});
  @override State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallet = context.read<WalletProvider>();
      if (wallet.isConnected) {
        context.read<MedicineProvider>().verifyBatch(wallet, widget.batchId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final med = context.watch<MedicineProvider>();
    return Scaffold(
      backgroundColor: MC.bg,
      appBar: AppBar(
        backgroundColor: MC.card,
        title: Text('Batch #${widget.batchId}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share link copied!'))),
          ),
        ],
      ),
      body: med.isLoading
          ? const Center(child: CircularProgressIndicator(color: MC.cyan, strokeWidth: 2))
          : med.currentBatch != null
              ? _BatchDetail(batch: med.currentBatch!, transfers: med.transfers, tempLogs: med.tempLogs)
              : Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.search_off_rounded, size: 60, color: MC.t3),
                    const SizedBox(height: 14),
                    Text('Batch Not Found', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Batch #${widget.batchId} not on blockchain', style: GoogleFonts.inter(color: MC.t2)),
                  ]),
                ),
    );
  }
}

class _BatchDetail extends StatelessWidget {
  final MedicineBatch batch;
  final List<TransferEvent> transfers;
  final List<TempLog> tempLogs;
  const _BatchDetail({required this.batch, required this.transfers, required this.tempLogs});

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      // Header card
      GlassCard(
        borderColor: MC.g.withOpacity(0.3),
        child: Column(children: [
          Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: MC.gradP), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.medication_liquid_rounded, color: Colors.white, size: 26)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(batch.name, style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(batch.batchNumber, style: GoogleFonts.jetBrainsMono(color: MC.cyan, fontSize: 13)),
            ])),
            StatusBadge(label: batch.status.label, color: batch.isExpired ? MC.r : batch.status == BatchStatus.recalled ? MC.r : MC.g),
          ]),
          const SizedBox(height: 16),
          const Divider(color: MC.border, height: 1),
          const SizedBox(height: 16),
          _InfoRow('Manufacturer', batch.manufacturer),
          _InfoRow('Composition', batch.composition),
          _InfoRow('Manufactured', _fmt(batch.mfgDate)),
          _InfoRow('Expires', _fmt(batch.expDate)),
          _InfoRow('Quantity', '${batch.quantity} units'),
          _InfoRow('Temp Range', batch.tempRange),
          const SizedBox(height: 14),
          const BlockchainBadge(),
        ]),
      ).animate().fadeIn(duration: 400.ms),

      const SizedBox(height: 16),

      // QR Code card
      GlassCard(
        child: Column(children: [
          Text('Verification QR Code', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: QrImageView(
              data: 'medichain://verify/${batch.id}',
              version: QrVersions.auto, size: 160,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: MC.bg),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: MC.p),
            ),
          ),
          const SizedBox(height: 8),
          Text('Scan to verify on MediChain', style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
        ]),
      ),

      const SizedBox(height: 16),

      // Transfer history
      if (transfers.isNotEmpty) GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Supply Chain Journey', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...transfers.asMap().entries.map((e) {
            final t = e.value;
            final icons = [Icons.circle, Icons.factory_rounded, Icons.local_shipping_rounded, Icons.local_pharmacy_rounded, Icons.admin_panel_settings_rounded];
            return ChainStep(
              title: ['', 'Manufacturer', 'Distributor', 'Pharmacy', 'Regulator'][t.toRole.index.clamp(0, 4)],
              subtitle: t.location.isEmpty ? t.notes : t.location,
              time: '${t.timestamp.day}/${t.timestamp.month}/${t.timestamp.year} ${t.timestamp.hour}:${t.timestamp.minute.toString().padLeft(2, '0')}',
              icon: icons[t.toRole.index.clamp(0, 4)],
              isLast: e.key == transfers.length - 1,
            );
          }),
        ]),
      ),

      const SizedBox(height: 16),

      // Temp logs
      if (tempLogs.isNotEmpty) GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Temperature Log', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...tempLogs.take(10).map((log) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              TempChip(temp: log.tempStr, statusIdx: log.status.index),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(log.location.isEmpty ? 'Location not recorded' : log.location,
                  style: GoogleFonts.inter(color: MC.t1, fontSize: 12)),
                Text('${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year}',
                  style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
              ])),
            ]),
          )),
        ]),
      ),

      const SizedBox(height: 80),
    ]),
  );
}

Widget _InfoRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 110, child: Text(label, style: GoogleFonts.inter(color: MC.t3, fontSize: 12))),
    const SizedBox(width: 10),
    Expanded(child: Text(value, style: GoogleFonts.inter(color: MC.t1, fontSize: 13, fontWeight: FontWeight.w500))),
  ]),
);

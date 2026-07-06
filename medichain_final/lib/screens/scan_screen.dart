// ═══════════════════════════════════════════
// lib/screens/scan_screen.dart
// ═══════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/shared_widgets.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MC.bg,
      appBar: AppBar(
        backgroundColor: MC.card,
        title: const Text('Scan & Verify'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // QR Scanner placeholder (real QR scanner via mobile_scanner)
          GlassCard(
            child: Column(children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: MC.card2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MC.cyan.withOpacity(0.3), width: 2),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  // Corner markers
                  ..._corners(),
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.qr_code_scanner_rounded, size: 60, color: MC.cyan),
                    const SizedBox(height: 14),
                    Text('Point camera at medicine QR code',
                      style: GoogleFonts.inter(color: MC.t2, fontSize: 13), textAlign: TextAlign.center),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              GradBtn(
                label: 'Open Camera Scanner',
                icon: Icons.camera_alt_rounded,
                onTap: () => _showCameraNote(context),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Divider
          Row(children: [
            Expanded(child: Divider(color: MC.border)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('OR', style: GoogleFonts.inter(color: MC.t3, fontSize: 12))),
            Expanded(child: Divider(color: MC.border)),
          ]),

          const SizedBox(height: 20),

          // Manual search
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Search by Batch Number / ID',
                style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(color: MC.t1),
                    decoration: InputDecoration(
                      hintText: 'e.g. BN-2025-001 or batch ID 1',
                      hintStyle: GoogleFonts.inter(color: MC.t3, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: MC.t2, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    if (_searchCtrl.text.trim().isNotEmpty) {
                      context.push('/verify?id=${_searchCtrl.text.trim()}');
                    }
                  },
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: MC.gradP),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Demo batches
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Demo Batches (Tap to verify)',
                style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...(['BN-2025-001', 'BN-2025-002', 'BN-2025-003'].map((b) =>
                ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: MC.p.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.medication_rounded, color: MC.p, size: 18),
                  ),
                  title: Text(b, style: GoogleFonts.inter(color: MC.t1, fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: Text('Tap to verify on blockchain', style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: MC.t3),
                  onTap: () => context.push('/verify?id=$b'),
                  contentPadding: EdgeInsets.zero,
                ),
              ).toList()),
            ]),
          ),
        ]),
      ),
    );
  }

  List<Widget> _corners() => [
    Positioned(top: 12, left: 12, child: _CornerMark(topLeft: true)),
    Positioned(top: 12, right: 12, child: _CornerMark(topRight: true)),
    Positioned(bottom: 12, left: 12, child: _CornerMark(bottomLeft: true)),
    Positioned(bottom: 12, right: 12, child: _CornerMark(bottomRight: true)),
  ];

  void _showCameraNote(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('On physical device, camera opens here. Use search above for demo.'),
      duration: Duration(seconds: 3),
    ));
  }
}

class _CornerMark extends StatelessWidget {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  const _CornerMark({this.topLeft=false, this.topRight=false, this.bottomLeft=false, this.bottomRight=false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 24, height: 24,
      child: CustomPaint(painter: _CornerPainter(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight)));
  }
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  _CornerPainter({this.topLeft=false, this.topRight=false, this.bottomLeft=false, this.bottomRight=false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = MC.cyan..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    if (topLeft) { canvas.drawLine(Offset.zero, Offset(size.width, 0), paint); canvas.drawLine(Offset.zero, Offset(0, size.height), paint); }
    if (topRight) { canvas.drawLine(Offset(size.width, 0), Offset.zero, paint); canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint); }
    if (bottomLeft) { canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint); canvas.drawLine(Offset(0, size.height), Offset.zero, paint); }
    if (bottomRight) { canvas.drawLine(Offset(size.width, size.height), Offset.zero, paint); canvas.drawLine(Offset(size.width, size.height), Offset(0, size.height), paint); }
  }

  @override
  bool shouldRepaint(_) => false;
}

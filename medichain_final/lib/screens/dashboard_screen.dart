// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../widgets/shared_widgets.dart';
import '../providers/wallet_provider.dart';
import '../providers/medicine_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    final med    = context.watch<MedicineProvider>();
    final a      = med.analytics;

    return Scaffold(
      backgroundColor: MC.bg,
      appBar: AppBar(
        backgroundColor: MC.card,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => med.loadAnalytics(wallet),
          ),
        ],
      ),
      body: wallet.isConnected
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Wallet card
                _WalletCard(wallet: wallet),
                const SizedBox(height: 16),

                // Stat cards 2x2
                Row(children: [
                  Expanded(child: StatCard(label: 'Total Batches', value: '${a?.batches ?? 0}', icon: Icons.medication_rounded, colors: MC.gradP)),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(label: 'Transfers', value: '${a?.transfers ?? 0}', icon: Icons.swap_horiz_rounded, colors: MC.gradC)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: StatCard(label: 'Recalls', value: '${a?.recalls ?? 0}', icon: Icons.warning_rounded, colors: MC.gradR)),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(label: 'Temp Breaches', value: '${a?.breaches ?? 0}', icon: Icons.thermostat_rounded, colors: MC.gradO)),
                ]),

                const SizedBox(height: 20),

                // Actor card
                if (wallet.actorInfo.exists) _ActorCard(wallet: wallet),

                const SizedBox(height: 20),

                // Charts
                _BatchStatusChart(analytics: a),
                const SizedBox(height: 16),
                _TempBreachChart(),
                const SizedBox(height: 16),
                _SupplyChainProgress(analytics: a),

                const SizedBox(height: 80),
              ]),
            )
          : _NotConnected(),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final WalletProvider wallet;
  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(20),
    child: Row(children: [
      Container(
        width: 50, height: 50,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: MC.gradP), borderRadius: BorderRadius.circular(14)),
        child: Center(child: Text(wallet.walletAddress.isEmpty ? '?' : wallet.walletAddress.substring(2,4).toUpperCase(),
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Connected Wallet', style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
        const SizedBox(height: 3),
        AddressDisplay(address: wallet.walletAddress),
        const SizedBox(height: 4),
        Text(wallet.balanceStr, style: GoogleFonts.spaceGrotesk(color: MC.cyan, fontSize: 18, fontWeight: FontWeight.w700)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: MC.g.withOpacity(0.1), borderRadius: BorderRadius.circular(50),
          border: Border.all(color: MC.g.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: MC.g, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('Sepolia', style: GoogleFonts.inter(color: MC.g, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]),
  ).animate().fadeIn().slideY(begin: -0.1);
}

class _ActorCard extends StatelessWidget {
  final WalletProvider wallet;
  const _ActorCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final actor = wallet.actorInfo;
    final roleColors = [Colors.transparent, MC.p, MC.cyan, MC.g, MC.violet];
    final roleColor = roleColors[actor.role.index.clamp(0, 4)];
    return GlassCard(
      borderColor: roleColor.withOpacity(0.3),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.badge_rounded, color: roleColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(actor.name, style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(actor.role.label, style: GoogleFonts.inter(color: roleColor, fontSize: 13, fontWeight: FontWeight.w500)),
          Text('License: ${actor.licenseNumber}', style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
        ])),
        actor.isVerified
            ? const StatusBadge(label: 'Verified', color: MC.g, icon: Icons.verified_rounded)
            : const StatusBadge(label: 'Pending', color: MC.o, icon: Icons.hourglass_bottom_rounded),
      ]),
    );
  }
}

class _BatchStatusChart extends StatelessWidget {
  final analytics;
  const _BatchStatusChart({this.analytics});

  @override
  Widget build(BuildContext context) {
    final total  = (analytics?.batches ?? 0).toDouble().clamp(1, double.infinity);
    final recalls = (analytics?.recalls ?? 0).toDouble();
    final active  = (total - recalls).clamp(0, total);

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Batch Overview', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: PieChart(PieChartData(
            sections: [
              PieChartSectionData(value: active, color: MC.g, title: 'Active\n${active.toInt()}', radius: 70,
                titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              PieChartSectionData(value: recalls, color: MC.r, title: 'Recalled\n${recalls.toInt()}', radius: 70,
                titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
            sectionsSpace: 3,
            centerSpaceRadius: 40,
          )),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Legend(color: MC.g, label: 'Active'),
          const SizedBox(width: 24),
          _Legend(color: MC.r, label: 'Recalled'),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6),
    Text(label, style: GoogleFonts.inter(color: MC.t2, fontSize: 12)),
  ]);
}

class _TempBreachChart extends StatelessWidget {
  const _TempBreachChart();

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Temperature Trends (Sample)', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      SizedBox(
        height: 160,
        child: LineChart(LineChartData(
          gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: MC.border, strokeWidth: 0.5)),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
              getTitlesWidget: (v, _) => Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][v.toInt().clamp(0,6)],
                style: GoogleFonts.inter(color: MC.t3, fontSize: 10)))),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
              getTitlesWidget: (v, _) => Text('${v.toInt()}°', style: GoogleFonts.inter(color: MC.t3, fontSize: 10)))),
            topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0, maxX: 6, minY: 0, maxY: 12,
          lineBarsData: [
            LineChartBarData(
              spots: const [FlSpot(0,4),FlSpot(1,5),FlSpot(2,4.5),FlSpot(3,7),FlSpot(4,5),FlSpot(5,4),FlSpot(6,5)],
              isCurved: true,
              color: MC.cyan,
              barWidth: 2,
              dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: MC.cyan, strokeWidth: 0)),
              belowBarData: BarAreaData(show: true, color: MC.cyan.withOpacity(0.06)),
            ),
            LineChartBarData(
              spots: const [FlSpot(0,2),FlSpot(1,2),FlSpot(2,8),FlSpot(3,2),FlSpot(4,2),FlSpot(5,2),FlSpot(6,2)],
              isCurved: false,
              color: MC.r,
              barWidth: 1.5,
              dashArray: [4, 4],
              dotData: FlDotData(show: false),
            ),
          ],
        )),
      ),
      const SizedBox(height: 10),
      Row(children: [
        _Legend(color: MC.cyan, label: 'Avg Temp (°C)'),
        const SizedBox(width: 24),
        _Legend(color: MC.r, label: 'Max Allowed'),
      ]),
    ]),
  );
}

class _SupplyChainProgress extends StatelessWidget {
  final analytics;
  const _SupplyChainProgress({this.analytics});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Registered', (analytics?.batches ?? 0), MC.p),
      ('In Transit', ((analytics?.transfers ?? 0) / 2).round(), MC.cyan),
      ('Delivered',  ((analytics?.batches ?? 0) * 0.6).round(), MC.g),
      ('Recalled',   analytics?.recalls ?? 0, MC.r),
    ];
    final maxVal = steps.map((s) => s.$2).reduce((a, b) => a > b ? a : b);
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Supply Chain Status', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        ...steps.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(s.$1, style: GoogleFonts.inter(color: MC.t2, fontSize: 13))),
              Text('${s.$2}', style: GoogleFonts.inter(color: MC.t1, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            LinearPercentIndicator(
              percent: maxVal == 0 ? 0 : (s.$2 / maxVal).clamp(0.0, 1.0),
              lineHeight: 6,
              backgroundColor: MC.card2,
              progressColor: s.$3,
              barRadius: const Radius.circular(3),
              padding: EdgeInsets.zero,
            ),
          ]),
        )),
      ]),
    );
  }
}

class _NotConnected extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.account_balance_wallet_outlined, size: 64, color: MC.t3),
      const SizedBox(height: 16),
      Text('Wallet Not Connected', style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Connect your MetaMask or private key to view analytics', style: GoogleFonts.inter(color: MC.t2, fontSize: 14), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      GradBtn(label: 'Go to Home', icon: Icons.home_rounded, fullWidth: false, onTap: () => context.go('/home')),
    ]),
  );
}

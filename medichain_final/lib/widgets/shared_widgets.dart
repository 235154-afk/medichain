// lib/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ── COLORS ─────────────────────────────────────────────────
class MC {
  static const bg     = Color(0xFF060B18);
  static const card   = Color(0xFF0C1425);
  static const card2  = Color(0xFF111D35);
  static const p      = Color(0xFF2563EB);
  static const cyan   = Color(0xFF38BDF8);
  static const violet = Color(0xFF7C3AED);
  static const g      = Color(0xFF10B981);
  static const o      = Color(0xFFF59E0B);
  static const r      = Color(0xFFEF4444);
  static const t1     = Color(0xFFF0F6FF);
  static const t2     = Color(0xFF94A3B8);
  static const t3     = Color(0xFF475569);
  static const border = Color(0xFF1E3A5F);

  static const gradP  = [Color(0xFF2563EB), Color(0xFF7C3AED)];
  static const gradC  = [Color(0xFF38BDF8), Color(0xFF2563EB)];
  static const gradG  = [Color(0xFF10B981), Color(0xFF059669)];
  static const gradR  = [Color(0xFFEF4444), Color(0xFFDC2626)];
  static const gradO  = [Color(0xFFF59E0B), Color(0xFFD97706)];
}

// ── GRADIENT TEXT ───────────────────────────────────────────
class GradientText extends StatelessWidget {
  final String text;
  final List<Color> colors;
  final TextStyle? style;

  const GradientText(this.text, {super.key, this.colors = MC.gradC, this.style});

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (b) => LinearGradient(colors: colors).createShader(b),
    child: Text(text, style: (style ?? Theme.of(context).textTheme.displaySmall)?.copyWith(color: Colors.white)),
  );
}

// ── GLASS CARD ──────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 16,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MC.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? MC.cyan.withOpacity(0.12), width: 0.5),
        boxShadow: [BoxShadow(color: MC.p.withOpacity(0.06), blurRadius: 20, spreadRadius: -2)],
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }
}

// ── GRADIENT BUTTON ─────────────────────────────────────────
class GradBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Color> colors;
  final bool loading;
  final bool fullWidth;

  const GradBtn({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.colors = MC.gradP,
    this.loading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: loading ? [MC.t3, MC.t3] : colors),
            borderRadius: BorderRadius.circular(50),
            boxShadow: loading ? [] : [
              BoxShadow(color: colors.first.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (loading) ...[
                const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                const SizedBox(width: 10),
              ] else if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(loading ? 'Processing...' : label,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── STATUS BADGE ────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 5)],
      Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── SECTION TITLE ───────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final bool centered;

  const SectionTitle({super.key, required this.eyebrow, required this.title, this.centered = false});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: MC.cyan.withOpacity(0.08),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: MC.cyan.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.hexagon_outlined, size: 12, color: MC.cyan),
          const SizedBox(width: 6),
          Text(eyebrow, style: GoogleFonts.inter(color: MC.cyan, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
        ]),
      ),
      const SizedBox(height: 12),
      GradientText(title, colors: MC.gradC,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
    ],
  );
}

// ── STAT CARD ───────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> colors;

  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(height: 12),
      Text(value, style: GoogleFonts.spaceGrotesk(color: MC.t1, fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(label, style: GoogleFonts.inter(color: MC.t2, fontSize: 12)),
    ]),
  ).animate().fadeIn().slideY(begin: 0.2);
}

// ── CHAIN STEP ──────────────────────────────────────────────
class ChainStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final bool isLast;
  final bool isDone;

  const ChainStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    this.isLast = false,
    this.isDone = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone ? MC.g : MC.t3;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (isDone ? MC.g : MC.t3).withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        if (!isLast) Container(width: 1.5, height: 40, color: isDone ? MC.g.withOpacity(0.4) : MC.border),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(color: MC.t1, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(color: MC.t2, fontSize: 12)),
          const SizedBox(height: 2),
          Text(time, style: GoogleFonts.inter(color: MC.t3, fontSize: 11)),
          SizedBox(height: isLast ? 0 : 24),
        ]),
      )),
    ]);
  }
}

// ── TEMP CHIP ───────────────────────────────────────────────
class TempChip extends StatelessWidget {
  final String temp;
  final int statusIdx; // 0=normal, 1=warning, 2=critical

  const TempChip({super.key, required this.temp, required this.statusIdx});

  @override
  Widget build(BuildContext context) {
    final colors = [MC.g, MC.o, MC.r];
    final icons  = [Icons.thermostat, Icons.warning_amber, Icons.dangerous];
    final labels = ['Normal', 'Warning', 'Critical'];
    final c = colors[statusIdx.clamp(0,2)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icons[statusIdx.clamp(0,2)], size: 13, color: c),
        const SizedBox(width: 5),
        Text(temp, style: GoogleFonts.inter(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text(labels[statusIdx.clamp(0,2)], style: GoogleFonts.inter(color: c.withOpacity(0.8), fontSize: 11)),
      ]),
    );
  }
}

// ── COPY ADDRESS WIDGET ─────────────────────────────────────
class AddressDisplay extends StatelessWidget {
  final String address;

  const AddressDisplay({super.key, required this.address});

  String get short => address.length > 10
    ? '${address.substring(0,6)}...${address.substring(address.length-4)}'
    : address;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      Clipboard.setData(ClipboardData(text: address));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address copied!'), duration: Duration(seconds: 1)),
      );
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: MC.card2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MC.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(short,
          style: GoogleFonts.jetBrainsMono(color: MC.cyan, fontSize: 12)),
        const SizedBox(width: 6),
        const Icon(Icons.copy_rounded, size: 13, color: MC.t2),
      ]),
    ),
  );
}

// ── LOADING SHIMMER ─────────────────────────────────────────
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 100,
    decoration: BoxDecoration(
      color: MC.card2,
      borderRadius: BorderRadius.circular(16),
    ),
  ).animate(onPlay: (c) => c.repeat()).shimmer(
    duration: 1200.ms, color: MC.p.withOpacity(0.05),
  );
}

// ── TX HASH LINK ─────────────────────────────────────────────
class TxHashLink extends StatelessWidget {
  final String txHash;

  const TxHashLink({super.key, required this.txHash});

  String get short => txHash.length > 12
    ? '${txHash.substring(0,8)}...${txHash.substring(txHash.length-6)}'
    : txHash;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      Clipboard.setData(ClipboardData(text: 'https://sepolia.etherscan.io/tx/$txHash'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etherscan link copied!')),
      );
    },
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.open_in_new_rounded, size: 13, color: MC.cyan),
      const SizedBox(width: 5),
      Text(short, style: GoogleFonts.jetBrainsMono(
        color: MC.cyan, fontSize: 12, decoration: TextDecoration.underline,
        decorationColor: MC.cyan,
      )),
    ]),
  );
}

// ── BLOCKCHAIN VERIFIED BADGE ────────────────────────────────
class BlockchainBadge extends StatelessWidget {
  const BlockchainBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [MC.g.withOpacity(0.15), MC.cyan.withOpacity(0.15)]),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: MC.g.withOpacity(0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.verified_rounded, size: 14, color: MC.g),
      const SizedBox(width: 6),
      Text('Blockchain Verified', style: GoogleFonts.inter(
        color: MC.g, fontSize: 12, fontWeight: FontWeight.w700)),
    ]),
  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
}

// ── INPUT FIELD ──────────────────────────────────────────────
class MCInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboard;
  final int? maxLines;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final bool obscure;

  const MCInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboard,
    this.maxLines = 1,
    this.validator,
    this.suffix,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(color: MC.t2, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 7),
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        obscureText: obscure,
        style: GoogleFonts.inter(color: MC.t1, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ],
  );
}

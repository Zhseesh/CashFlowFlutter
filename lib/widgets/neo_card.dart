import 'package:material_ui/material_ui.dart';
import '../theme/neo_theme.dart';

class NeoCard extends StatefulWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final double radius;
  final bool thickBorder;
  final bool showShadow;
  final VoidCallback? onTap;

  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.radius = NeoRadius.reg,
    this.thickBorder = false,
    this.showShadow = true,
    this.onTap,
  });

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final bg = widget.color ?? Neo.paper(context);
    final border = widget.thickBorder ? NeoBorders.thick(ink) : NeoBorders.reg(ink);

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: widget.padding,
        transform: _pressed ? Matrix4.translationValues(4, 4, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.radius),
          border: border,
          boxShadow: (widget.showShadow && !_pressed) ? NeoShadows.sm(ink) : null,
        ),
        child: widget.child,
      ),
    );
  }
}
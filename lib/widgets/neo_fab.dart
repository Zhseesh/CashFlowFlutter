import 'package:material_ui/material_ui.dart';
import '../theme/neo_theme.dart';

class NeoFab extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool expanded;
  final String? label;
  final double size;    // TAMBAHAN
  final double radius;  // TAMBAHAN

  const NeoFab({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.expanded = false,
    this.label,
    this.size = 60,
    this.radius = 18,
  });

  @override
  State<NeoFab> createState() => _NeoFabState();
}

class _NeoFabState extends State<NeoFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final bg = widget.color ?? NeoColors.pink;
    
    // Penyesuaian otomatis berdasarkan ukuran
    final isSmall = widget.size < 50;
    final border = isSmall ? NeoBorders.reg(ink) : NeoBorders.thick(ink);
    final shadow = isSmall ? NeoShadows.sm(ink) : NeoShadows.md(ink);
    final iconSize = widget.expanded ? widget.size * 0.43 : widget.size * 0.45;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: widget.size,
        padding: widget.expanded
            ? EdgeInsets.symmetric(horizontal: widget.size * 0.3)
            : EdgeInsets.zero,
        width: widget.expanded ? null : widget.size,
        transform: _pressed
            ? Matrix4.translationValues(isSmall ? 4 : 6, isSmall ? 4 : 6, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.radius),
          border: border,
          boxShadow: _pressed ? null : shadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: iconSize, color: NeoColors.inkLight),
            if (widget.expanded && widget.label != null) ...[
              const SizedBox(width: 8),
              Text(widget.label!.toUpperCase(),
                  style: NeoText.label(12, color: NeoColors.inkLight)),
            ],
          ],
        ),
      ),
    );
  }
}
import 'package:material_ui/material_ui.dart';
import '../theme/neo_theme.dart';

class NeoFab extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool expanded;
  final String? label;

  const NeoFab({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.expanded = false,
    this.label,
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

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 60,
        padding: widget.expanded
            ? const EdgeInsets.symmetric(horizontal: 20)
            : EdgeInsets.zero,
        width: widget.expanded ? null : 60,
        transform: _pressed
            ? Matrix4.translationValues(6, 6, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: NeoBorders.thick(ink),
          boxShadow: _pressed ? null : NeoShadows.md(ink),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 26, color: NeoColors.inkLight),
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
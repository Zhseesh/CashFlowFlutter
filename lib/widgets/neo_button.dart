import 'package:material_ui/material_ui.dart';
import '../theme/neo_theme.dart';

enum NeoButtonVariant { primary, secondary, danger, ghost, income, expense }

class NeoButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final NeoButtonVariant variant;
  final bool expanded;
  final bool loading;

  const NeoButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = NeoButtonVariant.primary,
    this.expanded = false,
    this.loading = false,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;

  Color _bg() {
    switch (widget.variant) {
      case NeoButtonVariant.primary:
        return NeoColors.yellow;
      case NeoButtonVariant.secondary:
        return Neo.paper(context);
      case NeoButtonVariant.danger:
        return NeoColors.red;
      case NeoButtonVariant.ghost:
        return Colors.transparent;
      case NeoButtonVariant.income:
        return NeoColors.lime;
      case NeoButtonVariant.expense:
        return NeoColors.pink;
    }
  }

  Color _fg() {
    if (widget.variant == NeoButtonVariant.danger) return Colors.white;
    if (widget.variant == NeoButtonVariant.ghost) return Neo.ink(context);
    return NeoColors.inkLight;
  }

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final disabled = widget.onPressed == null || widget.loading;
    final isGhost = widget.variant == NeoButtonVariant.ghost;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.expanded ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        transform: _pressed ? Matrix4.translationValues(4, 4, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: disabled ? ink.withValues(alpha: 0.15) : _bg(),
          borderRadius: BorderRadius.circular(NeoRadius.reg),
          border: isGhost
              ? Border.all(color: ink, width: 3)
              : NeoBorders.reg(ink),
          boxShadow: (_pressed || isGhost || disabled) ? null : NeoShadows.sm(ink),
        ),
        child: Row(
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _fg()),
              )
            else if (widget.icon != null)
              Icon(widget.icon, size: 18, color: _fg()),
            if (widget.loading || widget.icon != null) const SizedBox(width: 8),
            Text(
              widget.label.toUpperCase(),
              style: NeoText.body(13, weight: FontWeight.w700, color: _fg()),
            ),
          ],
        ),
      ),
    );
  }
}
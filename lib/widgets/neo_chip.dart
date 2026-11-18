import 'package:material_ui/material_ui.dart';
import '../theme/neo_theme.dart';

class NeoChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  const NeoChip({
    super.key,
    required this.label,
    this.emoji,
    this.color,
    this.onTap,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final bg = color ?? Neo.paper(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 6, onDeleted != null ? 6 : 12, 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(NeoRadius.pill),
          border: NeoBorders.thin(ink),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            Text(label.toUpperCase(), style: NeoText.label(10, color: ink)),
            if (onDeleted != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDeleted,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 12, color: ink),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NeoBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const NeoBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? NeoColors.lime,
        borderRadius: BorderRadius.circular(6),
        border: NeoBorders.thin(ink),
      ),
      child: Text(label.toUpperCase(),
          style: NeoText.label(9, color: NeoColors.inkLight)),
    );
  }
}
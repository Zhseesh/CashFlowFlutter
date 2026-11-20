import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/neo_theme.dart';

class NeoDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;

  const NeoDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);

    // Cari teks dari item yang sedang terpilih
    String? selectedLabel;
    if (value != null) {
      for (var item in items) {
        if (item.value == value) {
          if (item.child is Text) {
            selectedLabel = (item.child as Text).data;
          }
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label!.toUpperCase(), style: NeoText.label(10, color: ink)),
          ),
        PopupMenuButton<T>(
          tooltip: '',
          position: PopupMenuPosition.under,
          color: Neo.paper(context),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoRadius.reg),
            side: BorderSide(color: ink, width: 3), // Border tebal ala Settings
          ),
          onSelected: onChanged,
          itemBuilder: (context) => items.map((item) {
            return PopupMenuItem<T>(
              value: item.value,
              child: item.child,
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Neo.paper(context),
              borderRadius: BorderRadius.circular(NeoRadius.reg),
              border: NeoBorders.reg(ink),
              boxShadow: NeoShadows.sm(ink),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedLabel ?? '-',
                    style: NeoText.body(14, weight: FontWeight.w600, color: ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(LucideIcons.chevronDown, size: 20, color: ink),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
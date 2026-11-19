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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label!.toUpperCase(), style: NeoText.label(10, color: ink)),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Neo.paper(context),
            borderRadius: BorderRadius.circular(NeoRadius.reg),
            border: NeoBorders.reg(ink),
            boxShadow: NeoShadows.sm(ink),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: Neo.paper(context),
              borderRadius: BorderRadius.circular(NeoRadius.reg),
              icon: Icon(LucideIcons.chevronDown, size: 20, color: ink),
              style: NeoText.body(14, weight: FontWeight.w600, color: ink),
              onChanged: onChanged,
              items: items,
            ),
          ),
        ),
      ],
    );
  }
}
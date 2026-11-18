import 'package:material_ui/material_ui.dart';
import '../theme/neo_theme.dart';

class NeoNavItem {
  final IconData icon;
  final String label;
  const NeoNavItem({required this.icon, required this.label});
}

class NeoNavbar extends StatelessWidget {
  final List<NeoNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NeoNavbar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final paper = Neo.paper(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 10 + bottomInset, left: 8, right: 8),
      decoration: BoxDecoration(
        color: paper,
        border: Border(top: BorderSide(color: ink, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          return _NeoNavItemWidget(
            item: items[i],
            active: i == currentIndex,
            ink: ink,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

class _NeoNavItemWidget extends StatelessWidget {
  final NeoNavItem item;
  final bool active;
  final Color ink;
  final VoidCallback onTap;

  const _NeoNavItemWidget({
    required this.item,
    required this.active,
    required this.ink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: active ? 14 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? NeoColors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(NeoRadius.reg),
          border: active
              ? NeoBorders.thin(ink)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: active ? NeoShadows.sm(ink) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: active ? NeoColors.inkLight : ink),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(item.label.toUpperCase(),
                          style: NeoText.label(10, color: NeoColors.inkLight)),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
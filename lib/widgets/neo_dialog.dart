import 'package:material_ui/material_ui.dart';
import '../theme/neo_theme.dart';

Future<T?> showNeoDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      final ink = Neo.ink(ctx);
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Neo.paper(ctx),
            borderRadius: BorderRadius.circular(NeoRadius.lg),
            border: NeoBorders.thick(ink),
            boxShadow: NeoShadows.md(ink),
          ),
          child: child,
        ),
      );
    },
  );
}

class NeoDialogTitle extends StatelessWidget {
  final String text;
  const NeoDialogTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text.toUpperCase(),
          style: NeoText.display(16, color: Neo.ink(context))),
    );
  }
}

class NeoDialogActions extends StatelessWidget {
  final List<Widget> children;
  const NeoDialogActions({super.key, required this.children});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

/// Kartu dengan tonal elevation Material 3 dan sudut membulat.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cs.outlineVariant.withAlpha(110)),
      ),
      child: child,
    );
  }
}

import 'package:material_ui/material_ui.dart';
import '../theme/neo_theme.dart';

class NeoSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const NeoSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = NeoRadius.sm,
  });

  @override
  State<NeoSkeleton> createState() => _NeoSkeletonState();
}

class _NeoSkeletonState extends State<NeoSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: ink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: ink.withValues(alpha: 0.2), width: 2),
        ),
      ),
    );
  }
}

class NeoSkeletonList extends StatelessWidget {
  final int count;
  const NeoSkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            const NeoSkeleton(width: 42, height: 42, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  NeoSkeleton(width: 150, height: 16),
                  SizedBox(height: 6),
                  NeoSkeleton(width: 100, height: 12),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const NeoSkeleton(width: 80, height: 20),
          ],
        ),
      )),
    );
  }
}
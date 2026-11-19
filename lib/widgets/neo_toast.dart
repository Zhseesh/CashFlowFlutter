import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../theme/neo_theme.dart';

class NeoToast {
  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    bool isRemoved = false;

    void remove() {
      if (!isRemoved) {
        isRemoved = true;
        entry.remove();
      }
    }

    entry = OverlayEntry(
      builder: (context) => _NeoToastWidget(
        message: message,
        onDismiss: remove,
      ),
    );

    overlay.insert(entry);
  }
}

class _NeoToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _NeoToastWidget({required this.message, required this.onDismiss});

  @override
  State<_NeoToastWidget> createState() => _NeoToastWidgetState();
}

class _NeoToastWidgetState extends State<_NeoToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Auto dismiss setelah 3 detik
    _timer = Timer(const Duration(seconds: 3), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) => widget.onDismiss());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final paper = Neo.paper(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      // Posisi tepat di atas navbar (navbar height ~70 + bottomInset)
      bottom: bottomInset + 80,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _offsetAnimation,
        child: GestureDetector(
          onTap: _dismiss,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(NeoRadius.reg),
                border: Border.all(color: paper, width: 2), // Inner border
                boxShadow: [
                  BoxShadow(
                    color: paper,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: paper, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: NeoText.body(13, weight: FontWeight.w600, color: paper),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
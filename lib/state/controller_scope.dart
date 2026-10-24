import 'package:flutter/widgets.dart';

import 'cashflow_controller.dart';

/// Menyediakan [CashFlowController] ke seluruh pohon widget.
class ControllerScope extends InheritedNotifier<CashFlowController> {
  const ControllerScope({
    super.key,
    required CashFlowController controller,
    required super.child,
  }) : super(notifier: controller);

  static CashFlowController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ControllerScope>();
    assert(scope != null, 'ControllerScope tidak ditemukan di pohon widget');
    return scope!.notifier!;
  }
}

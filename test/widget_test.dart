import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow/main.dart'; // ganti sesuai nama class app-mu

void main() {
  testWidgets('App renders', (tester) async {
    await tester.pumpWidget(const CashFlowApp()); // sesuaikan nama class
    expect(find.byType(CashFlowApp), findsOneWidget);
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/main.dart';

void main() {
  testWidgets('MOVA inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MovaApp());
    expect(find.text('MOVA'), findsWidgets);
  });
}
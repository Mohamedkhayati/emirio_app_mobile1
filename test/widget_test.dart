import 'package:flutter_test/flutter_test.dart';
import 'package:emirio_mobile/app/app.dart';

void main() {
  testWidgets('app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const EmirioApp());
    expect(find.text('Home'), findsOneWidget);
  });
}
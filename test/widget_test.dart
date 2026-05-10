import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emirio_mobile/app.dart';
import 'package:emirio_mobile/providers/auth_provider.dart';
import 'package:emirio_mobile/providers/cart_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App basic load test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: const EmirioApp(), // Changed from MyApp to EmirioApp
      ),
    );

    // Basic test to see if the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
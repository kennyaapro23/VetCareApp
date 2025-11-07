// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetcare_app/main.dart';

void main() {
  testWidgets('Smoke test: carga pantalla de login', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VetCareApp());

    // Espera a que se renderice el widget principal.
    await tester.pumpAndSettle();

    // Verifica que el título 'VetCare' esté presente en la pantalla de login.
    expect(find.text('VetCare'), findsOneWidget);
  });
}

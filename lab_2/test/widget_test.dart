import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:lab_2/main.dart';

void main() {
  testWidgets('renders journal trend analyzer home screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Journal Trend Analyzer'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}

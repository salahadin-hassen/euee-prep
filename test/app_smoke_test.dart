import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/main.dart';

void main() {
  testWidgets('EueePrepApp boots without error', (tester) async {
    await tester.pumpWidget(const EueePrepApp());

    expect(find.text('EUEE Prep — project skeleton'), findsOneWidget);
  });
}

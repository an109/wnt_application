// Layout checks for the shared Fare Breakup drawer (newUIWidgets/
// fare_breakup_sheet.dart) — Figma "Fare flight".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wander_nova/newUIWidgets/fare_breakup_sheet.dart';

const _sizes = <Size>[
  Size(320, 568),
  Size(360, 640),
  Size(375, 812),
  Size(430, 932),
];

const _lines = [
  FareBreakupLine(
    label: 'Base Fare',
    amount: '₹ 4,892',
    subLabel: 'Adult(s) (1 X ₹ 4,892)',
    subAmount: '₹ 4,892',
  ),
  FareBreakupLine(
    label: 'Taxes & Surcharges',
    amount: '₹ 1,892',
    subLabel: 'Adult(s) (1 X ₹ 1,892)',
    subAmount: '₹ 1,892',
  ),
  FareBreakupLine(
    label: 'Discounts',
    amount: '-₹ 892',
    subLabel: 'WNTSUPER',
    subAmount: '-₹ 892',
    isDiscount: true,
  ),
];

/// Opens the sheet through its real entry point ([FareBreakupSheet.show]),
/// which is where the modal height constraints come from.
Future<void> _open(
  WidgetTester tester, {
  List<FareBreakupLine> lines = _lines,
  String totalAmount = '₹ 6,353',
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => FareBreakupSheet.show(
              context,
              lines: lines,
              totalAmount: totalAmount,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders every line, the sub-rows and the total at all sizes',
      (tester) async {
    for (final size in _sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _open(tester);

      expect(tester.takeException(), isNull, reason: 'overflow at $size');
      expect(find.text('Fare Breakup'), findsOneWidget);
      expect(find.text('Base Fare'), findsOneWidget);
      expect(find.text('Adult(s) (1 X ₹ 4,892)'), findsOneWidget);
      expect(find.text('WNTSUPER'), findsOneWidget);
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.text('₹ 6,353'), findsOneWidget);
    }
  });

  testWidgets('close icon pops the sheet', (tester) async {
    await _open(tester);
    expect(find.text('Fare Breakup'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Fare Breakup'), findsNothing);
  });

  testWidgets('long labels / many lines do not overflow on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _open(
      tester,
      lines: List.generate(
        8,
        (i) => FareBreakupLine(
          label: 'A very very long fare component label number $i that keeps going',
          amount: '₹ 12,34,567',
          subLabel: 'Adult(s), Child(ren) and Infant(s) ($i X ₹ 9,99,999) breakdown detail',
          subAmount: '₹ 12,34,567',
        ),
      ),
      totalAmount: '₹ 98,76,543',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Total Amount'), findsOneWidget);
  });
}

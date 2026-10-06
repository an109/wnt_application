import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/injection_container.dart' as di;
import 'package:wander_nova/views/splash/screen/choose_country_screen.dart';
import 'package:wander_nova/views/splash/widgets/auth_scaffold.dart';
import 'package:wander_nova/views/splash/widgets/wander_logo.dart';

Future<void> _font() async {
  final arial = File('/System/Library/Fonts/Supplemental/Arial.ttf')
      .readAsBytesSync().buffer.asByteData();
  await (FontLoader('Roboto')..addFont(Future.value(arial))).load();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initializeDependencies();
    await _font();
  });

  Future<void> pump(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: ChooseCountryScreen(onContinue: (_) {}),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the row opens a dropdown, not a bottom sheet',
      (tester) async {
    await pump(tester);
    expect(find.byType(PopupMenuItem<SplashCountry>), findsNothing);

    await tester.tap(find.text('CHOOSE YOUR COUNTRY'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.byType(PopupMenuItem<SplashCountry>),
      findsNWidgets(SplashCountry.all.length),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the dropdown hangs below the row', (tester) async {
    await pump(tester);
    final row = tester.getRect(find.byType(ChooseCountryScreen));
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    final menu = tester.getRect(find.byType(PopupMenuItem<SplashCountry>).first);
    expect(menu.top, greaterThan(row.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the artwork climbs toward the logo as the entrance rewinds',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: ChooseCountryScreen(onContinue: (_) {}),
    ));

    final art = find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName ==
            WanderLogoLayers.countryBottomArt);

    await tester.pump(const Duration(milliseconds: 260));
    final early = tester.getRect(art);
    await tester.pumpAndSettle();
    final settled = tester.getRect(art);

    expect(early.top, lessThan(settled.top),
        reason: 'artwork should start higher and descend');
    expect(early.width, lessThan(settled.width),
        reason: 'artwork should grow into place');
  });

  testWidgets('dial picker sheet does not overflow on a short screen',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showAuthDialPicker(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

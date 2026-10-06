import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/injection_container.dart' as di;
import 'package:wander_nova/views/splash/screen/choose_country_screen.dart';
import 'package:wander_nova/views/splash/splash_screen.dart';
import 'package:wander_nova/views/splash/widgets/wander_logo.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initializeDependencies();
    final arial = File('/System/Library/Fonts/Supplemental/Arial.ttf')
        .readAsBytesSync().buffer.asByteData();
    await (FontLoader('Roboto')..addFont(Future.value(arial))).load();
  });

  testWidgets('the logo flies from the splash position to the country screen',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      navigatorKey: navigator,
      home: Scaffold(
        body: Center(
          child: Hero(
            tag: WanderLogo.heroTag,
            child: WanderLogo.still(width: 230),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final from = tester.getRect(find.byType(WanderLogo));

    navigator.currentState!.pushReplacement(
      fadeRoute(ChooseCountryScreen(onContinue: (_) {})),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    // Mid-flight there is exactly one logo, in the overlay, on its way over.
    final mid = tester.getRect(find.byType(WanderLogo));
    expect(mid, isNot(equals(from)), reason: 'hero never left the start');

    await tester.pumpAndSettle();
    final to = tester.getRect(find.byType(WanderLogo));

    expect(to, isNot(equals(from)), reason: 'hero did not move');
    expect(to.top, lessThan(from.top), reason: 'logo should end up higher');
    expect(to.width, lessThan(from.width), reason: 'logo should end smaller');
  });
}

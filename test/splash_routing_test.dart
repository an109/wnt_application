import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/injection_container.dart' as di;
import 'package:wander_nova/views/splash/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> seed(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await di.sl.reset();
    await di.initializeDependencies();
  }

  test('a stored session goes straight to the home screen', () async {
    await seed({
      'is_logged_in': true,
      'auth_token': 'token-123',
      'user_data': '{"id":1,"firstname":"Ada"}',
    });
    expect(splashDestination(), SplashDestination.home);
    expect(hasStoredSession(), isTrue);
  });

  test('a stored session skips the country step even on a fresh install',
      () async {
    // An existing user upgrading has never seen the country screen.
    await seed({
      'is_logged_in': true,
      'auth_token': 'token-123',
      'user_data': '{"id":1,"firstname":"Ada"}',
    });
    expect(splashDestination(), SplashDestination.home);
  });

  test('no session and no country choice goes to the country step', () async {
    await seed({});
    expect(splashDestination(), SplashDestination.country);
  });

  test('no session but a country already chosen goes to login', () async {
    await seed({'selected_country': 'IN'});
    expect(splashDestination(), SplashDestination.login);
  });

  test('the logged-in flag alone is not a session', () async {
    await seed({'is_logged_in': true, 'selected_country': 'IN'});
    expect(hasStoredSession(), isFalse);
    expect(splashDestination(), SplashDestination.login);
  });
}

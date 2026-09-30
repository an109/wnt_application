import 'package:flutter_test/flutter_test.dart';
import 'package:wander_nova/views/DiyHoliday/data/diy_holiday_api.dart';

/// Guards the filter values the UI can actually produce against the live
/// search endpoint.
///
/// Every one of these combinations used to return an empty list from a normal
/// tap path, which surfaced as "No packages match this search" with no way
/// back. The empty state now names and clears the offending filter, but these
/// tests exist so the underlying mismatches are visible rather than silent.
void main() {
  final api = DiyHolidayApi();
  const origin = 'new-delhi-in';
  const destination = 'kerala';

  test('an unfiltered search returns packages', () async {
    final page = await api.searchPackages(
      origin: origin,
      destination: destination,
      adults: 2,
    );
    expect(page.results, isNotEmpty,
        reason: 'the baseline search must return something');
    print('baseline: ${page.count} packages');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('max_price is compared against the party total, not per person',
      () async {
    // The two live packages total ₹79,467 and ₹85,869 for two adults —
    // ₹39,734 / ₹42,935 per person. A ceiling of ₹80,000 keeps exactly the
    // cheaper one, which is only true if the backend compares the TOTAL.
    // If this flips, the Budget section's "(trip total)" label is wrong.
    final page = await api.searchPackages(
      origin: origin,
      destination: destination,
      adults: 2,
      maxPrice: 80000,
    );
    expect(page.count, 1,
        reason: 'max_price=80000 should match the total, not per-person');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('the budget slider ceiling is above the real package totals', () async {
    // The slider's far-right position sends no ceiling at all, but every
    // position below it must be able to match something. 300000 is the
    // current _maxBudget.
    final page = await api.searchPackages(
      origin: origin,
      destination: destination,
      adults: 2,
      maxPrice: 300000,
    );
    expect(page.results, isNotEmpty,
        reason: 'the top of the budget range must still return packages');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('themes return nothing today — the empty state must stay recoverable',
      () async {
    // Documents a real data gap rather than asserting a wish: the live
    // packages carry `themes: []`, so every "Holiday By Theme" tile leads to
    // an empty list. If this ever starts returning packages, the tiles work
    // and this test should be updated to assert that instead.
    final themes = await api.getThemes();
    expect(themes, isNotEmpty);

    final page = await api.searchPackages(theme: themes.first.slug, adults: 2);
    expect(
      page.results,
      isEmpty,
      reason: 'if this now returns packages, theme tiles are live — update '
          'this test and drop the empty-state caveat',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}

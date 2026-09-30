/// Switches for UI that is built to the Figma but has no data behind it yet.
///
/// The DIY API (verified against the live host on 2026-09-30) does not return
/// star ratings, review counts, deal countdowns, part-payment amounts, weather,
/// insurance add-ons, coupons or wishlist state. The widgets for all of those
/// exist and are wired — they are just gated here so nothing invented is shown
/// to a customer.
///
/// When the backend starts sending a field, flip its flag to `true` and the
/// section appears. Each flag names the field it is waiting on, so there is no
/// guessing about what "done" means.
class DiyFeatures {
  const DiyFeatures._();

  /// Waiting on: `rating` + `review_count` on package search rows and on the
  /// hotel options rows. Drives the star row on package and hotel cards.
  static const bool ratings = false;

  /// Waiting on: a `deal` object (`ends_at`, `label`) on package search rows.
  /// Drives the "DEAL OF THE DAY · Ends in 05h 24m" ribbon.
  static const bool dealOfTheDay = false;

  /// Waiting on: `part_payment.amount` on package search rows. Drives the
  /// "Book this now by paying only ₹8,411" line.
  static const bool partPayment = false;

  /// Waiting on: a weather field (or a separate weather service) keyed by
  /// destination. Drives the "Goa · 28°C Sunny" chip on the results header.
  static const bool weather = false;

  /// Waiting on: an insurance product on the package/trip. Drives the
  /// "Travel + Medical Insurance" card on the review screen.
  static const bool insuranceAddon = false;

  /// Waiting on: a coupon endpoint. Drives "Coupon & Offers" on review.
  static const bool coupons = false;

  /// Waiting on: a saved/wishlist endpoint. Drives the heart on package cards.
  static const bool wishlist = false;

  /// Waiting on: `inclusions[]` / `cancellation_policy` / `terms` on the
  /// package. Drives the Package Inclusions, Cancellation & Date Change and
  /// Policies accordions. `counts` already backs the summary chip row, which
  /// is why that part is live.
  static const bool policyText = false;
}

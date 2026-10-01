import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

/// Every colour, radius and text style the redesigned insurance flow uses,
/// in one place so the fourteen screens stay visually identical to each
/// other and to the Figma.
///
/// Deliberately separate from [AppColors]: that palette is shared with
/// flights/hotels and changing it to match an insurance mock would move
/// those too. Anything here that happens to equal an AppColors value is a
/// coincidence of the design, not a dependency.
class InsTokens {
  const InsTokens._();

  // ----------------------------------------------------------- palette

  /// Figma's primary blue — tab text, links, "View Policy Details".
  static const blue = Color(0xFF00A1E4);

  /// The deeper blue behind headings and amounts.
  static const navy = AppColors.black;

  /// CTA orange: Explore Plans, PAY NOW, DONE, APPLY FILTER.
  static const orange = Color(0xFFFF6600);

  /// "PREMIUM" label above a price.
  static const premiumLabel = Color(0xFFFF6600);

  static const pageBg = Color(0xFFF8F9FA);
  static const cardBg = Colors.white;

  /// Hairline borders on cards and dividers.
  static const line = Color(0xFFE6E9EF);

  /// Small uppercase field labels (FROM COUNTRY, START DATE …).
  static const labelGrey = AppColors.subhead;

  /// Secondary body copy under a title.
  static const subGrey = Color(0xFF7A8494);

  /// Success green — "Individual" plan type, Total Paid.
  static const green = Color(0xFF1AA260);

  /// Discount/offer strips on the payment screen.
  static const offerBg = Color(0xFFF1FAF4);
  static const offerIcon = Color(0xFF1AA260);

  /// Error surfaces.
  static const errorBg = Color(0xFFFDECEC);
  static const errorFg = Color(0xFFB02A2A);
  static const errorIcon = Color(0xFFD23B3B);

  /// The "RECOMMENDED" ribbon on a plan card.
  static const ribbon = LinearGradient(
    colors: [Color(0xFF4FC3F7), Color(0xFF00A1E4)],
  );

  /// Confirmation screen's header band.
  static const confirmBand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
  );

  // ------------------------------------------------------------ assets

  /// Payment-method artwork, reused from the wallet checkout so insurance
  /// and wallet show the same icon for the same method.
  static const iconUpi = 'assets/NewIcons/upi.png';
  static const iconGpay = 'assets/NewIcons/gpay.png';
  static const iconCard = 'assets/NewIcons/credit.png';
  static const iconNetBanking = 'assets/NewIcons/net_banking.png';
  static const iconPayLater = 'assets/NewIcons/pay_later.png';
  static const iconWallet = 'assets/NewIcons/wallet.png';
  static const iconPayMethod = 'assets/NewIcons/paymethod.png';
  static const iconDiscount = 'assets/NewIcons/discount.png';
  static const iconArrowBack = 'assets/NewIcons/arrowBack.png';
  static const iconArrowForward = 'assets/NewIcons/arrowForward.png';
  static const iconEdit = 'assets/NewIcons/edit.png';
  static const iconFilter = 'assets/NewIcons/filter.png';
  static const iconSort = 'assets/NewIcons/sort.png';
  static const iconCalendar = 'assets/NewIcons/calender.png';
  static const iconTraveller = 'assets/NewIcons/TravellerAdult.png';

  // ----------------------------------------------------------- numbers

  static final _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// `₹ 6,784` — Indian digit grouping, no paise, as every Figma screen
  /// shows it.
  static String rupees(num value) => _money.format(value);

  /// `USD 50,000` — the coverage figure on a plan card.
  static String coverage(num value, {String currency = 'USD'}) =>
      '$currency ${NumberFormat.decimalPattern('en_US').format(value)}';

  /// `20 Sep' 26` — the date format used across the search summary,
  /// plan cards and confirmation.
  static String shortDate(DateTime d) => "${DateFormat('d MMM').format(d)}' "
      '${DateFormat('yy').format(d)}';

  /// `20 Aug, 26` — the search card's own, slightly different, format.
  static String searchDate(DateTime d) => DateFormat('d MMM, yy').format(d);

  static String weekday(DateTime d) => DateFormat('EEEE').format(d);

  static String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}

/// The white rounded card every form field, plan row and section sits on.
BoxDecoration insCard(
  BuildContext context, {
  double radius = 12,
  bool border = false,
  bool shadow = true,
}) {
  return BoxDecoration(
    color: InsTokens.cardBg,
    borderRadius: BorderRadius.circular(context.r(radius)),
    border: border ? Border.all(color: InsTokens.line) : null,
    boxShadow: shadow
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ]
        : null,
  );
}

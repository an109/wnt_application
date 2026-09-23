import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../UI_helper/navigation_queue.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../login/presentation/screen/login.dart';
import '../../domain/entities/TPollSearchEntity.dart';

/// Transport search-result card (Figma "Transport results").
///
/// Every value shown is read from the API result — nothing is hardcoded. A
/// row/label is simply omitted when the API didn't return the field.
class TpollVehicleCard extends StatelessWidget {
  final SearchResultEntity result;
  final String currencySymbol;
  final String currencyCode;
  final VoidCallback onTap;
  final String searchId;
  final String? formattedPrice;
  final Map<String, String>? formattedAmenityPrices;

  static const _border = Color(0xffE3E5E8);
  static const _panelBg = Color(0xffF0F4F9);
  static const _bulletText = Color(0xff4F4F4F);
  static const _acColor = Color(0xffF97316);
  static const _bagColor = Color(0xffE5383B);
  static const _labelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xff7AD3F7), AppColors.AppBlue],
  );

  const TpollVehicleCard({
    super.key,
    required this.result,
    required this.currencySymbol,
    required this.currencyCode,
    required this.onTap,
    required this.searchId,
    this.formattedPrice,
    this.formattedAmenityPrices,
  });

  // ── derived from the API result ─────────────────────────────────────────
  String get _title {
    final makeModel = [result.vehicleMake, result.vehicleModel]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    if (makeModel.isNotEmpty) return makeModel;
    if (result.vehicleName.isNotEmpty) return result.vehicleName;
    return result.providerName;
  }

  AmenityEntity? get _smsAmenity {
    for (final a in result.amenities) {
      if (a.key == 'sms_notifications') return a;
    }
    return null;
  }

  bool get _hasAirConditioning => result.amenities.any((a) {
        if (!a.included) return false;
        final s = '${a.key} ${a.name}'.toLowerCase();
        return s.contains('air_con') ||
            s.contains('air con') ||
            s.contains('aircon') ||
            s.contains('a/c');
      });

  List<String> get _bullets {
    final items = <String>[];

    final hours = result.freeCancellationHours;
    if (hours != null) {
      items.add(hours > 0
          ? 'Free cancellation up to $hours hrs'
          : 'Free cancellation');
    }
    if (result.tollsIncluded) items.add('Tolls included');

    final sms = _smsAmenity;
    if (sms != null) {
      final hasPrice = sms.price != null && sms.price!.value.isNotEmpty;
      final price = hasPrice
          ? (formattedAmenityPrices?[sms.key] ??
              formattedAmenityPrices?[sms.name] ??
              '$currencySymbol${sms.price!.value}')
          : null;
      items.add(price != null ? 'SMS notification $price' : 'SMS notification');
    }
    return items;
  }

  void _handleTap(BuildContext context) {
    final isLoggedIn = sl<AuthBloc>().state is AuthAuthenticated ||
        sl<PreferencesManager>().isLoggedIn();

    if (isLoggedIn) {
      onTap();
      return;
    }

    // The booking screen needs a signed-in user: park the navigation, show
    // the login popup, and LoginSuccessScreen resumes it once login succeeds.
    NavigationQueueService().setPendingNavigation(onTap);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Login',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const LoginSignupScreen(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    ).then((_) {
      // Dismissed without logging in → drop the parked navigation so it can't
      // fire later. After a successful login it was already consumed, so this
      // is a no-op.
      NavigationQueueService().clear();
    });
  }

  // ── build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.r(10));

    return Opacity(
      opacity: result.bookable ? 1 : 0.55,
      child: GestureDetector(
        onTap: result.bookable ? () => _handleTap(context) : null,
        child: Container(
          margin: EdgeInsets.only(bottom: context.h(20)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: radius,
            border: Border.all(color: _border),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: context.h(96)),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImagePanel(context),
                    Expanded(child: _buildDetails(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePanel(BuildContext context) {
    final label = result.vehicleType;
    final labelH = context.h(18);

    return Container(
      width: context.w(98),
      color: _panelBg,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: label.isNotEmpty ? labelH : 0,
            child: Padding(
              padding: EdgeInsets.all(context.w(6)),
              child: _buildVehicleImage(context),
            ),
          ),
          if (label.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: labelH,
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(gradient: _labelGradient),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleImage(BuildContext context) {
    final fallback = Center(
      child: Icon(
        Icons.directions_car,
        size: context.w(34),
        color: Colors.grey.shade300,
      ),
    );
    if (result.vehicleImageUrl.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: result.vehicleImageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => Center(
        child: SizedBox(
          width: context.w(16),
          height: context.w(16),
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.AppBlue,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => fallback,
    );
  }

  Widget _buildDetails(BuildContext context) {
    final bullets = _bullets;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(10),
        context.h(8),
        context.w(10),
        context.h(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                ),
              ),
              _buildRating(context),
            ],
          ),
          if (bullets.isNotEmpty) ...[
            SizedBox(height: context.h(4)),
            Wrap(
              spacing: context.w(8),
              runSpacing: context.h(2),
              children: bullets.map((b) => _bullet(context, b)).toList(),
            ),
          ],
          const Spacer(),
          SizedBox(height: context.h(6)),
          CustomPaint(
            size: Size(double.infinity, 1),
            painter: _DashedLinePainter(color: AppColors.lightsubhead),
          ),
          SizedBox(height: context.h(6)),
          _buildBottomRow(context),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.w(4),
          height: context.w(4),
          decoration: const BoxDecoration(
            color: _bulletText,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: context.w(4)),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: context.fs(8),
              color: _bulletText,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRating(BuildContext context) {
    final rating = result.rating?.toDouble();
    if (rating == null || rating <= 0) return const SizedBox.shrink();
    final count = result.ratingCount ?? 0;
    final stars = rating.round().clamp(1, 5);

    return Padding(
      padding: EdgeInsets.only(left: context.w(6), top: context.h(2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < stars; i++)
            Icon(Icons.star_rounded,
                size: context.w(9), color: const Color(0xffFFC107)),
          SizedBox(width: context.w(2)),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: context.fs(8),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          if (count > 0)
            Text(
              '($count)',
              style: TextStyle(
                fontSize: context.fs(6),
                color: AppColors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    final features = <Widget>[];

    void addFeature(Widget w) {
      if (features.isNotEmpty) {
        features.add(Container(
          width: 1,
          height: context.h(12),
          margin: EdgeInsets.symmetric(horizontal: context.w(7)),
          color: const Color(0xffD9D9D9),
        ));
      }
      features.add(w);
    }

    if (_hasAirConditioning) {
      addFeature(_feature(context, Icons.ac_unit_rounded, 'AC', _acColor));
    }
    if (result.maxPassengers > 0) {
      addFeature(_feature(context, Icons.person_rounded,
          '${result.maxPassengers}', AppColors.AppBlue));
    }
    if (result.maxBags > 0) {
      addFeature(_feature(
          context, Icons.luggage_rounded, '${result.maxBags}', _bagColor));
    }

    final price = formattedPrice ??
        '${CurrencyConverter.getSymbol(currencyCode)}${result.totalPriceAmount}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(mainAxisSize: MainAxisSize.min, children: features),
            ),
          ),
        ),
        SizedBox(width: context.w(6)),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: price,
                style: TextStyle(
                  fontSize: context.fs(17),
                  fontWeight: FontWeight.w500,
                  color: AppColors.AppBlue,
                ),
              ),
              TextSpan(
                text: ' /trip',
                style: TextStyle(
                  fontSize: context.fs(9),
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _feature(
      BuildContext context, IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.w(11), color: color),
        SizedBox(width: context.w(3)),
        Text(
          label,
          style: TextStyle(fontSize: context.fs(10), color: color),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 3.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      final end = x + dash > size.width ? size.width : x + dash;
      canvas.drawLine(Offset(x, 0), Offset(end, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

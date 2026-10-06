import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/injection_container.dart' as di;

import '../../../core/utils/storage/shared_preference.dart';
import '../widgets/wander_logo.dart';

/// A country the splash screen offers. The currency is what the rest of the
/// app actually consumes, through [PreferencesManager.savePreferredCurrency].
class SplashCountry {
  const SplashCountry({
    required this.isoCode,
    required this.name,
    required this.flag,
    required this.currency,
  });

  final String isoCode;
  final String name;
  final String flag;
  final String currency;

  static const india = SplashCountry(
    isoCode: 'IN',
    name: 'INDIA',
    flag: '🇮🇳',
    currency: 'INR',
  );

  static const all = <SplashCountry>[
    india,
    SplashCountry(isoCode: 'US', name: 'USA', flag: '🇺🇸', currency: 'USD'),
    SplashCountry(isoCode: 'AE', name: 'UAE', flag: '🇦🇪', currency: 'AED'),
    SplashCountry(isoCode: 'GB', name: 'UK', flag: '🇬🇧', currency: 'GBP'),
    SplashCountry(
      isoCode: 'SG',
      name: 'SINGAPORE',
      flag: '🇸🇬',
      currency: 'SGD',
    ),
    SplashCountry(
      isoCode: 'AU',
      name: 'AUSTRALIA',
      flag: '🇦🇺',
      currency: 'AUD',
    ),
    SplashCountry(
      isoCode: 'SA',
      name: 'SAUDI ARABIA',
      flag: '🇸🇦',
      currency: 'SAR',
    ),
    SplashCountry(isoCode: 'QA', name: 'QATAR', flag: '🇶🇦', currency: 'QAR'),
  ];
}

/// Second beat of the splash flow: the logo settles, then the country row and
/// the plane artwork ease in. Picking a country stores the matching currency
/// and calls [onContinue].
class ChooseCountryScreen extends StatefulWidget {
  const ChooseCountryScreen({super.key, required this.onContinue});

  /// Called with this screen's context once a country is stored, so the
  /// splash owns the decision about where the flow goes next.
  final void Function(BuildContext context) onContinue;

  @override
  State<ChooseCountryScreen> createState() => _ChooseCountryScreenState();
}

class _ChooseCountryScreenState extends State<ChooseCountryScreen>
    with SingleTickerProviderStateMixin {
  static const _entrance = Duration(milliseconds: 900);

  late final AnimationController _controller;
  SplashCountry _country = SplashCountry.india;
  bool _isContinuing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _entrance)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    if (_isContinuing) return;

    final picked = await showModalBottomSheet<SplashCountry>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CountrySheet(selected: _country),
    );
    if (picked == null || !mounted) return;

    setState(() => _country = picked);
    // Let the row repaint with the new country before moving on.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    await _continue();
  }

  Future<void> _continue() async {
    if (_isContinuing) return;
    setState(() => _isContinuing = true);

    final prefs = di.sl<PreferencesManager>();
    await prefs.saveSelectedCountry(_country.isoCode);
    // The user chose explicitly, so stop re-detecting from their IP.
    await prefs.savePreferredCurrency(_country.currency);
    await prefs.setCurrencyAutoDetect(false);

    if (!mounted) return;
    widget.onContinue(context);
  }

  Animation<double> _step(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOutQuart),
    );
  }

  Widget _rise(Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, context.w(18) * (1 - animation.value)),
          child: inner,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Plane and arc sit flush with the bottom edge.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _rise(
              _step(0.4, 1.0),
              Image.asset(
                WanderLogoLayers.countryBottomArt,
                fit: BoxFit.fitWidth,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: context.h(104)),
                Center(
                  child: Hero(
                    tag: WanderLogo.heroTag,
                    child: WanderLogo.still(width: context.w(206)),
                  ),
                ),
                SizedBox(height: context.h(92)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(28)),
                  child: _rise(_step(0.25, 0.85), _buildCountryRow()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryRow() {
    return Container(
      height: context.w(58),
      padding: EdgeInsets.only(left: context.w(12), right: context.w(4)),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F6FF),
        borderRadius: BorderRadius.circular(context.w(14)),
      ),
      child: Row(
        children: [
          Text(_country.flag, style: TextStyle(fontSize: context.fs(18))),
          SizedBox(width: context.w(10)),
          Expanded(
            flex: 3,
            child: Text(
              _country.name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: AppColors.authInk,
              ),
            ),
          ),
          SizedBox(width: context.w(6)),
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: _isContinuing ? null : _choose,
              child: Container(
                height: context.w(46),
                padding: EdgeInsets.symmetric(horizontal: context.w(10)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.AppBlue,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(context.w(10)),
                  ),
                ),
                child: _isContinuing
                    ? SizedBox(
                        width: context.w(18),
                        height: context.w(18),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'CHOOSE YOUR COUNTRY',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: context.fs(10.5),
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _isContinuing ? null : _choose,
            child: Container(
              height: context.w(46),
              width: context.w(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(context.w(10)),
                ),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: context.w(26),
                color: AppColors.OrangeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountrySheet extends StatelessWidget {
  const _CountrySheet({required this.selected});

  final SplashCountry selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(context.w(16)),
      padding: EdgeInsets.symmetric(vertical: context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.w(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: context.hp(60)),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          itemCount: SplashCountry.all.length,
          separatorBuilder: (_, __) => SizedBox(height: context.w(14)),
          itemBuilder: (context, index) {
            final country = SplashCountry.all[index];
            final isSelected = country.isoCode == selected.isoCode;

            return GestureDetector(
              onTap: () => Navigator.of(context).pop(country),
              child: Container(
                height: context.w(96),
                padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFF7F7F8),
                  borderRadius: BorderRadius.circular(context.w(18)),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.AppBlue
                        : const Color(0xFFEDEDF0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      country.flag,
                      style: TextStyle(fontSize: context.fs(40)),
                    ),
                    SizedBox(width: context.w(22)),
                    Expanded(
                      child: Text(
                        country.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(26),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                          color: AppColors.authInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

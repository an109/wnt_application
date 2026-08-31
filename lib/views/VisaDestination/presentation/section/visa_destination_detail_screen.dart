import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/entity/visaDestin_Entity.dart';
import 'package:wander_nova/views/VisaDestination/presentation/section/visa_apply_screen.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/fast_network_image_cache_manager.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/services/currency_service.dart';

class VisaDestinationDetailPage extends StatefulWidget {
  final VisaDestinationEntity destination;

  const VisaDestinationDetailPage({
    Key? key,
    required this.destination,
  }) : super(key: key);

  @override
  State<VisaDestinationDetailPage> createState() =>
      _VisaDestinationDetailPageState();
}

class _VisaDestinationDetailPageState
    extends State<VisaDestinationDetailPage> {

  int selectedTab = 0;

  // Currency state
  String _preferredSymbol = '₹';
  double _conversionRate = 1.0;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    CurrencyConverter.currencyListenable.addListener(_loadCurrency);
  }

  @override
  void dispose() {
    CurrencyConverter.currencyListenable.removeListener(_loadCurrency);
    super.dispose();
  }

  Future<void> _loadCurrency() async {
    final preferred = CurrencyConverter.getPreferredCurrency();
    if (!mounted) return;
    // Use the actual fees_currency from the first visa type (e.g. "USD"),
    // falling back to priceCurrency then 'USD'.
    final sourceCurrency = widget.destination.visaTypes.isNotEmpty
        ? widget.destination.visaTypes.first.feesCurrency
        : (widget.destination.priceCurrency.isNotEmpty
        ? widget.destination.priceCurrency
        : 'USD');
    final rate = await CurrencyService.instance.getRate(sourceCurrency, preferred);
    if (!mounted) return;
    setState(() {
      _preferredSymbol = CurrencyConverter.getSymbol(preferred);
      _conversionRate = rate;
    });
  }

  /// Convert a fee (in its feesCurrency) to the user's preferred currency.
  String _formatVisaPrice(num amount, {String? sourceCurrency}) {
    double converted;
    if (sourceCurrency != null) {
      // Per-visa-type currency — use cached rates for a synchronous conversion.
      converted = CurrencyConverter.convert(
        amount: amount.toDouble(),
        fromCurrency: sourceCurrency,
        toCurrency: CurrencyConverter.getPreferredCurrency(),
      );
    } else {
      converted = amount.toDouble() * _conversionRate;
    }
    final formatted = converted.toStringAsFixed(converted % 1 == 0 ? 0 : 2);
    return '$_preferredSymbol$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F9),

      /// ================= APP BAR =================
      appBar: AppBar(
        title: WanderNovaLogo(
          scaleFactor: context.isMobile ? 0.6 : (context.isTablet ? 0.8 : 1.0),
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(2)), // Was: context.wp(2)
            child: Image.asset(
              "assets/images/wander_logo.png",
              height: context.h(4.5), // Was: context.hp(4.5)
            ),
          )
        ],
      ),

      /// ================= BOTTOM BUTTON =================
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(context.w(12), context.h(8), context.w(12), context.h(12)),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: context.h(46),
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => VisaApplyPopup(
                    destinationName: widget.destination.name,
                    price: widget.destination.price,
                    currency: widget.destination.priceCurrency,
                    visaTypes: widget.destination.visaTypes,
                    onSuccess: () {
                      // Optional: Refresh data or show confirmation
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xff0D47A1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
              ),
              child: Text(
                "Apply Visa",
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),

      body: CustomScrollView(
        slivers: [

          /// ================= HERO =================
          SliverToBoxAdapter(
            child: _buildHeroSection(context),
          ),

          /// ================= TABS =================
          SliverToBoxAdapter(
            child: _buildTabs(),
          ),


          if (selectedTab == 0) ...[

            /// INTRO
            if (widget.destination.VisaIntroParagraph?.isNotEmpty == true)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(context.w(12), context.h(10), context.w(12), context.h(4)),
                  child: Text(
                    widget.destination.VisaIntroParagraph!,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      height: 1.5,
                      color: const Color(0xff4B5563),
                    ),
                  ),
                ),
              ),

            /// VISA TYPES
            if (widget.destination.visaTypes.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildVisaTypes(),
              ),
          ],


          if (selectedTab == 1)
            SliverToBoxAdapter(
              child: _buildSimpleSection(
                title: "Required Documents",
                icon: Icons.description_outlined,
                items: widget.destination.requirementsItems,
                iconColor: const Color(0xff6366F1),
              ),
            ),

          /// =========================================================
          /// TAB 2 -> PROCESS
          /// =========================================================

          if (selectedTab == 2)
            SliverToBoxAdapter(
              child: _buildSimpleSection(
                title: "Visa Process",
                icon: Icons.account_tree_outlined,
                items: const [
                  "Choose your visa type",
                  "Fill application form",
                  "Upload documents",
                  "Make payment",
                  "Application review",
                  "Receive approved visa",
                ],
                iconColor: const Color(0xff0D47A1),
              ),
            ),


          if (selectedTab == 3)
            SliverToBoxAdapter(
              child: _buildSimpleSection(
                title: "Frequently Asked Questions",
                icon: Icons.help_outline_rounded,
                items: const [
                  "How long does approval take?",
                  "Can I extend my visa?",
                  "Is travel insurance required?",
                  "Can I track my application?",
                  "Will I get refund if rejected?",
                ],
                iconColor: const Color(0xffFF6B00),
              ),
            ),

          if (widget.destination.priceIncludesItems.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSimpleSection(
                title: widget.destination.priceIncludesHeading.isNotEmpty
                    ? widget.destination.priceIncludesHeading
                    : "Price Includes",
                icon: Icons.check_circle_outline_rounded,
                items: widget.destination.priceIncludesItems,
                iconColor: const Color(0xff10B981),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 10),
          ),
        ],
      ),

    );
  }

  Widget _buildHeroSection(BuildContext context) {

    final image =
        widget.destination.heroBannerImage ??
            widget.destination.imageUrl;


    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ================= IMAGE BANNER =================

          Stack(
            children: [

              /// IMAGE
              SizedBox(
                height: context.isMobile ? context.h(210) : context.h(260),
                width: double.infinity,
                child: _safeNetworkImage(image),
              ),

              /// DARK OVERLAY
              Container(
                height: context.isMobile ? context.h(210) : context.h(260),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),

              /// CONTENT
              Positioned(
                left: context.w(14),
                right: context.w(14),
                bottom: context.h(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// COUNTRY
                    Text(
                      "${widget.destination.name} Visa",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.fs(24),
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),

                    SizedBox(height: context.h(6)),

                    /// REGION
                    Text(
                      widget.destination.region,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: context.h(14)),

                    /// INFO ROW
                    Row(
                      children: [

                        Expanded(
                          child: _heroMiniCard(
                            icon: Icons.schedule_rounded,
                            title: "Processing",
                            value: widget.destination.processingTime,
                          ),
                        ),

                        SizedBox(width: context.w(10)),

                        Expanded(
                          child: _heroMiniCard(
                            icon: Icons.payments_outlined,
                            title: "Starting From",
                            value: _formatVisaPrice(
                              double.tryParse(widget.destination.price) ?? 0,
                              sourceCurrency: widget.destination.priceCurrency,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMiniCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(10),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [

          Container(
            width: context.w(30),
            height: context.w(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(context.r(10)),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: context.iconSmall,
            ),
          ),

          SizedBox(width: context.w(8)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: context.h(2)),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      "Visa Types",
      "Documents",
      "Process",
      "FAQ",
    ];

    return Container(
      height: context.h(46),
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: context.w(10)),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (_, index) {
          final selected = selectedTab == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTab = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.only(right: context.w(10), top: context.h(6), bottom: context.h(6)),
              padding: EdgeInsets.symmetric(
                horizontal: context.w(14),
                vertical: context.h(6),
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xff0D47A1)
                    : const Color(0xffF1F5F9),
                borderRadius: BorderRadius.circular(context.r(20)),
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : const Color(0xff475569),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisaTypes() {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(12), context.h(10), context.w(12), 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Types Of Visa",
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
              color: const Color(0xff0D1B3D),
            ),
          ),

          SizedBox(height: context.h(10)),

          ...widget.destination.visaTypes.map(
                (visa) => Padding(
              padding: EdgeInsets.only(bottom: context.h(10)),
              child: _compactVisaCard(visa),
            ),
          ),
        ],
      ),
    );
  }


  Widget _compactVisaCard(VisaTypeEntity visa) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
          color: visa.popular
              ? const Color(0xff0D47A1)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TITLE
          Row(
            children: [

              Expanded(
                child: Text(
                  visa.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff0D1B3D),
                  ),
                ),
              ),

              if (visa.popular)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(7),
                    vertical: context.h(3),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff0D47A1),
                    borderRadius: BorderRadius.circular(context.r(20)),
                  ),
                  child: Text(
                    "Popular",
                    style: TextStyle(
                      fontSize: context.fs(9),
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: context.h(8)),

          /// DETAILS
          Wrap(
            spacing: context.w(10),
            runSpacing: context.h(4),
            children: [

              _miniText("Stay", visa.stay),
              _miniText("Entry", visa.entry),
              _miniText("Validity", visa.validity),
              _miniText("Process", visa.processing),
            ],
          ),

          SizedBox(height: context.h(10)),

          /// PRICE
          Row(
            children: [

              Expanded(
                child: Text(
                  _formatVisaPrice(visa.feesInr, sourceCurrency: visa.feesCurrency),
                  style: TextStyle(
                    fontSize: context.fs(16),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xffFF6B00),
                  ),
                ),
              ),

            ],
          )
        ],
      ),
    );
  }

  /// =========================================================
  /// MINI TEXT
  /// =========================================================

  Widget _miniText(String title, String value) {
    return RichText(
      text: TextSpan(
        children: [

          TextSpan(
            text: "$title: ",
            style: TextStyle(
              fontSize: context.fs(11),
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),

          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: context.fs(11),
              color: const Color(0xff0D1B3D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// SIMPLE SECTION
  /// =========================================================

  Widget _buildSimpleSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color iconColor,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(context.w(12), context.h(10), context.w(12), 0),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Icon(
                icon,
                size: context.iconMedium,
                color: iconColor,
              ),

              SizedBox(width: context.w(8)),

              Text(
                title,
                style: TextStyle(
                  fontSize: context.fs(15),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff0D1B3D),
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(12)),

          ...items.map(
                (e) => Padding(
              padding: EdgeInsets.only(bottom: context.h(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Padding(
                    padding: EdgeInsets.only(top: context.h(3)),
                    child: Icon(
                      Icons.check_circle,
                      size: context.iconSmall,
                      color: iconColor,
                    ),
                  ),

                  SizedBox(width: context.w(8)),

                  Expanded(
                    child: Text(
                      e,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        height: 1.4,
                        color: const Color(0xff374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// SAFE IMAGE
  /// =========================================================

  Widget _safeNetworkImage(String? imageUrl) {
    final isValid =
        imageUrl != null &&
            imageUrl.isNotEmpty &&
            imageUrl.startsWith("http");

    if (!isValid) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: FastNetworkImageCacheManager.instance,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) {
        return Container(
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.broken_image_outlined,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}
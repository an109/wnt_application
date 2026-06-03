import 'package:flutter/material.dart';
import 'package:wander_nova/views/VisaDestination/domain/entity/visaDestin_Entity.dart';
import 'package:wander_nova/views/VisaDestination/presentation/section/visa_apply_screen.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';

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
            padding: EdgeInsets.all(context.wp(2)),
            child: Image.asset(
              "assets/images/wander_nova_logo.jpg",
              height: context.hp(4.5),
            ),
          )
        ],
      ),

      /// ================= BOTTOM BUTTON =================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
            height: 46,
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
                    visaTypes: widget.destination.visaTypes,  // ← Pass the actual visa types
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Apply Visa",
                style: TextStyle(
                  fontSize: 13,
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
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Text(
                    widget.destination.VisaIntroParagraph!,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xff4B5563),
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
                iconColor: Color(0xff0D47A1),
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
                iconColor: Color(0xffFF6B00),
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
                height: 210,
                width: double.infinity,
                child: _safeNetworkImage(image),
              ),

              /// DARK OVERLAY
              Container(
                height: 210,
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
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// COUNTRY
                    Text(
                      "${widget.destination.name} Visa",
                      style:  TextStyle(
                        color: Colors.white,
                        fontSize: context.fs(24),
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// REGION
                    Text(
                      widget.destination.region,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 14),

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

                        const SizedBox(width: 10),

                        Expanded(
                          child: _heroMiniCard(
                            icon: Icons.payments_outlined,
                            title: "Starting From",
                            value:
                            "${widget.destination.priceCurrency} ${widget.destination.price}",
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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [

          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),

          const SizedBox(width: 8),

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
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  Widget _smallInfoTile({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xff0D1B3D),
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
      height: 46,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
              margin: const EdgeInsets.only(right: 10, top: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xff0D47A1)
                    : const Color(0xffF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 11,
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Types Of Visa",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xff0D1B3D),
            ),
          ),

          const SizedBox(height: 10),

          ...widget.destination.visaTypes.map(
                (visa) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _compactVisaCard(visa),
            ),
          ),
        ],
      ),
    );
  }


  Widget _compactVisaCard(VisaTypeEntity visa) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff0D1B3D),
                  ),
                ),
              ),

              if (visa.popular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff0D47A1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Popular",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          /// DETAILS
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [

              _miniText("Stay", visa.stay),
              _miniText("Entry", visa.entry),
              _miniText("Validity", visa.validity),
              _miniText("Process", visa.processing),
            ],
          ),

          const SizedBox(height: 10),

          /// PRICE
          Row(
            children: [

              Expanded(
                child: Text(
                  "${widget.destination.priceCurrency} ${visa.feesInr}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xffFF6B00),
                  ),
                ),
              ),

              // SizedBox(
              //   height: 34,
              //   child: ElevatedButton(
              //     onPressed: () {},
              //     style: ElevatedButton.styleFrom(
              //       elevation: 0,
              //       backgroundColor: const Color(0xff0D47A1),
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 14,
              //       ),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //     child: const Text(
              //       "Apply",
              //       style: TextStyle(
              //         fontSize: 11,
              //         fontWeight: FontWeight.w600,
              //         color: Colors.white,
              //       ),
              //     ),
              //   ),
              // ),
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
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),

          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xff0D1B3D),
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
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Icon(
                icon,
                size: 18,
                color: iconColor,
              ),

              const SizedBox(width: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0D1B3D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...items.map(
                (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: iconColor,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xff374151),
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

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
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
// import 'package:flutter/material.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
//
// import '../widget/destinaiton_card.dart';
//
//
// class PopularVisaDestinations extends StatelessWidget {
//   const PopularVisaDestinations({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//
//     final destinations = [
//
//       {
//         "image":
//         "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1200&auto=format&fit=crop",
//         "country": "United Arab Emirates",
//         "type": "Middle East",
//         "price": "8,619",
//         "processing": "48-96 hours",
//       },
//
//       {
//         "image":
//         "https://images.unsplash.com/photo-1485738422979-f5c462d49f74?q=80&w=1200&auto=format&fit=crop",
//         "country": "United States",
//         "type": "North America",
//         "price": "33,520",
//         "processing": "7-10 Days",
//       },
//
//       {
//         "image":
//         "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?q=80&w=1200&auto=format&fit=crop",
//         "country": "United Kingdom",
//         "type": "Europe",
//         "price": "38,309",
//         "processing": "3 Weeks",
//       },
//
//       {
//         "image":
//         "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?q=80&w=1200&auto=format&fit=crop",
//         "country": "Germany",
//         "type": "Schengen",
//         "price": "19,154",
//         "processing": "15 Days",
//       },
//     ];
//
//     return Padding(
//       padding: context.horizontalPadding,
//
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//
//           Text(
//             "Popular Destinations",
//             style: TextStyle(
//               fontSize: context.titleLarge,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//
//           SizedBox(height: context.gapLarge),
//
//           SizedBox(
//             height: context.isMobile ? 310 : 360,
//
//             child: ListView.separated(
//               scrollDirection: Axis.horizontal,
//
//               physics: context.scrollPhysics,
//
//               itemCount: destinations.length,
//
//               separatorBuilder: (_, __) =>
//                   SizedBox(width: context.gapMedium),
//
//               itemBuilder: (context, index) {
//
//                 final item = destinations[index];
//
//                 return DestinationCard(
//                   image: item["image"]!,
//                   country: item["country"]!,
//                   type: item["type"]!,
//                   price: item["price"]!,
//                   processing: item["processing"]!,
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/injection_container.dart' as di;
import 'package:wander_nova/views/Visa_popularDestinaton/presentation/widget/destinaiton_card.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../VisaDestination/domain/entity/visaDestin_Entity.dart';
import '../../../VisaDestination/presentation/section/visa_destination_detail_screen.dart';
import '../../domain/entities/visa_destination_entity.dart' hide VisaTypeEntity;
import '../bloc/visa_destination_bloc.dart';
import '../bloc/visa_destination_event.dart';
import '../bloc/visa_destination_state.dart';

class PopularVisaDestinations extends StatelessWidget {
  const PopularVisaDestinations({super.key});

  static const _primaryBlue = Color(0xFF1769F6);
  static const _textDark = Color(0xFF071638);

  @override
  Widget build(BuildContext context) {
    print('PopularVisaDestinations: Widget build called');

    return BlocProvider<VisaPopularDestinationBloc>(
      create: (context) =>
          di.sl<VisaPopularDestinationBloc>()
            ..add(const LoadVisaDestinations(domain: 'thewandernova.com')),
      child:
          BlocBuilder<VisaPopularDestinationBloc, VisaPopularDestinationState>(
            builder: (context, state) {
              print(
                'PopularVisaDestinations: State changed - ${state.runtimeType}',
              );

              if (state is VisaDestinationLoading) {
                return _buildLoading(context);
              } else if (state is VisaDestinationLoaded) {
                return _buildDestinationsList(context, state.destinations);
              } else if (state is VisaDestinationError) {
                print(
                  'PopularVisaDestinations: Error state - ${state.message}',
                );
                return _buildError(context, state.message);
              } else if (state is VisaDestinationInitial) {
                return _buildLoading(context);
              }

              print('PopularVisaDestinations: Unknown state, showing error');
              return _buildError(context, 'Unable to load destinations');
            },
          ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    print('PopularVisaDestinations: Building loading state');

    return Padding(
      padding: context.horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Popular Destinations",
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          SizedBox(height: context.h(14)),
          SizedBox(
            height: context.isMobile ? context.h(282) : context.h(330),
            child: Center(
              child: CircularProgressIndicator(
                color: _primaryBlue,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    print('PopularVisaDestinations: Building error state - $message');

    return Padding(
      padding: context.horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Popular Destinations",
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          SizedBox(height: context.h(14)),
          SizedBox(
            height: context.isMobile ? context.h(282) : context.h(330),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.shade400,
                    size: context.iconMedium,
                  ),
                  SizedBox(height: context.gapSmall),
                  Text(
                    'Failed to load destinations',
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    SizedBox(height: context.gapXSmall),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: Colors.black38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationsList(
    BuildContext context,
    List<VisaPopularDestinationEntity> destinations,
  ) {
    print(
      'PopularVisaDestinations: Building list with ${destinations.length} total destinations',
    );

    // Filter only popular and active destinations for this section
    final popularDestinations = destinations
        .where((d) => d.showInPopular && d.isActive)
        .toList();

    print(
      'PopularVisaDestinations: Filtered to ${popularDestinations.length} popular destinations',
    );

    return Padding(
      padding: context.horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Popular Destinations",
            style: TextStyle(
              fontSize: context.fs(22),
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          SizedBox(height: context.h(14)),
          SizedBox(
            height: context.isMobile ? context.h(282) : context.h(330),
            child: popularDestinations.isEmpty
                ? Center(
                    child: Text(
                      'No popular destinations available',
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: context.scrollPhysics,
                    itemCount: popularDestinations.length,
                    separatorBuilder: (_, __) => SizedBox(width: context.w(14)),
                    itemBuilder: (context, index) {
                      final destination = popularDestinations[index];
                      print(
                        'PopularVisaDestinations: Building card #$index for ${destination.name}',
                      );

                      // Format price with currency symbol
                      // final formattedPrice = _formatPrice(
                      //   destination.price,
                      //   destination.priceCurrency,
                      // );

                      final prefs = di.sl<PreferencesManager>();
                      final targetCurrency =
                          prefs.getPreferredCurrency() ?? 'INR';

                      final formattedPrice = _formatPrice(
                        destination.price,
                        destination.priceCurrency,
                        targetCurrency:
                            targetCurrency, // 🔹 Pass target currency
                      );

                      // Get image URL - prefer imageUrl, fallback to img field
                      final imageUrl = _getImageUrl(destination);

                      // Get processing time - use first visa type's processing if available
                      final processingTime = _getProcessingTime(destination);

                      return DestinationCard(
                        image: imageUrl,
                        country: destination.name,
                        type: destination.region,
                        price: formattedPrice,
                        processing: processingTime,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VisaDestinationDetailPage(
                                destination: _convertToDestinationEntity(
                                  destination,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getImageUrl(VisaPopularDestinationEntity destination) {
    // Priority: imageUrl -> img -> empty string
    if (destination.imageUrl.isNotEmpty) {
      return destination.imageUrl;
    }
    // Note: If you add 'img' field to entity, check it here as fallback
    return '';
  }

  String _getProcessingTime(VisaPopularDestinationEntity destination) {
    // Use the main processing_time field from destination
    if (destination.processingTime.isNotEmpty) {
      return destination.processingTime;
    }

    // Fallback: try to get from first visa type if available
    if (destination.visaTypes.isNotEmpty &&
        destination.visaTypes.first.processing.isNotEmpty) {
      return destination.visaTypes.first.processing;
    }

    return 'N/A';
  }

  // String _formatPrice(String price, String currency) {
  //   try {
  //     print('PopularVisaDestinations: Formatting price: $price $currency');
  //
  //     // Parse the price value
  //     final priceValue = double.tryParse(price) ?? 0.0;
  //
  //     // Format based on currency code
  //     final currencyCode = currency.toUpperCase();
  //
  //     if (currencyCode == 'USD') {
  //       // Format USD with $ symbol
  //       return '\$${priceValue.toStringAsFixed(0)}';
  //     } else if (currencyCode == 'INR') {
  //       // Format INR with ₹ symbol and Indian comma system
  //       return '₹${_formatIndianNumber(priceValue.toInt())}';
  //     } else if (currencyCode == 'EUR') {
  //       return '€${priceValue.toStringAsFixed(0)}';
  //     } else if (currencyCode == 'GBP') {
  //       return '£${priceValue.toStringAsFixed(0)}';
  //     }
  //
  //     // Default: show currency code + price
  //     return '$currencyCode ${priceValue.toStringAsFixed(0)}';
  //
  //   } catch (e) {
  //     print('PopularVisaDestinations: Price formatting error: $e');
  //     // Fallback: return original values
  //     return '$price $currency';
  //   }
  // }

  String _formatPrice(String price, String currency, {String? targetCurrency}) {
    try {
      // Parse the price value
      double priceValue = double.tryParse(price) ?? 0.0;

      // 🔹 MINIMAL CHANGE: Convert if target currency specified
      if (targetCurrency != null &&
          currency.toUpperCase() != targetCurrency.toUpperCase()) {
        priceValue = CurrencyConverter.convert(
          amount: priceValue,
          fromCurrency: currency,
          toCurrency: targetCurrency,
        );
        currency = targetCurrency; // Use target currency for display
      }

      // Format based on currency code
      final currencyCode = currency.toUpperCase();

      if (currencyCode == 'USD') {
        return '\$${priceValue.toStringAsFixed(0)}';
      } else if (currencyCode == 'INR') {
        return '₹${_formatIndianNumber(priceValue.toInt())}';
      } else if (currencyCode == 'EUR') {
        return '€${priceValue.toStringAsFixed(0)}';
      } else if (currencyCode == 'GBP') {
        return '£${priceValue.toStringAsFixed(0)}';
      } else if (currencyCode == 'AED') {
        return 'د.إ ${priceValue.toStringAsFixed(0)}';
      }

      // Default: show currency code + price
      return '$currencyCode ${priceValue.toStringAsFixed(0)}';
    } catch (e) {
      print('PopularVisaDestinations: Price formatting error: $e');
      return '$price $currency'; // Fallback
    }
  }

  String _formatIndianNumber(int num) {
    // Format number with Indian comma system: 1,00,000
    if (num < 1000) return num.toString();

    final str = num.toString();
    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);

    // Add commas to remaining digits in Indian style (every 2 digits after first)
    var formatted = '';
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        formatted += ',';
      }
      formatted += remaining[i];
    }

    return '$formatted,$lastThree';
  }

  VisaDestinationEntity _convertToDestinationEntity(
    VisaPopularDestinationEntity popular,
  ) {
    final convertedVisaTypes = popular.visaTypes
        .map(
          (visaType) => VisaTypeEntity(
            stay: visaType.stay,
            entry: visaType.entry,
            title: visaType.title,
            feesInr: visaType.feesInr,
            popular: visaType.popular,
            validity: visaType.validity,
            processing: visaType.processing,
          ),
        )
        .toList();

    return VisaDestinationEntity(
      id: popular.id,
      name: popular.name,
      region: popular.region,
      price: popular.price,
      priceCurrency: popular.priceCurrency,
      processingTime: popular.processingTime,
      heroBannerImageUrl: null,
      heroBannerImage: null,
      imageUrl: popular.imageUrl,
      VisaIntroParagraph: null,
      visaTypes: convertedVisaTypes,
      priceIncludesHeading: "Price Includes",
      priceIncludesItems: popular.priceIncludesItems,
      requirementsItems: popular.requirementsItems,
    );
  }
}

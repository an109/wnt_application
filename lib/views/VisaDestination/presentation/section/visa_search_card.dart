import 'package:flutter/material.dart';
import 'package:wander_nova/views/VisaDestination/presentation/section/visa_destination_detail_screen.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../domain/entity/visaDestin_Entity.dart';
import '../widget/visa_destination_search_tile.dart';

class VisaSearchCard extends StatefulWidget {
  final ValueChanged<VisaDestinationEntity>? onDestinationSelected;

  const VisaSearchCard({super.key, this.onDestinationSelected});

  @override
  State<VisaSearchCard> createState() => _VisaSearchCardState();
}

class _VisaSearchCardState extends State<VisaSearchCard> {
  VisaDestinationEntity? _selectedDestination;

  void _handleDestinationSelected(VisaDestinationEntity destination) {
    setState(() {
      _selectedDestination = destination;
    });
    widget.onDestinationSelected?.call(destination);
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// SEARCH BAR WITH INTEGRATED DROPDOWN
        Container(
          height: context.isMobile ? 58 : 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              if (!context.isMobile)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: context.gapLarge),

              /// Search Input with Integrated Dropdown
              Expanded(
                child: VisaDestinationSearchTile(
                  title: '',
                  hint: 'Search destination country',
                  onDestinationSelected: _handleDestinationSelected,
                ),
              ),

              /// Search Button
              Padding(
                padding: EdgeInsets.all(context.gapSmall),
                child: SizedBox(
                  height: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedDestination != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VisaDestinationDetailPage(
                              destination: _selectedDestination!,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff00A19A),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_sharp,
                      color: Colors.white,
                      size: context.iconMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../UI_helper/responsive_layout.dart';
import '../../../../../common_widgets/logo.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/baggage_option_entity.dart';
import '../../../domain/entities/meal_option_entity.dart';
import '../../../domain/entities/seat_option_entity.dart';
import '../../../domain/entities/service_selection_entity.dart';
import '../../bloc/ssr_bloc.dart';
import '../../bloc/ssr_event.dart';
import 'baggage_screen.dart';
import 'meal_screen.dart';
import 'seats_screen.dart';
import 'special_service_screen.dart';

class SSRMainScreen extends StatefulWidget {
  final String traceId;
  final String tokenId;
  final String resultIndex;
  final String endUserIp;

  const SSRMainScreen({
    super.key,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
    required this.endUserIp,
  });

  @override
  State<SSRMainScreen> createState() => _SSRMainScreenState();
}

class _SSRMainScreenState extends State<SSRMainScreen> {
  final PageController _pageController = PageController();
  late final SsrBloc _ssrBloc;
  MealOptionEntity? _selectedMeal;
  SeatOptionEntity? _selectedSeat;
  List<SpecialServiceEntity> _selectedServices = [];

  int currentIndex = 0;
  BaggageOptionEntity? _selectedBaggage;
  int? _selectedBaggageIndex;

  final List<String> titles = [
    "Baggage",
    "Meals",
    "Choose Your Seat",
    "Services",
  ];

  @override
  void initState() {
    super.initState();
    _ssrBloc = sl<SsrBloc>();

    // Pre-load SSR data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ssrBloc.add(
        LoadSsrData(
          endUserIp: widget.endUserIp,
          traceId: widget.traceId,
          tokenId: widget.tokenId,
          resultIndex: widget.resultIndex,
        ),
      );
    });
  }

  @override
  void dispose() {
    _ssrBloc.close();
    _pageController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (currentIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleBaggageSelected(
      List<BaggageOptionEntity>? options,
      int? selectedIndex,
      ) {
    if (options != null && selectedIndex != null && selectedIndex < options.length) {
      setState(() {
        _selectedBaggage = options[selectedIndex];
        _selectedBaggageIndex = selectedIndex;
      });
      print('Baggage selected: ${options[selectedIndex].code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SsrBloc>(
      create: (_) => _ssrBloc,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FA),
        appBar: AppBar(
          title: const WanderNovaLogo(scaleFactor: 0.6),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                "assets/images/wander_nova_logo.jpg",
                height: 35,
              ),
            )
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              /// TOP HEADER
              Padding(
                padding: context.horizontalPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.gapMedium),
                    Text(
                      "Customize Your Journey",
                      style: TextStyle(
                        fontSize: context.titleLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: context.gapSmall),
                    Text(
                      titles[currentIndex],
                      style: TextStyle(
                        fontSize: context.bodyLarge,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: context.gapMedium),

                    /// PROGRESS BAR
                    Row(
                      children: List.generate(
                        4,
                            (index) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: index == 3 ? 0 : 8,
                            ),
                            height: context.hp(0.8),
                            decoration: BoxDecoration(
                              color: index <= currentIndex
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.gapMedium),

              /// PAGES
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (value) {
                    setState(() {
                      currentIndex = value;
                    });
                  },
                  children: [
                    /// BAGGAGE SCREEN WITH BLOC
                    BaggageScreen(
                      traceId: widget.traceId,
                      tokenId: widget.tokenId,
                      resultIndex: widget.resultIndex,
                      endUserIp: widget.endUserIp,
                      selectedSegmentIndex: 0,
                      onBaggageSelected: _handleBaggageSelected,
                    ),

                    MealScreen(
                      traceId: widget.traceId,
                      tokenId: widget.tokenId,
                      resultIndex: widget.resultIndex,
                      onMealSelected: (meals, index) {
                        if (meals != null && index != null && index < meals.length) {
                          setState(() {
                            _selectedMeal = meals[index];
                          });
                          print('Meal selected for segment: ${meals[index].code}');
                        }
                      },
                    ),
                    SeatScreen(
                      traceId: widget.traceId,
                      tokenId: widget.tokenId,
                      resultIndex: widget.resultIndex,
                      onSeatSelected: (seat) {
                        setState(() => _selectedSeat = seat);
                      },
                    ),

                    /// SPECIAL SERVICES - NEW INTEGRATION
                    SpecialServiceScreen(
                      traceId: widget.traceId,
                      tokenId: widget.tokenId,
                      resultIndex: widget.resultIndex,
                      onServicesSelected: (services) {
                        setState(() => _selectedServices);
                      },
                    ),
                  ],
                ),
              ),

              /// BOTTOM BUTTONS
              Padding(
                padding: context.horizontalPadding,
                child: Row(
                  children: [
                    if (currentIndex != 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: previousPage,
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(
                              double.infinity,
                              context.buttonHeight,
                            ),
                          ),
                          child: const Text("Back"),
                        ),
                      ),
                      SizedBox(width: context.gapMedium),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (currentIndex == 3) {
                            // Final continue action
                            final summary = {
                              'meal': _selectedMeal?.code,
                              'seat': _selectedSeat?.seatLabel,
                              'services': _selectedServices.map((s) => s.code).toList(),
                              'traceId': widget.traceId,
                              'resultIndex': widget.resultIndex,
                            };

                            print('SSR Summary: $summary');
                            print('Continuing with selections');
                          } else {
                            nextPage();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(
                            double.infinity,
                            context.buttonHeight,
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          currentIndex == 3  ? "Continue" : "Next",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.gapLarge),
            ],
          ),
        ),
      ),
    );
  }
}
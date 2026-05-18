import 'package:equatable/equatable.dart';

abstract class PopularDestinationEvent extends Equatable {
  const PopularDestinationEvent();

  @override
  List<Object?> get props => [];
}

class FetchPopularDestinations extends PopularDestinationEvent {
  const FetchPopularDestinations();
}
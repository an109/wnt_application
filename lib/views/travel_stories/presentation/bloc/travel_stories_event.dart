import 'package:equatable/equatable.dart';

abstract class TravelStoriesEvent extends Equatable {
  const TravelStoriesEvent();

  @override
  List<Object?> get props => [];
}

class GetTravelStoriesEvent extends TravelStoriesEvent {
  final String? status;
  final String? domain;
  final int? limit;

  const GetTravelStoriesEvent({
    this.status,
    this.domain,
    this.limit,
  });

  @override
  List<Object?> get props => [status, domain, limit];
}

class GetTravelStoryBySlugEvent extends TravelStoriesEvent {
  final String slug;

  const GetTravelStoryBySlugEvent(this.slug);

  @override
  List<Object?> get props => [slug];
}

class RefreshTravelStoriesEvent extends TravelStoriesEvent {
  const RefreshTravelStoriesEvent();
}
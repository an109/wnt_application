import 'package:equatable/equatable.dart';
import '../../domain/entities/travel_stories_entity.dart';

abstract class TravelStoriesState extends Equatable {
  const TravelStoriesState();

  @override
  List<Object?> get props => [];
}

class TravelStoriesInitial extends TravelStoriesState {
  const TravelStoriesInitial();
}

class TravelStoriesLoading extends TravelStoriesState {
  const TravelStoriesLoading();
}

class TravelStoriesLoaded extends TravelStoriesState {
  final List<TravelStoryEntity> stories;
  final int? count;

  const TravelStoriesLoaded({
    required this.stories,
    this.count,
  });

  @override
  List<Object?> get props => [stories, count];
}

class TravelStoryDetailLoaded extends TravelStoriesState {
  final TravelStoryEntity story;

  const TravelStoryDetailLoaded(this.story);

  @override
  List<Object?> get props => [story];
}

class TravelStoriesError extends TravelStoriesState {
  final String message;

  const TravelStoriesError(this.message);

  @override
  List<Object?> get props => [message];
}
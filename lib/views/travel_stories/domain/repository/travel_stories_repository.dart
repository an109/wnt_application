import '../../../../core/error/data_state.dart';
import '../entities/travel_stories_entity.dart';

abstract class TravelStoriesRepository {
  Future<DataState<List<TravelStoryEntity>>> getTravelStories({
    String? status,
    String? domain,
    int? limit,
  });

  Future<DataState<TravelStoryEntity>> getTravelStoryBySlug(String slug);
}
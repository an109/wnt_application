import '../../../../core/error/data_state.dart';
import '../entities/travel_stories_entity.dart';
import '../repository/travel_stories_repository.dart';

class GetTravelStoryBySlugUseCase {
  final TravelStoriesRepository repository;

  GetTravelStoryBySlugUseCase(this.repository);

  Future<DataState<TravelStoryEntity>> call(String slug) async {
    return await repository.getTravelStoryBySlug(slug);
  }
}
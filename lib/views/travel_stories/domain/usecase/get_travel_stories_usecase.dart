import '../../../../core/error/data_state.dart';
import '../entities/travel_stories_entity.dart';
import '../repository/travel_stories_repository.dart';

class GetTravelStoriesUseCase {
  final TravelStoriesRepository repository;

  GetTravelStoriesUseCase(this.repository);

  Future<DataState<List<TravelStoryEntity>>> call({
    String? status,
    String? domain,
    int? limit,
  }) async {
    return await repository.getTravelStories(
      status: status,
      domain: domain,
      limit: limit,
    );
  }
}
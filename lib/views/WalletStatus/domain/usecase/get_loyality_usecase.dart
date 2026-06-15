import '../../../../core/error/data_state.dart';
import '../entity/loyality_entity.dart';
import '../repository/loyality_repository.dart';

class GetUserLoyaltyUseCase {
  final LoyaltyRepository repository;

  GetUserLoyaltyUseCase(this.repository);

  Future<DataState<LoyaltyEntity>> call() async {
    return await repository.getUserLoyalty();
  }
}
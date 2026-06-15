import '../../../../core/error/data_state.dart';
import '../entity/loyality_entity.dart';

abstract class LoyaltyRepository {
  Future<DataState<LoyaltyEntity>> getUserLoyalty();
}
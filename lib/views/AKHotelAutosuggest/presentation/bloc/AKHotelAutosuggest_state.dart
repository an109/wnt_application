import 'package:equatable/equatable.dart';
import '../../domain/entity/AKHotelAutosuggest_entity.dart';

abstract class AkHotelAutosuggestState extends Equatable {
  const AkHotelAutosuggestState();

  @override
  List<Object?> get props => [];
}

class AkHotelAutosuggestInitial extends AkHotelAutosuggestState {
  const AkHotelAutosuggestInitial();
}

class AkHotelAutosuggestLoading extends AkHotelAutosuggestState {
  const AkHotelAutosuggestLoading();
}

class AkHotelAutosuggestLoaded extends AkHotelAutosuggestState {
  final List<AkHotelLocationEntity> locations;

  const AkHotelAutosuggestLoaded(this.locations);

  @override
  List<Object?> get props => [locations];
}

class AkHotelAutosuggestFailed extends AkHotelAutosuggestState {
  final String message;

  const AkHotelAutosuggestFailed(this.message);

  @override
  List<Object?> get props => [message];
}

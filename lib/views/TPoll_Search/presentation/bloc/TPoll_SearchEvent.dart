import 'package:equatable/equatable.dart';

abstract class TpollSearchEvent extends Equatable {
  const TpollSearchEvent();

  @override
  List<Object?> get props => [];
}

class TpollSearchFetchEvent extends TpollSearchEvent {
  final String searchId;

  const TpollSearchFetchEvent({required this.searchId});

  @override
  List<Object?> get props => [searchId];
}

class TpollSearchRefreshEvent extends TpollSearchEvent {
  final String searchId;

  const TpollSearchRefreshEvent({required this.searchId});

  @override
  List<Object?> get props => [searchId];
}
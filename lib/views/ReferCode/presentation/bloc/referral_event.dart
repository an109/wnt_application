import 'package:equatable/equatable.dart';

abstract class ReferralEvent extends Equatable {
  const ReferralEvent();

  @override
  List<Object?> get props => [];
}

class FetchReferralEvent extends ReferralEvent {
  const FetchReferralEvent();
}
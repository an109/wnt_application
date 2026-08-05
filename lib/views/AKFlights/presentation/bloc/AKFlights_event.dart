// lib/features/akflights/presentation/bloc/akflights_event.dart

import 'package:equatable/equatable.dart';

abstract class AkflightsEvent extends Equatable {
  const AkflightsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkflightsEvent extends AkflightsEvent {
  final String tui;

  const LoadAkflightsEvent({required this.tui});

  @override
  List<Object?> get props => [tui];
}

class PollAkflightsEvent extends AkflightsEvent {
  final String tui;

  const PollAkflightsEvent({required this.tui});

  @override
  List<Object?> get props => [tui];
}

class ResetAkflightsEvent extends AkflightsEvent {
  const ResetAkflightsEvent();

  @override
  List<Object?> get props => [];
}
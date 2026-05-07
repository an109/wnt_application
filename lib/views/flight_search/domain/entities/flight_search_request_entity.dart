import 'package:equatable/equatable.dart';
import 'segment_entity.dart';

class FlightSearchRequestEntity extends Equatable {
  final String endUserIp;
  final int adultCount;
  final int childCount;
  final int infantCount;
  final int journeyType;
  final List<SegmentEntity> segments;

  const FlightSearchRequestEntity({
    required this.endUserIp,
    required this.adultCount,
    this.childCount = 0,
    this.infantCount = 0,
    required this.journeyType,
    required this.segments,
  });

  @override
  List<Object?> get props => [
    endUserIp,
    adultCount,
    childCount,
    infantCount,
    journeyType,
    segments,
  ];
}
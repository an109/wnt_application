class FareQuoteRequestModel {
  final String endUserIp;
  final String traceId;
  final String tokenId;
  final String resultIndex;

  FareQuoteRequestModel({
    required this.endUserIp,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'EndUserIp': endUserIp,
      'TraceId': traceId,
      'TokenId': tokenId,
      'ResultIndex': resultIndex,
    };
  }
}
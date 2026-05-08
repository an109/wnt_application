class GoogleAuthRequestModel {
  final String? idToken;
  final String? token;

  GoogleAuthRequestModel({
    this.idToken,
    this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      if (idToken != null) 'id_token': idToken,
      if (token != null) 'token': token,
    };
  }
}
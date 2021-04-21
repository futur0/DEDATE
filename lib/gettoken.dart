import 'dart:convert';

import 'package:http/http.dart' as http;

class TokenResponse {
  int uid;
  String token;
  TokenResponse({this.uid, this.token});
  TokenResponse.fromMap(Map<String, dynamic> map) {
    this.token = map['token'];
    this.uid = map['uid'];
  }
}

Future<TokenResponse> getToken(String channelName, bool isPublisher) async {
  var apiUrl = 'https://us-central1-dating-app-c1796.cloudfunctions.net/getAgoraToken';
  var response = await http.post(apiUrl,
      body: {'channel': channelName, 'isPublisher': '$isPublisher'});
  if (response.statusCode == 200) {
    return TokenResponse.fromMap(json.decode(response.body));
  }
  return null;
}
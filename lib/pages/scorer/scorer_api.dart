import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/scorer_auth_service.dart';

class ScorerApi {
  ScorerApi._();

  static Map<String, String> get headers {
    final token = ScorerAuthSession.current?.token ?? '';
    return {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    };
  }

  static Future<http.Response> get(String path) {
    return http.get(apiUri(path), headers: headers);
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> body) {
    return http.patch(
      apiUri(path),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }
}

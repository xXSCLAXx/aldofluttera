import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService({String? baseUrl})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: '',
            ).ifEmpty(_defaultBaseUrl);

  final String _baseUrl;

  static String get _defaultBaseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  Future<String> fetchMessage() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/message'));
    if (response.statusCode != 200) {
      throw Exception('El backend respondió con ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['message'] as String? ?? 'Respuesta vacía';
  }
}

extension on String {
  String ifEmpty(String Function() fallback) => isEmpty ? fallback() : this;
}

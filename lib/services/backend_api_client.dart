import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';

class BackendApiClient {
  BackendApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? AppEnvironmentConfig.baseUrl;
  final http.Client _client;
  final String baseUrl;

  Future<Map<String, dynamic>> getJson(String path) async {
    final r = await _client
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw HttpException('Backend request failed (${r.statusCode})');
    }
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getList(String path) async {
    final r = await _client
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw HttpException('Backend request failed (${r.statusCode})');
    }
    return jsonDecode(utf8.decode(r.bodyBytes)) as List<dynamic>;
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final r = await _client
        .put(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw HttpException('Backend request failed (${r.statusCode})');
    }
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final r = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw HttpException('Backend request failed (${r.statusCode})');
    }
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patch(String path) async {
    final r = await _client
        .patch(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw HttpException('Backend request failed (${r.statusCode})');
    }
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final r = await _client
        .patch(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw HttpException('Backend request failed (${r.statusCode})');
    }
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    final r = await _client
        .delete(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw HttpException('Backend request failed (${r.statusCode})');
    }
  }
}

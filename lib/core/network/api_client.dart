import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final String baseUrl;
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'numbaa_jwt';

  ApiClient({required this.baseUrl});

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, body['message'] as String? ?? res.body);
    }
    return body;
  }

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    final res = await http.get(_uri(path), headers: await _headers(auth: auth));
    return _parse(res);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(body));
    return _parse(res);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(_uri(path), headers: await _headers(), body: jsonEncode(body));
    return _parse(res);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(_uri(path), headers: await _headers(), body: jsonEncode(body));
    return _parse(res);
  }

  Future<Map<String, dynamic>> postFile(String path, String field, String filePath) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', _uri(path));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(field, filePath));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  Future<void> delete(String path) async {
    final res = await http.delete(_uri(path), headers: await _headers());
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(res.statusCode, body['message'] as String? ?? res.body);
    }
  }
}

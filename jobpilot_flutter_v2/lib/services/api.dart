import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The server URL is entered once on the login screen after the backend is hosted.
/// Example: https://your-jobpilot-server.onrender.com (do not add /api).
class Api {
  static const _tokenKey = 'jp_token';
  static const _baseUrlKey = 'jp_api_base_url';

  static Future<String?> token() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  static Future<void> saveToken(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, value);
    }
  }

  static Future<String> baseUrl() async =>
      (await SharedPreferences.getInstance()).getString(_baseUrlKey) ?? '';

  static Future<void> saveBaseUrl(String value) async {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized.isNotEmpty) {
      final uri = Uri.tryParse(normalized);
      if (uri == null || !uri.hasAuthority || !['https', 'http'].contains(uri.scheme)) {
        throw Exception('Enter a valid server URL beginning with https://');
      }
      if (uri.scheme != 'https' && !normalized.contains('localhost') && !normalized.contains('127.0.0.1')) {
        throw Exception('For a hosted server, use HTTPS.');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);
  }

  static Future<Uri> _uri(String path, [Map<String, String>? query]) async {
    final base = await baseUrl();
    if (base.isEmpty) {
      throw Exception('First enter your hosted JobPilot HTTPS server URL.');
    }
    return Uri.parse('$base/api$path').replace(queryParameters: query);
  }

  static Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = await _uri(path, query);
    final t = await token();
    final headers = <String, String>{'Accept': 'application/json'};
    if (t != null) headers['Authorization'] = 'Token $t';
    if (body != null) headers['Content-Type'] = 'application/json';

    late http.Response response;
    try {
      final req = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) req.body = jsonEncode(body);
      response = await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 45)),
      );
    } catch (_) {
      throw Exception('Cannot connect to JobPilot. Check your internet and server URL.');
    }
    if (response.statusCode == 204) return null;

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = {'detail': response.body};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) await saveToken(null);
      final msg = data is Map
          ? (data['detail'] ?? data.values.first)
          : 'Request failed (${response.statusCode})';
      throw Exception(msg is List ? msg.join(' ') : msg.toString());
    }
    return data;
  }

  static Future<dynamic> upload(String path, String filePath, String filename) async {
    final uri = await _uri(path);
    final req = http.MultipartRequest('POST', uri);
    final t = await token();
    if (t != null) req.headers['Authorization'] = 'Token $t';
    req.files.add(await http.MultipartFile.fromPath('file', filePath, filename: filename));
    final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 90)));
    dynamic data;
    try { data = jsonDecode(res.body); } catch (_) { data = {'detail': res.body}; }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data is Map ? (data['detail'] ?? 'Upload failed').toString() : 'Upload failed');
    }
    return data;
  }
}

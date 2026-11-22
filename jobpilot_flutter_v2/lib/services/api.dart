
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static const String _tokenKey = 'jp_token';
  static const String _baseUrlKey = 'jp_api_base_url';

  // Get saved authentication token
  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save or remove authentication token
  static Future<void> saveToken(String? value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value == null || value.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, value);
    }
  }

  // Get saved server URL
  static Future<String> baseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? '';
  }

  // Save and validate server URL
  static Future<void> saveBaseUrl(String value) async {
    final normalized = value.trim().replaceFirst(
      RegExp(r'/+$'),
      '',
    );

    if (normalized.isEmpty) {
      throw Exception('Please enter your JobPilot server URL.');
    }

    final uri = Uri.tryParse(normalized);

    if (uri == null ||
        !uri.hasAuthority ||
        !['https', 'http'].contains(uri.scheme)) {
      throw Exception(
        'Enter a valid server URL beginning with https://',
      );
    }

    if (uri.scheme != 'https' &&
        !normalized.contains('localhost') &&
        !normalized.contains('127.0.0.1')) {
      throw Exception('For a hosted server, use HTTPS.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);
  }

  // Build API endpoint URL
  static Future<Uri> _uri(
    String path, [
    Map<String, String>? query,
  ]) async {
    final base = await baseUrl();

    if (base.isEmpty) {
      throw Exception(
        'First enter your hosted JobPilot HTTPS server URL.',
      );
    }

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$base/api$cleanPath').replace(
      queryParameters: query,
    );
  }

  // Common API request method
  static Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = await _uri(path, query);
    final savedToken = await token();

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (savedToken != null && savedToken.isNotEmpty) {
      headers['Authorization'] = 'Token $savedToken';
    }

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    late http.Response response;

    try {
      final req = http.Request(method, uri);
      req.headers.addAll(headers);

      if (body != null) {
        req.body = jsonEncode(body);
      }

      response = await http.Response.fromStream(
        await req.send().timeout(
          const Duration(seconds: 45),
        ),
      );
    } catch (e) {
      throw Exception('Network Error: $e');
    }

    if (response.statusCode == 204) {
      return null;
    }

    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = {
        'detail': response.body,
      };
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      if (response.statusCode == 401) {
        await saveToken(null);
      }

      final msg = data is Map
          ? (data['detail'] ?? data.values.first)
          : 'Request failed (${response.statusCode})';

      throw Exception(
        msg is List ? msg.join(' ') : msg.toString(),
      );
    }

    return data;
  }

  // Upload file to server
  static Future<dynamic> upload(
    String path,
    String filePath,
    String filename,
  ) async {
    final uri = await _uri(path);
    final savedToken = await token();

    try {
      final req = http.MultipartRequest('POST', uri);

      req.headers['Accept'] = 'application/json';

      if (savedToken != null && savedToken.isNotEmpty) {
        req.headers['Authorization'] = 'Token $savedToken';
      }

      req.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: filename,
        ),
      );

      final response = await http.Response.fromStream(
        await req.send().timeout(
          const Duration(seconds: 90),
        ),
      );

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {
          'detail': response.body,
        };
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          data is Map
              ? (data['detail'] ?? 'Upload failed').toString()
              : 'Upload failed (${response.statusCode})',
        );
      }

      return data;
    } catch (e) {
      throw Exception('Upload Network Error: $e');
    }
  }
}

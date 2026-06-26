import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown for any non-2xx response; [message] is the server's error string.
class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;

  @override
  String toString() => message;
}

/// HTTP client for the Vidyora Rust backend. Holds the bearer token
/// (persisted to shared_preferences) for whichever role is signed in.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Where the API lives. Resolution order:
  /// 1. `--dart-define=API_BASE_URL=https://your-app.onrender.com` (release
  ///    builds — point mobile at the deployed backend).
  /// 2. Web: the same origin the app was served from, so a deployed build talks
  ///    to its own backend with no hardcoding and no CORS hop.
  /// 3. Local dev fallbacks: Android emulator → host loopback; else localhost.
  static const _envBase = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl {
    if (_envBase.isNotEmpty) return _envBase;
    if (kIsWeb) return Uri.base.origin;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8090';
    }
    return 'http://localhost:8090';
  }

  static const _kToken = 'api_token';
  static const _kRole = 'api_role'; // teacher | student
  static const _kName = 'api_name';
  static const _kSubtitle = 'api_subtitle';

  static const _timeout = Duration(seconds: 30);
  static const _uploadTimeout = Duration(seconds: 60);

  // Token + role live in the OS keychain/keystore; display fields stay in
  // shared_preferences since they're not sensitive.
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _token;
  String? role;
  String? displayName;
  String? displaySubtitle; // e.g. roll no / institution

  /// Called when a 401 is received — navigate to login.
  void Function()? onUnauthorized;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    displayName = prefs.getString(_kName);
    displaySubtitle = prefs.getString(_kSubtitle);

    // Read credentials from secure storage. If absent, migrate any legacy
    // values that an older build left in shared_preferences.
    _token = await _secure.read(key: _kToken);
    role = await _secure.read(key: _kRole);
    if (_token == null && prefs.getString(_kToken) != null) {
      _token = prefs.getString(_kToken);
      role = prefs.getString(_kRole);
      if (_token != null) await _secure.write(key: _kToken, value: _token);
      if (role != null) await _secure.write(key: _kRole, value: role);
      await prefs.remove(_kToken);
      await prefs.remove(_kRole);
    }
  }

  bool get signedIn => _token != null;

  Future<void> setSession(String token, String r) async {
    _token = token;
    role = r;
    await _secure.write(key: _kToken, value: token);
    await _secure.write(key: _kRole, value: r);
  }

  Future<void> setIdentity(String? name, String? subtitle) async {
    displayName = name;
    displaySubtitle = subtitle;
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_kName, name);
    if (subtitle != null) await prefs.setString(_kSubtitle, subtitle);
  }

  Future<void> clearSession() async {
    _token = null;
    role = null;
    displayName = null;
    displaySubtitle = null;
    await _secure.delete(key: _kToken);
    await _secure.delete(key: _kRole);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kName);
    await prefs.remove(_kSubtitle);
  }

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (_token != null) 'authorization': 'Bearer $_token',
      };

  dynamic _decode(http.Response r) {
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final message = (body is Map && body['error'] != null)
        ? body['error'] as String
        : 'Request failed (${r.statusCode})';
    if (r.statusCode == 401) {
      // Fire-and-forget: clear stored creds then redirect to login.
      clearSession();
      onUnauthorized?.call();
    }
    throw ApiException(r.statusCode, message);
  }

  Never _throwTimeout() => throw ApiException(
      -1, 'Request timed out — check your connection');

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      return _decode(await http.get(uri, headers: _headers).timeout(_timeout));
    } on TimeoutException {
      _throwTimeout();
    }
  }

  /// Raw binary GET (e.g. a source PDF). Returns null on 404.
  Future<Uint8List?> getBytes(String path) async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl$path'), headers: _headers)
          .timeout(_timeout);
      if (r.statusCode == 404) return null;
      if (r.statusCode >= 400) {
        throw ApiException(r.statusCode, 'Request failed (${r.statusCode})');
      }
      return r.bodyBytes;
    } on TimeoutException {
      _throwTimeout();
    }
  }

  Future<dynamic> post(String path, [Object? body, Duration? timeout]) async {
    try {
      return _decode(await http
          .post(Uri.parse('$baseUrl$path'),
              headers: _headers, body: body == null ? null : jsonEncode(body))
          .timeout(timeout ?? _timeout));
    } on TimeoutException {
      _throwTimeout();
    }
  }

  Future<dynamic> put(String path, Object body) async {
    try {
      return _decode(await http
          .put(Uri.parse('$baseUrl$path'),
              headers: _headers, body: jsonEncode(body))
          .timeout(_timeout));
    } on TimeoutException {
      _throwTimeout();
    }
  }

  Future<dynamic> delete(String path, Object body) async {
    try {
      final req = http.Request('DELETE', Uri.parse('$baseUrl$path'))
        ..headers.addAll(_headers)
        ..body = jsonEncode(body);
      final streamed = await req.send().timeout(_timeout);
      return _decode(await http.Response.fromStream(streamed).timeout(_timeout));
    } on TimeoutException {
      _throwTimeout();
    }
  }

  /// Multipart upload (PDF import, question images, syllabus). Extra text
  /// fields (e.g. `subject`) ride alongside the file in the same request.
  Future<dynamic> upload(String path,
      {required List<int> bytes,
      required String filename,
      Map<String, String>? fields,
      Duration? timeout}) async {
    final t = timeout ?? _uploadTimeout;
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers['authorization'] = 'Bearer $_token'
        ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename));
      if (fields != null) req.fields.addAll(fields);
      final streamed = await req.send().timeout(t);
      return _decode(await http.Response.fromStream(streamed).timeout(t));
    } on TimeoutException {
      _throwTimeout();
    }
  }
}

final api = ApiClient.instance;

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:4000/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
  }

  Future<http.Response> _authedPost(String path, Map<String, String> body) async {
    final token = await getToken();
    return http.post(Uri.parse('$baseUrl$path'), headers: {
      'Authorization': 'Bearer $token'
    }, body: body);
  }

  Future<String?> login(String email, String password) async {
    final resp = await http.post(Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    if (resp.statusCode == 200) {
      final jwt = jsonDecode(resp.body)['jwt'];
      await setToken(jwt);
      return jwt;
    }
    return null;
  }

  Future<String?> register(String email, String password, String nickname) async {
    final resp = await http.post(Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'nickname': nickname}));
    if (resp.statusCode == 200) {
      final jwt = jsonDecode(resp.body)['jwt'];
      await setToken(jwt);
      return jwt;
    }
    return null;
  }

    Future<Map<String, dynamic>?> fetchMe() async {
      final token = await getToken();
    if (token == null) return null;
    final resp = await http.get(Uri.parse('$baseUrl/me'), headers: {
      'Authorization': 'Bearer $token'
    });
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> stoneByToken(String token) async {
    final resp = await http.get(Uri.parse('$baseUrl/stones/by-token/$token'));
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    return null;
  }

  Future<Map<String, dynamic>?> activateStone(String qrToken, String name, String description) async {
    final resp = await _authedPost('/stones/activate', {
      'qrToken': qrToken,
      'name': name,
      'description': description,
    });
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    return null;
  }

  Future<List<dynamic>> listStones() async {
    final resp = await http.get(Uri.parse('$baseUrl/stones'));
    if (resp.statusCode == 200) return jsonDecode(resp.body) as List<dynamic>;
    return [];
  }

  Future<Map<String, dynamic>?> getStone(String id) async {
    final resp = await http.get(Uri.parse('$baseUrl/stones/$id'));
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    return null;
  }
}

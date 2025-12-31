import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_model.dart';

class ApiService {
  // 1. ADD '/api/match' to the end of the base URL
  static const String baseUrl = "https://squad-io-backend.onrender.com/api/match";

  final String myUserId = "11111111-1111-1111-1111-111111111111";

  Future<List<AppUser>> findTeammates() async {
    // 2. This creates the correct full path
    final response = await http.get(Uri.parse('$baseUrl/find-teammates?userId=$myUserId'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => AppUser.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load: ${response.statusCode}");
    }
  }
}
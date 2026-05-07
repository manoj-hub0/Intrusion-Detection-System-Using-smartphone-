import 'dart:convert';
import 'package:http/http.dart' as http;

class IDSApi {
  IDSApi({required this.baseUrl});
  final String baseUrl;

  Future<Map<String, dynamic>> predict(Map<String, double> features) async {
    final res = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'features': features}),
    );
    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class SignalRegistrationService {
  final String bridgeBaseUrl;

  SignalRegistrationService({required String bridgeBaseUrl})
      : bridgeBaseUrl = bridgeBaseUrl.endsWith('/')
            ? bridgeBaseUrl.substring(0, bridgeBaseUrl.length - 1)
            : bridgeBaseUrl;

  Future<Map<String, dynamic>> registrar({
    required String telefone,
    String? captchaToken,
  }) async {
    final resposta = await http.post(
      Uri.parse('$bridgeBaseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': telefone,
        if (captchaToken != null) 'captchaToken': captchaToken,
      }),
    );

    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verificar({
    required String telefone,
    required String codigo,
  }) async {
    final resposta = await http.post(
      Uri.parse('$bridgeBaseUrl/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': telefone, 'code': codigo}),
    );

    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }
}

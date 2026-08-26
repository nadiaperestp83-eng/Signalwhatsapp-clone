// lib/core/signal_user_lookup_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignalUserLookupService {
  final String bridgeBaseUrl;

  SignalUserLookupService({required String bridgeBaseUrl})
      : bridgeBaseUrl = bridgeBaseUrl.endsWith('/')
            ? bridgeBaseUrl.substring(0, bridgeBaseUrl.length - 1)
            : bridgeBaseUrl;

  /// Confirma se [recipient] (número OU username) está registrado no Signal
  /// de verdade, antes de tentar abrir um chat com ele.
  Future<Map<String, dynamic>> verificarStatus({
    required String telefoneConta,
    required String recipient,
  }) async {
    final resposta = await http.post(
      Uri.parse('$bridgeBaseUrl/getUserStatus'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': telefoneConta, 'recipient': recipient}),
    );

    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }
}

// lib/core/signal_story_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class SignalStoryService {
  final String bridgeBaseUrl;

  SignalStoryService({required String bridgeBaseUrl})
      : bridgeBaseUrl = bridgeBaseUrl.endsWith('/')
            ? bridgeBaseUrl.substring(0, bridgeBaseUrl.length - 1)
            : bridgeBaseUrl;

  /// Envia uma story já renderizada como PNG (texto + fundo/foto compostos
  /// no cliente) pra rota /uploadStory da bridge.
  ///
  /// [groupId] nulo/vazio -> posta em "My Story" (todos os contatos).
  /// [groupId] preenchido -> posta só nesse grupo (equivalente a -g GROUP_ID
  /// no signal-cli), conforme o modelo de privacidade simplificado decidido.
  Future<Map<String, dynamic>> enviarStory({
    required String telefone,
    required Uint8List imagemPng,
    String? groupId,
  }) async {
    final resposta = await http.post(
      Uri.parse('$bridgeBaseUrl/uploadStory'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': telefone,
        'imageBase64': base64Encode(imagemPng),
        'mimeType': 'image/png',
        if (groupId != null && groupId.trim().isNotEmpty) 'groupId': groupId.trim(),
      }),
    );

    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }
}

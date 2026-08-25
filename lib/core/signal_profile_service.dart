import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SignalProfileService {
  final String bridgeBaseUrl;

  SignalProfileService({required String bridgeBaseUrl})
      : bridgeBaseUrl = bridgeBaseUrl.endsWith('/')
            ? bridgeBaseUrl.substring(0, bridgeBaseUrl.length - 1)
            : bridgeBaseUrl;

  Future<Map<String, dynamic>> atualizarPerfil({
    required String telefone,
    String? nome,
    String? sobreMim,
    File? novoAvatar,
  }) async {
    String? avatarBase64;
    if (novoAvatar != null) {
      final bytes = await novoAvatar.readAsBytes();
      avatarBase64 = base64Encode(bytes);
    }

    final resposta = await http.post(
      Uri.parse('$bridgeBaseUrl/updateProfile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': telefone,
        if (nome != null) 'name': nome,
        if (sobreMim != null) 'about': sobreMim,
        if (avatarBase64 != null) 'avatarBase64': avatarBase64,
      }),
    );

    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }
}

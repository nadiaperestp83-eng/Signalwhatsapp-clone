import 'package:flutter/services.dart';

class ContatoNativo {
  final String nome;
  final String numero;

  ContatoNativo({required this.nome, required this.numero});
}

class NativeContactsService {
  // Precisa bater exatamente com o nome do canal no MainActivity.kt.
  static const MethodChannel _canal = MethodChannel('casulo/contatos_nativo');

  /// Lê a agenda direto pelo ContentResolver do Android (nome + número,
  /// nada além disso — sem foto, sem propriedades extras).
  ///
  /// Existe porque o `flutter_contacts` estava travando a thread principal
  /// do Android nesse fluxo — ANR confirmado em teste real (47s parado e o
  /// app fechando sozinho), mesmo com menos de 100 contatos na agenda e o
  /// WhatsApp oficial lendo a mesma agenda normalmente. A leitura roda em
  /// background do lado nativo (Kotlin), então essa chamada aqui não trava
  /// a UI mesmo que demore.
  static Future<List<ContatoNativo>> listarContatos() async {
    final resultado = await _canal.invokeMethod<List<dynamic>>('listarContatos');
    if (resultado == null) return [];

    return resultado
        .cast<Map<dynamic, dynamic>>()
        .map((mapa) => ContatoNativo(
              nome: (mapa['nome'] as String?) ?? '',
              numero: (mapa['numero'] as String?) ?? '',
            ))
        .toList();
  }
}

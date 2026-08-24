import 'dart:typed_data';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContatoSignal {
  final String nome;
  final Uint8List? foto;
  final String telefoneRegistrado;

  ContatoSignal({
    required this.nome,
    required this.foto,
    required this.telefoneRegistrado,
  });
}

class SignalContactsService {
  static String _somenteDigitos(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  /// Cruza a agenda do celular com os números registrados no Bridge Signal
  /// (tabela signal_bundles). Compara pelos últimos 8 dígitos, pra tolerar
  /// diferenças de formatação (DDI, espaços, traços) entre agenda e registro.
  static Future<List<ContatoSignal>> buscarContatosRegistrados() async {
    final permitido = await FlutterContacts.requestPermission();
    if (!permitido) {
      throw StateError('Permissão de contatos negada.');
    }

    final contatosDispositivo = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    final linhas = await Supabase.instance.client
        .from('signal_bundles')
        .select('user_id');

    final numerosRegistrados =
        (linhas as List).map((row) => row['user_id'] as String).toList();

    final indiceRegistrados = <String, String>{};
    for (final numero in numerosRegistrados) {
      final digitos = _somenteDigitos(numero);
      if (digitos.length >= 8) {
        indiceRegistrados[digitos.substring(digitos.length - 8)] = numero;
      }
    }

    final resultado = <ContatoSignal>[];

    for (final contato in contatosDispositivo) {
      for (final telefone in contato.phones) {
        final digitos = _somenteDigitos(telefone.number);
        if (digitos.length < 8) continue;

        final chave = digitos.substring(digitos.length - 8);
        final numeroRegistrado = indiceRegistrados[chave];

        if (numeroRegistrado != null) {
          resultado.add(ContatoSignal(
            nome: contato.displayName,
            foto: contato.photo,
            telefoneRegistrado: numeroRegistrado,
          ));
          break;
        }
      }
    }

    resultado.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return resultado;
  }
}

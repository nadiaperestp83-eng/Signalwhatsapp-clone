import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as ph;

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
  // DDIs mais comuns, do mais longo pro mais curto (importa checar os de 3
  // dígitos antes dos de 1, senão "598" (Uruguai) nunca seria encontrado
  // porque "5" ou "1" já teriam "batido" antes).
  //
  // Isso só é usado pra descobrir o DDI da PRÓPRIA conta (que já vem em
  // E.164 do cadastro no signal-cli) — não é usado pra adivinhar o país de
  // números de terceiros.
  static const List<String> _ddisConhecidos = [
    '351', // Portugal
    '598', // Uruguai
    '55',  // Brasil
    '54',  // Argentina
    '52',  // México
    '44',  // Reino Unido
    '49',  // Alemanha
    '34',  // Espanha
    '33',  // França
    '39',  // Itália
    '91',  // Índia
    '81',  // Japão
    '86',  // China
    '1',   // EUA/Canadá
  ];

  static String _somenteDigitos(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  /// Extrai o DDI do número da PRÓPRIA conta (já em E.164, ex: +5511999998888)
  /// pra usar como país padrão ao normalizar números da agenda que não têm "+".
  static String? _extrairDdiDaConta(String numeroContaE164) {
    final digitos = _somenteDigitos(numeroContaE164);
    if (digitos.length < 8) return null;

    for (final ddi in _ddisConhecidos) {
      if (digitos.startsWith(ddi)) return ddi;
    }
    // Fallback: assume 2 dígitos de DDI (cobre a maioria dos casos fora
    // da lista acima).
    return digitos.substring(0, 2);
  }

  /// Normaliza um número da agenda do aparelho pra E.164 (ex: +5511988887777).
  ///
  /// Regra (mesma ideia que Signal/Molly usam pra descoberta de contatos:
  /// comparar o número internacional completo, não um pedaço dele):
  /// - Já tem "+"  -> mantém como está (assume que já é E.164).
  /// - Começa com "00" -> "00" vira "+" (formato de discagem internacional
  ///   comum fora dos EUA).
  /// - Sem prefixo internacional -> assume o mesmo DDI da conta cadastrada
  ///   neste aparelho, removendo um possível "0" de tronco nacional.
  ///   LIMITAÇÃO CONHECIDA: se o contato for de outro país e estiver salvo
  ///   sem "+" na agenda, não tem como adivinhar — mesma limitação que
  ///   WhatsApp/Signal têm nesse caso (a orientação padrão deles também é
  ///   "salve com o código do país").
  static String? _normalizarParaE164(String numeroBruto, String? ddiPadrao) {
    var limpo = numeroBruto.replaceAll(RegExp(r'[^\d+]'), '');
    if (limpo.isEmpty) return null;

    if (limpo.startsWith('+')) {
      final digitos = limpo.substring(1);
      if (digitos.length < 8) return null;
      return '+$digitos';
    }

    if (limpo.startsWith('00')) {
      final digitos = limpo.substring(2);
      if (digitos.length < 8) return null;
      return '+$digitos';
    }

    if (ddiPadrao == null) return null;

    var nacional = limpo;
    if (nacional.startsWith('0')) {
      nacional = nacional.substring(1);
    }
    if (nacional.length < 7) return null;

    return '+$ddiPadrao$nacional';
  }

  /// Verifica no bridge (signal-cli), em lotes, quais números da lista estão
  /// registrados de verdade no Signal. Sequencial (nunca em paralelo) porque
  /// o signal-cli trava a config da conta por lockfile — chamadas
  /// concorrentes pra mesma conta podem falhar.
  static Future<Map<String, bool>> _verificarLoteNoBridge({
    required String bridgeBaseUrl,
    required String contaTelefone,
    required List<String> numeros,
    void Function(int verificados, int total)? aoProgredir,
  }) async {
    final resultado = <String, bool>{};
    const tamanhoLote = 50;
    var verificados = 0;

    for (var i = 0; i < numeros.length; i += tamanhoLote) {
      final fim = (i + tamanhoLote > numeros.length) ? numeros.length : i + tamanhoLote;
      final lote = numeros.sublist(i, fim);

      final resposta = await http.post(
        Uri.parse('$bridgeBaseUrl/getUsersStatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': contaTelefone, 'recipients': lote}),
      );

      if (resposta.statusCode != 200) {
        throw StateError(
          'Bridge retornou ${resposta.statusCode} ao verificar contatos: ${resposta.body}',
        );
      }

      final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
      final resultados = (corpo['resultados'] as List<dynamic>?) ?? [];

      for (final item in resultados) {
        final mapa = item as Map<String, dynamic>;
        final numero = mapa['numero'] as String?;
        final registrado = mapa['registrado'] == true;
        if (numero != null) resultado[numero] = registrado;
      }

      verificados += lote.length;
      aoProgredir?.call(verificados, numeros.length);
    }

    return resultado;
  }

  /// Checa a permissão de contatos com DUAS fontes de verdade, não só uma:
  ///
  /// 1) FlutterContacts.requestPermission() — dispara o diálogo do sistema
  ///    na primeira vez, mas mantém um cache interno que pode ficar
  ///    desatualizado.
  /// 2) permission_handler (Permission.contacts.status) — consulta o
  ///    Android direto, sem cache do plugin. Cobre o caso comum: usuário
  ///    negou uma vez, foi em Ajustes do sistema > Apps > Permissões e
  ///    ativou manualmente, voltou pro app — o flutter_contacts nunca fica
  ///    sabendo dessa mudança e continua dizendo "negado" mesmo com a
  ///    permissão concedida de verdade no SO. Sem essa segunda checagem, a
  ///    tela fica presa pedindo permissão pra sempre mesmo já concedida.
  static Future<bool> _temPermissaoContatos() async {
    final concedidaPeloFlutterContacts = await FlutterContacts.requestPermission();
    if (concedidaPeloFlutterContacts) return true;

    final statusReal = await ph.Permission.contacts.status;
    return statusReal.isGranted;
  }

  /// Abre a tela de configurações do próprio app no Android/iOS, pro
  /// usuário ativar a permissão manualmente quando o diálogo do sistema
  /// não aparece mais (ex: já negou "não perguntar novamente").
  static Future<void> abrirConfiguracoesDoApp() async {
    await ph.openAppSettings();
  }

  /// Cruza a agenda do celular com quem está REALMENTE registrado no Signal,
  /// perguntando direto pro bridge (signal-cli) — não mais pela tabela
  /// signal_bundles do Supabase, que só lista quem já abriu esse fork.
  static Future<List<ContatoSignal>> buscarContatosRegistrados({
    required String bridgeBaseUrl,
    required String contaTelefone,
    void Function(int verificados, int total)? aoProgredir,
  }) async {
    final permitido = await _temPermissaoContatos();
    if (!permitido) {
      throw StateError('Permissão de contatos negada.');
    }

    final contatosDispositivo = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    final ddiPadrao = _extrairDdiDaConta(contaTelefone);

    // contato -> lista de (número normalizado) pra tentar, na ordem em que
    // aparecem na agenda.
    final numerosPorContato = <int, List<String>>{};
    final todosNumerosUnicos = <String>{};

    for (var idx = 0; idx < contatosDispositivo.length; idx++) {
      final normalizados = <String>[];
      for (final telefone in contatosDispositivo[idx].phones) {
        final normalizado = _normalizarParaE164(telefone.number, ddiPadrao);
        if (normalizado != null) {
          normalizados.add(normalizado);
          todosNumerosUnicos.add(normalizado);
        }
      }
      if (normalizados.isNotEmpty) {
        numerosPorContato[idx] = normalizados;
      }
    }

    if (todosNumerosUnicos.isEmpty) {
      return [];
    }

    final registrados = await _verificarLoteNoBridge(
      bridgeBaseUrl: bridgeBaseUrl,
      contaTelefone: contaTelefone,
      numeros: todosNumerosUnicos.toList(),
      aoProgredir: aoProgredir,
    );

    final resultado = <ContatoSignal>[];

    numerosPorContato.forEach((idx, numeros) {
      for (final numero in numeros) {
        if (registrados[numero] == true) {
          final contato = contatosDispositivo[idx];
          resultado.add(ContatoSignal(
            nome: contato.displayName,
            foto: contato.photo,
            telefoneRegistrado: numero,
          ));
          break; // um match já basta pra esse contato
        }
      }
    });

    resultado.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return resultado;
  }
}

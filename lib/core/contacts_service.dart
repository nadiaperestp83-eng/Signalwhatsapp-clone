import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:whatsapp_clone/core/native_contacts_service.dart';

class ContatoSignal {
  final String nome;
  final Uint8List? foto; // sempre null por enquanto — ver nota em buscarContatosRegistrados
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

  /// Checa a permissão de contatos usando SÓ o permission_handler.
  ///
  /// O flutter_contacts foi removido de vez desse arquivo — não só da
  /// checagem de permissão, mas também da leitura da agenda (ver
  /// buscarContatosRegistrados). Log real coletado (DIAG-v1) mostrou o
  /// plugin mentindo sobre o status de permissão, e depois travando a
  /// leitura até o Android matar o app (ANR) mesmo com <100 contatos e
  /// permissão genuinamente concedida. permission_handler continua sendo
  /// usado só pra checagem — isso nunca deu problema.
  static Future<bool> _temPermissaoContatos() async {
    var status = await ph.Permission.contacts.status;
    if (status.isGranted) return true;

    status = await ph.Permission.contacts.request();
    return status.isGranted;
  }

  /// Devolve um texto de diagnóstico com o status real da permissão — pra
  /// debugar ao vivo quando a tela travar sem dar pra saber por quê.
  static Future<String> diagnosticoPermissao() async {
    final status = await ph.Permission.contacts.status;
    return 'permission_handler=$status (leitura 100% nativa agora, sem flutter_contacts)';
  }

  /// Abre a tela de configurações do próprio app no Android/iOS, pro
  /// usuário ativar a permissão manualmente quando o diálogo do sistema
  /// não aparece mais (ex: já negou "não perguntar novamente").
  static Future<void> abrirConfiguracoesDoApp() async {
    await ph.openAppSettings();
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

  /// Cruza a agenda do celular com quem está REALMENTE registrado no Signal.
  ///
  /// A leitura da agenda agora é 100% nativa (NativeContactsService, via
  /// ContentResolver direto), não passa mais pelo flutter_contacts em
  /// nenhum ponto — plugin removido de vez desse fluxo depois de ANR
  /// confirmado em teste real. Sem foto por enquanto (a leitura nativa só
  /// traz nome + número); dá pra adicionar foto depois com outra consulta
  /// nativa se fizer falta.
  static Future<List<ContatoSignal>> buscarContatosRegistrados({
    required String bridgeBaseUrl,
    required String contaTelefone,
    void Function(int verificados, int total)? aoProgredir,
  }) async {
    final permitido = await _temPermissaoContatos();
    if (!permitido) {
      throw StateError('Permissão de contatos negada.');
    }

    final contatosDispositivo = await NativeContactsService.listarContatos().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw StateError(
        'A leitura nativa da agenda travou em 15s. Essa consulta já não '
        'depende mais do flutter_contacts — se travar aqui também, o '
        'problema não é mais de plugin, é outra coisa (ex: permissão '
        'bloqueada em nível de sistema, ou muitos contatos duplicados).',
      ),
    );

    final ddiPadrao = _extrairDdiDaConta(contaTelefone);

    // numero E.164 -> nome (um por linha, já que a consulta nativa devolve
    // uma linha por número de telefone, não por "pessoa").
    final candidatos = <MapEntry<String, String>>[];
    final todosNumerosUnicos = <String>{};

    for (final contato in contatosDispositivo) {
      final normalizado = _normalizarParaE164(contato.numero, ddiPadrao);
      if (normalizado == null) continue;
      candidatos.add(MapEntry(normalizado, contato.nome));
      todosNumerosUnicos.add(normalizado);
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
    final jaAdicionado = <String>{};

    for (final candidato in candidatos) {
      final numero = candidato.key;
      final nome = candidato.value;
      final chave = '$nome|$numero';

      if (registrados[numero] == true && !jaAdicionado.contains(chave)) {
        resultado.add(ContatoSignal(
          nome: nome.isEmpty ? numero : nome,
          foto: null,
          telefoneRegistrado: numero,
        ));
        jaAdicionado.add(chave);
      }
    }

    resultado.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return resultado;
  }
}

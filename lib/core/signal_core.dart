import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class MensagemDescriptografada {
  final String remetente;
  final String texto;
  final DateTime timestamp;

  MensagemDescriptografada({
    required this.remetente,
    required this.texto,
    required this.timestamp,
  });
}

class ConversaResumo {
  final String contatoId;
  final String ultimaMensagem;
  final DateTime timestamp;
  final bool ultimaFoiEnviadaPorMim;

  ConversaResumo({
    required this.contatoId,
    required this.ultimaMensagem,
    required this.timestamp,
    required this.ultimaFoiEnviadaPorMim,
  });

  Map<String, dynamic> toJson() => {
        'contatoId': contatoId,
        'ultimaMensagem': ultimaMensagem,
        'timestamp': timestamp.toIso8601String(),
        'ultimaFoiEnviadaPorMim': ultimaFoiEnviadaPorMim,
      };

  factory ConversaResumo.fromJson(Map<String, dynamic> json) => ConversaResumo(
        contatoId: json['contatoId'] as String,
        ultimaMensagem: json['ultimaMensagem'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        ultimaFoiEnviadaPorMim: json['ultimaFoiEnviadaPorMim'] as bool,
      );
}

class SignalCore {
  static final SignalCore _instance = SignalCore._internal();
  factory SignalCore() => _instance;
  SignalCore._internal();

  bool _inicializado = false;
  late SupabaseClient _supabase;
  RealtimeChannel? _canal;
  String _meuUserId = '';

  late IdentityKeyPair _identityKeyPair;
  late int _registrationId;
  late SignedPreKeyRecord _signedPreKey;

  final InMemorySessionStore _sessionStore = InMemorySessionStore();
  final InMemoryPreKeyStore _preKeyStore = InMemoryPreKeyStore();
  final InMemorySignedPreKeyStore _signedPreKeyStore = InMemorySignedPreKeyStore();
  late InMemoryIdentityKeyStore _identityKeyStore;

  final Set<String> _sessoesEstabelecidas = {};

  final StreamController<MensagemDescriptografada> _streamController =
      StreamController<MensagemDescriptografada>.broadcast();

  Stream<MensagemDescriptografada> get mensagensRecebidas => _streamController.stream;
  bool get estaInicializado => _inicializado;

  // ===== Índice local de conversas (persistido no dispositivo) =====

  final Map<String, ConversaResumo> _conversas = {};
  final StreamController<List<ConversaResumo>> _conversasController =
      StreamController<List<ConversaResumo>>.broadcast();

  Stream<List<ConversaResumo>> get conversas => _conversasController.stream;

  String get _chavePersistencia => 'conversas_$_meuUserId';

  Future<void> _carregarConversasPersistidas() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_chavePersistencia);
    if (bruto == null) return;

    final List<dynamic> lista = jsonDecode(bruto) as List<dynamic>;
    for (final item in lista) {
      final resumo = ConversaResumo.fromJson(item as Map<String, dynamic>);
      _conversas[resumo.contatoId] = resumo;
    }
    _emitirConversas();
  }

  Future<void> _persistirConversas() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = _conversas.values.map((c) => c.toJson()).toList();
    await prefs.setString(_chavePersistencia, jsonEncode(lista));
  }

  void _emitirConversas() {
    final lista = _conversas.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _conversasController.add(lista);
  }

  void _atualizarConversa({
    required String contatoId,
    required String ultimaMensagem,
    required bool enviadaPorMim,
  }) {
    _conversas[contatoId] = ConversaResumo(
      contatoId: contatoId,
      ultimaMensagem: ultimaMensagem,
      timestamp: DateTime.now(),
      ultimaFoiEnviadaPorMim: enviadaPorMim,
    );
    _emitirConversas();
    _persistirConversas();
  }

  // ===== Inicialização =====

  Future<void> inicializarCasulo({required String meuUserId}) async {
    if (_inicializado) return;
    _meuUserId = meuUserId;
    _supabase = Supabase.instance.client;

    _identityKeyPair = generateIdentityKeyPair();
    _registrationId = generateRegistrationId(false);
    _identityKeyStore = InMemoryIdentityKeyStore(_identityKeyPair, _registrationId);

    final preKeys = generatePreKeys(0, 100);
    _signedPreKey = generateSignedPreKey(_identityKeyPair, 0);

    for (final p in preKeys) {
      await _preKeyStore.storePreKey(p.id, p);
    }
    await _signedPreKeyStore.storeSignedPreKey(_signedPreKey.id, _signedPreKey);

    await _publicarMeuBundle(preKeys);
    await _carregarConversasPersistidas();
    _escutarMensagensEntrantes();

    _inicializado = true;
  }

  Future<void> encerrarCasulo() async {
    await _canal?.unsubscribe();
    _inicializado = false;
  }

  Future<void> _publicarMeuBundle(List<PreKeyRecord> preKeys) async {
    await _supabase.from('signal_bundles').upsert({
      'user_id': _meuUserId,
      'registration_id': _registrationId,
      'identity_key': base64Encode(_identityKeyPair.getPublicKey().serialize()),
      'signed_pre_key_id': _signedPreKey.id,
      'signed_pre_key_public':
          base64Encode(_signedPreKey.getKeyPair().publicKey.serialize()),
      'signed_pre_key_signature': base64Encode(_signedPreKey.signature),
    });

    final linhas = preKeys
        .map((pk) => {
              'user_id': _meuUserId,
              'pre_key_id': pk.id,
              'pre_key_public': base64Encode(pk.getKeyPair().publicKey.serialize()),
            })
        .toList();

    await _supabase.from('signal_prekeys').insert(linhas);
  }

  void _escutarMensagensEntrantes() {
    _canal = _supabase
        .channel('mensagens:$_meuUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'signal_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: _meuUserId,
          ),
          callback: (payload) => _processarMensagemEntrante(payload.newRecord),
        )
        .subscribe();
  }

  Future<void> _garantirSessao(String userId) async {
    if (_sessoesEstabelecidas.contains(userId)) return;

    final address = SignalProtocolAddress(userId, 1);
    if (await _sessionStore.containsSession(address)) {
      _sessoesEstabelecidas.add(userId);
      return;
    }

    final bundleRow =
        await _supabase.from('signal_bundles').select().eq('user_id', userId).maybeSingle();

    if (bundleRow == null) {
      throw StateError('Usuário $userId ainda não publicou um bundle de chaves.');
    }

    final preKeyResult =
        await _supabase.rpc('consume_one_time_prekey', params: {'target_user_id': userId});

    if (preKeyResult is! List || preKeyResult.isEmpty) {
      throw StateError(
        'Usuário $userId está sem one-time prekeys disponíveis no momento. '
        'Ele precisa reabrir o app pra repor o lote.',
      );
    }

    final preKeyId = preKeyResult.first['pre_key_id'] as int;
    final preKeyPublicB64 = preKeyResult.first['pre_key_public'] as String;
    final preKeyPublic = Curve.decodePoint(base64Decode(preKeyPublicB64), 0);

    final identityKey =
        IdentityKey(Curve.decodePoint(base64Decode(bundleRow['identity_key']), 0));
    final signedPreKeyPublic =
        Curve.decodePoint(base64Decode(bundleRow['signed_pre_key_public']), 0);
    final signedPreKeySignature = base64Decode(bundleRow['signed_pre_key_signature']);

    final bundle = PreKeyBundle(
      bundleRow['registration_id'] as int,
      1,
      preKeyId,
      preKeyPublic,
      bundleRow['signed_pre_key_id'] as int,
      signedPreKeyPublic,
      signedPreKeySignature,
      identityKey,
    );

    final sessionBuilder = SessionBuilder(
      _sessionStore,
      _preKeyStore,
      _signedPreKeyStore,
      _identityKeyStore,
      address,
    );

    await sessionBuilder.processPreKeyBundle(bundle);
    _sessoesEstabelecidas.add(userId);
  }

  Future<void> enviarMensagemSegura(String numeroDestino, String textoPuro) async {
    if (!_inicializado) {
      throw StateError('SignalCore não inicializado. Chame inicializarCasulo() primeiro.');
    }

    await _garantirSessao(numeroDestino);

    final address = SignalProtocolAddress(numeroDestino, 1);
    final sessionCipher = SessionCipher(
      _sessionStore,
      _preKeyStore,
      _signedPreKeyStore,
      _identityKeyStore,
      address,
    );

    final ciphertextMessage =
        await sessionCipher.encrypt(Uint8List.fromList(utf8.encode(textoPuro)));

    await _supabase.from('signal_messages').insert({
      'sender_id': _meuUserId,
      'recipient_id': numeroDestino,
      'payload': base64Encode(ciphertextMessage.serialize()),
      'payload_type': ciphertextMessage.getType(),
    });

    _atualizarConversa(
      contatoId: numeroDestino,
      ultimaMensagem: textoPuro,
      enviadaPorMim: true,
    );
  }

  Future<void> _processarMensagemEntrante(Map<String, dynamic> row) async {
    try {
      final String remetente = row['sender_id'] as String;
      final Uint8List payloadBytes = base64Decode(row['payload'] as String);
      final int payloadTipo = row['payload_type'] as int;

      final address = SignalProtocolAddress(remetente, 1);
      final sessionCipher = SessionCipher(
        _sessionStore,
        _preKeyStore,
        _signedPreKeyStore,
        _identityKeyStore,
        address,
      );

      Uint8List textoPlanoBytes;

      if (payloadTipo == CiphertextMessage.prekeyType) {
        final mensagem = PreKeySignalMessage(payloadBytes);
        textoPlanoBytes = await sessionCipher.decrypt(mensagem);
      } else {
        final mensagem = SignalMessage.fromSerialized(payloadBytes);
        textoPlanoBytes = await sessionCipher.decryptFromSignal(mensagem);
      }

      _sessoesEstabelecidas.add(remetente);
      final textoPlano = utf8.decode(textoPlanoBytes);

      _streamController.add(
        MensagemDescriptografada(
          remetente: remetente,
          texto: textoPlano,
          timestamp: DateTime.now(),
        ),
      );

      _atualizarConversa(
        contatoId: remetente,
        ultimaMensagem: textoPlano,
        enviadaPorMim: false,
      );

      await _supabase.from('signal_messages').delete().eq('id', row['id']);
    } catch (e) {
      print('Erro ao processar mensagem entrante: $e');
    }
  }
}

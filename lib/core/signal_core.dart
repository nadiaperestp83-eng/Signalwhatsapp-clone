import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libsignal/libsignal.dart';

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

  /// Chame isso DEPOIS de Supabase.initialize() no main.dart e depois do login.
  Future<void> inicializarCasulo({required String meuUserId}) async {
    if (_inicializado) return;
    _meuUserId = meuUserId;
    _supabase = Supabase.instance.client;

    _identityKeyPair = IdentityKeyPair.generate();
    _registrationId = generateRegistrationId(false);
    _identityKeyStore = InMemoryIdentityKeyStore(_identityKeyPair, _registrationId);

    final signedPreKeyId = Random.secure().nextInt(0xFFFFFF);
    _signedPreKey = generateSignedPreKey(_identityKeyPair, signedPreKeyId);
    _signedPreKeyStore.storeSignedPreKey(signedPreKeyId, _signedPreKey);

    final preKeys = generatePreKeys(0, 100);
    for (final pk in preKeys) {
      _preKeyStore.storePreKey(pk.id, pk);
    }

    await _publicarMeuBundle(preKeys);
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

    final address = ProtocolAddress(userId, 1);
    if (_sessionStore.containsSession(address)) {
      _sessoesEstabelecidas.add(userId);
      return;
    }

    final bundleRow =
        await _supabase.from('signal_bundles').select().eq('user_id', userId).maybeSingle();

    if (bundleRow == null) {
      throw StateError('Usuário $userId ainda não publicou um bundle de chaves.');
    }

    final preKeyResult = await _supabase
        .rpc('consume_one_time_prekey', params: {'target_user_id': userId});

    int? preKeyId;
    String? preKeyPublic;
    if (preKeyResult is List && preKeyResult.isNotEmpty) {
      preKeyId = preKeyResult.first['pre_key_id'] as int?;
      preKeyPublic = preKeyResult.first['pre_key_public'] as String?;
    }

    final identityKey = IdentityKey.fromBytes(base64Decode(bundleRow['identity_key']), 0);
    final signedPreKeyPublic =
        Curve.decodePoint(base64Decode(bundleRow['signed_pre_key_public']), 0);
    final signedPreKeySignature = base64Decode(bundleRow['signed_pre_key_signature']);

    final bundle = PreKeyBundle(
      bundleRow['registration_id'] as int,
      1,
      preKeyId,
      preKeyId != null ? Curve.decodePoint(base64Decode(preKeyPublic!), 0) : null,
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

    sessionBuilder.processPreKeyBundle(bundle);
    _sessoesEstabelecidas.add(userId);
  }

  Future<void> enviarMensagemSegura(String numeroDestino, String textoPuro) async {
    if (!_inicializado) {
      throw StateError('SignalCore não inicializado. Chame inicializarCasulo() primeiro.');
    }

    await _garantirSessao(numeroDestino);

    final address = ProtocolAddress(numeroDestino, 1);
    final sessionCipher = SessionCipher(
      _sessionStore,
      _identityKeyStore,
      _preKeyStore,
      _signedPreKeyStore,
      address,
    );

    final ciphertextMessage = await sessionCipher.encrypt(utf8.encode(textoPuro));

    await _supabase.from('signal_messages').insert({
      'sender_id': _meuUserId,
      'recipient_id': numeroDestino,
      'payload': base64Encode(ciphertextMessage.serialize()),
      'payload_type': ciphertextMessage.getType(),
    });
  }

  Future<void> _processarMensagemEntrante(Map<String, dynamic> row) async {
    try {
      final String remetente = row['sender_id'] as String;
      final payload = base64Decode(row['payload'] as String);

      final address = ProtocolAddress(remetente, 1);
      final sessionCipher = SessionCipher(
        _sessionStore,
        _identityKeyStore,
        _preKeyStore,
        _signedPreKeyStore,
        address,
      );

      final textoPlanoBytes = await sessionCipher.decrypt(
        CiphertextMessage.fromSerialized(payload),
      );

      _sessoesEstabelecidas.add(remetente);

      _streamController.add(
        MensagemDescriptografada(
          remetente: remetente,
          texto: utf8.decode(textoPlanoBytes),
          timestamp: DateTime.now(),
        ),
      );

      // Apaga do Supabase depois de descriptografar — não fica ciphertext acumulado
      await _supabase.from('signal_messages').delete().eq('id', row['id']);
    } catch (e) {
      print('Erro ao processar mensagem entrante: $e');
    }
  }
}

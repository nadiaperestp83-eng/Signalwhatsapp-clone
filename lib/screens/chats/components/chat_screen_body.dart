import 'dart:async';
import 'package:flutter/material.dart';
import 'package:whatsapp_clone/core/signal_core.dart';
import 'package:whatsapp_clone/screens/chats/components/widgets/chat_messages.dart';
import 'package:whatsapp_clone/screens/chats/components/widgets/chat_screen/send_msg_record_audio.dart';

class ChatScreenBody extends StatefulWidget {
  final String targetUserId;

  const ChatScreenBody({
    super.key,
    required this.targetUserId,
  });

  @override
  State<ChatScreenBody> createState() => _ChatScreenBodyState();
}

class _ChatScreenBodyState extends State<ChatScreenBody> {
  final List<Map<String, dynamic>> _mensagens = [];
  StreamSubscription<MensagemDescriptografada>? _sub;

  // "Anotações" (chat consigo mesmo) não usa a sessão criptográfica
  // ponto-a-ponto — ver SignalCore.salvarAnotacao/carregarAnotacoes.
  bool get _ehAnotacoes =>
      widget.targetUserId.isNotEmpty && widget.targetUserId == SignalCore().meuUserId;

  @override
  void initState() {
    super.initState();
    if (_ehAnotacoes) {
      _carregarAnotacoesSalvas();
    } else {
      _sub = SignalCore().mensagensRecebidas.listen((msg) {
        if (msg.remetente != widget.targetUserId) return;
        setState(() {
          _mensagens.add({
            'isSender': false,
            'message': msg.texto,
            'timeStamp': _formatarHora(msg.timestamp),
          });
        });
      });
    }
  }

  Future<void> _carregarAnotacoesSalvas() async {
    final anotacoes = await SignalCore().carregarAnotacoes();
    if (!mounted) return;
    setState(() {
      _mensagens.addAll(anotacoes.map((a) => {
            'isSender': true,
            'message': a['texto'],
            'timeStamp': _formatarHora(DateTime.parse(a['timestamp'] as String)),
          }));
    });
  }

  String _formatarHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _adicionarMensagemNaTela(String texto) {
    setState(() {
      _mensagens.add({
        'isSender': true,
        'message': texto,
        'timeStamp': _formatarHora(DateTime.now()),
      });
    });
  }

  Future<void> _enviar(String texto) async {
    if (_ehAnotacoes) {
      await SignalCore().salvarAnotacao(texto);
    } else {
      await SignalCore().enviarMensagemSegura(widget.targetUserId, texto);
    }
    _adicionarMensagemNaTela(texto);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage('assets/img/whatsapp-doodle.png'),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ChatScreenMessagesWidget(mensagens: _mensagens),
          SendMessageAndRecordAudioWidget(onEnviar: _enviar),
        ],
      ),
    );
  }
}

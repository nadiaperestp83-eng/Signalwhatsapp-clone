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
  // Estado da conversa mora aqui agora (era todo dentro de
  // ChatScreenMessagesWidget antes, e a mensagem que VOCÊ manda nunca
  // chegava até essa lista — só o que chegava pelo SignalCore).
  final List<Map<String, dynamic>> _mensagens = [];
  late final StreamSubscription<MensagemDescriptografada> _sub;

  @override
  void initState() {
    super.initState();
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

  String _formatarHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _adicionarMensagemEnviada(String texto) {
    setState(() {
      _mensagens.add({
        'isSender': true,
        'message': texto,
        'timeStamp': _formatarHora(DateTime.now()),
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
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
          SendMessageAndRecordAudioWidget(
            targetUserId: widget.targetUserId,
            onMensagemEnviada: _adicionarMensagemEnviada,
          ),
        ],
      ),
    );
  }
}

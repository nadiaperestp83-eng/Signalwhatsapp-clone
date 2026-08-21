import 'dart:async';
import 'package:flutter/material.dart';
import 'package:whatsapp_clone/models/messages.dart';
import 'package:whatsapp_clone/core/signal_core.dart';
import 'package:whatsapp_clone/screens/chats/components/widgets/messages/receiver_message_bubble.dart';
import 'package:whatsapp_clone/screens/chats/components/widgets/messages/sender_message_bubble.dart';

class ChatScreenMessagesWidget extends StatefulWidget {
  final String targetUserId;

  const ChatScreenMessagesWidget({
    super.key,
    required this.targetUserId,
  });

  @override
  State<ChatScreenMessagesWidget> createState() =>
      _ChatScreenMessagesWidgetState();
}

class _ChatScreenMessagesWidgetState extends State<ChatScreenMessagesWidget> {
  late final List<Map<String, dynamic>> _mensagens;
  late final StreamSubscription<MensagemDescriptografada> _sub;

  @override
  void initState() {
    super.initState();
    // Mantém o mock inicial (opcional — pode trocar por [] se preferir começar vazio)
    _mensagens = List<Map<String, dynamic>>.from(inboxMessages);

    _sub = SignalCore().mensagensRecebidas.listen((msg) {
      if (msg.remetente != widget.targetUserId) return;
      setState(() {
        _mensagens.add({
          'isSender': false,
          'message': msg.texto,
          'timeStamp':
              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
        });
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
    return Expanded(
      child: ListView.builder(
        itemCount: _mensagens.length,
        itemBuilder: (context, index) {
          if (_mensagens[index]['isSender'] == false) {
            return ReceiverMessageBubble(
              message: _mensagens[index]['message'],
              timeStamp: _mensagens[index]['timeStamp'],
            );
          }
          return SenderMessageBubble(
            message: _mensagens[index]['message'],
            timeStamp: _mensagens[index]['timeStamp'],
          );
        },
      ),
    );
  }
}

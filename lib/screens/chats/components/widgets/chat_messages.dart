import 'package:flutter/material.dart';
import 'package:whatsapp_clone/screens/chats/components/widgets/messages/receiver_message_bubble.dart';
import 'package:whatsapp_clone/screens/chats/components/widgets/messages/sender_message_bubble.dart';

// Antes era StatefulWidget dono da lista de mensagens, e começava com
// List.from(inboxMessages) — uma conversa fake fixa ("Hey handsome 🥰🥰")
// que aparecia em QUALQUER chat, não importa com quem. Agora é
// StatelessWidget: só exibe a lista que o ChatScreenBody controla.
//
// Nota: ainda não persiste histórico entre sessões — reabrir a conversa
// depois de fechar o app não traz mensagens antigas de volta, porque não
// existe camada de persistência de mensagens por contato ainda (só o
// resumo/última mensagem usado na lista de conversas). É feature separada,
// avisa se quiser que eu implemente.
class ChatScreenMessagesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> mensagens;

  const ChatScreenMessagesWidget({
    super.key,
    required this.mensagens,
  });

  @override
  Widget build(BuildContext context) {
    if (mensagens.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Nenhuma mensagem ainda. Diga oi!',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: mensagens.length,
        itemBuilder: (context, index) {
          final msg = mensagens[index];
          if (msg['isSender'] == false) {
            return ReceiverMessageBubble(
              message: msg['message'],
              timeStamp: msg['timeStamp'],
            );
          }
          return SenderMessageBubble(
            message: msg['message'],
            timeStamp: msg['timeStamp'],
          );
        },
      ),
    );
  }
}

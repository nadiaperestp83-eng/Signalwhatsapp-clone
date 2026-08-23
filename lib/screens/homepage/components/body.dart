import 'package:flutter/material.dart';
import 'package:whatsapp_clone/core/signal_core.dart';
import 'package:whatsapp_clone/screens/chats/chat_screen.dart';
import 'package:whatsapp_clone/screens/homepage/components/inbox_messages.dart';

class HomepageBody extends StatelessWidget {
  const HomepageBody({super.key});

  String _formatarHorario(DateTime timestamp) {
    final agora = DateTime.now();
    final mesmoDia = agora.year == timestamp.year &&
        agora.month == timestamp.month &&
        agora.day == timestamp.day;

    if (mesmoDia) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConversaResumo>>(
      stream: SignalCore().conversas,
      builder: (context, snapshot) {
        final conversas = snapshot.data ?? [];

        if (conversas.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Nenhuma conversa ainda. Envie uma mensagem pra alguém registrado pra começar.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: conversas.length,
          itemBuilder: (context, int index) {
            final conversa = conversas[index];
            final prefixo = conversa.ultimaFoiEnviadaPorMim ? 'Você: ' : '';

            return InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                ChatScreen.routeName,
                arguments: conversa.contatoId,
              ),
              child: MessagesWidget(
                username: conversa.contatoId,
                message: '$prefixo${conversa.ultimaMensagem}',
                timeStamp: _formatarHorario(conversa.timestamp),
                profilePicture: 'assets/img/default.png',
                messageTick: null,
              ),
            );
          },
        );
      },
    );
  }
}

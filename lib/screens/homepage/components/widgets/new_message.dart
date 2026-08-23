import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/screens/chats/chat_screen.dart';

class NewMessageWidget extends StatelessWidget {
  const NewMessageWidget({
    super.key,
  });

  void _abrirDialogoNovaConversa(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kAppBarColor,
          title: const Text('Nova conversa', style: TextStyle(color: kTextColor)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: kTextColor),
            decoration: const InputDecoration(
              hintText: '+5511999999999',
              hintStyle: TextStyle(color: kTextDarkColor),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final numero = controller.text.trim();
                if (numero.isEmpty) return;
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  ChatScreen.routeName,
                  arguments: numero,
                );
              },
              child: const Text('Iniciar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: kPrimaryColor,
      onPressed: () => _abrirDialogoNovaConversa(context),
      child: const Icon(Icons.message_rounded),
    );
  }
}

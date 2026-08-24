import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/contacts_service.dart';
import 'package:whatsapp_clone/screens/chats/chat_screen.dart';

class SelectContactScreen extends StatefulWidget {
  static String routeName = '/select-contact';
  const SelectContactScreen({super.key});

  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  late Future<List<ContatoSignal>> _futureContatos;

  @override
  void initState() {
    super.initState();
    _futureContatos = SignalContactsService.buscarContatosRegistrados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kbackgroundColor,
      appBar: AppBar(
        backgroundColor: kbackgroundColor,
        title: const Text('Selecionar contato'),
      ),
      body: FutureBuilder<List<ContatoSignal>>(
        future: _futureContatos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Não foi possível carregar os contatos: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kTextColor),
                ),
              ),
            );
          }

          final contatos = snapshot.data ?? [];

          if (contatos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Nenhum contato da sua agenda está registrado no Signal ainda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextColor),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: contatos.length,
            itemBuilder: (context, index) {
              final contato = contatos[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage:
                      contato.foto != null ? MemoryImage(contato.foto as Uint8List) : null,
                  child: contato.foto == null
                      ? Text(contato.nome.isNotEmpty ? contato.nome[0].toUpperCase() : '?')
                      : null,
                ),
                title: Text(contato.nome, style: const TextStyle(color: kTextColor)),
                subtitle: Text(
                  contato.telefoneRegistrado,
                  style: const TextStyle(color: kTextDarkColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    ChatScreen.routeName,
                    arguments: contato.telefoneRegistrado,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

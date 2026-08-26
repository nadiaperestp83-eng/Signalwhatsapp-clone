import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/contacts_service.dart';
import 'package:whatsapp_clone/core/signal_core.dart';
import 'package:whatsapp_clone/screens/chats/chat_screen.dart';

class SelectContactScreen extends StatefulWidget {
  static String routeName = '/select-contact';
  const SelectContactScreen({super.key});

  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  late Future<List<ContatoSignal>> _futureContatos;
  final TextEditingController _buscaController = TextEditingController();
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregarContatos();
    _buscaController.addListener(() {
      setState(() => _busca = _buscaController.text.trim().toLowerCase());
    });
  }

  void _carregarContatos() {
    setState(() {
      _futureContatos = SignalContactsService.buscarContatosRegistrados();
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _abrirChat(String numero) {
    Navigator.of(context).pushReplacementNamed(
      ChatScreen.routeName,
      arguments: numero,
    );
  }

  void _avisarIndisponivel(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _buscarPorNumero() async {
    final numeroController = TextEditingController();

    final numero = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAppBarColor,
        title: const Text('Encontrar pelo número', style: TextStyle(color: kTextColor)),
        content: TextField(
          controller: numeroController,
          autofocus: true,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: kTextColor),
          decoration: const InputDecoration(
            hintText: '+55 11 91234-5678',
            hintStyle: TextStyle(color: kTextDarkColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, numeroController.text.trim()),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (numero != null && numero.isNotEmpty && mounted) {
      _abrirChat(numero);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kbackgroundColor,
      appBar: AppBar(
        backgroundColor: kbackgroundColor,
        title: const Text('Nova mensagem'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
            child: Container(
              decoration: BoxDecoration(
                color: kchatBarMessage,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: _buscaController,
                style: const TextStyle(color: kTextColor),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  hintText: 'Nome, nome de usuário ou número',
                  hintStyle: TextStyle(color: kTextDarkColor),
                  prefixIcon: Icon(Icons.search, color: kTextDarkColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ContatoSignal>>(
              future: _futureContatos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErroPermissao(snapshot.error.toString());
                }

                final todos = snapshot.data ?? [];
                final filtrados = _busca.isEmpty
                    ? todos
                    : todos
                        .where((c) =>
                            c.nome.toLowerCase().contains(_busca) ||
                            c.telefoneRegistrado.contains(_busca))
                        .toList();

                return ListView(
                  children: [
                    _buildOpcao(
                      icon: Icons.group,
                      titulo: 'Novo grupo',
                      onTap: () => _avisarIndisponivel(
                        'Grupos ainda não estão disponíveis nesse fork.',
                      ),
                    ),
                    _buildOpcao(
                      icon: Icons.alternate_email,
                      titulo: 'Encontrar pelo nome de usuário',
                      onTap: () => _avisarIndisponivel(
                        'Busca por nome de usuário ainda não implementada.',
                      ),
                    ),
                    _buildOpcao(
                      icon: Icons.tag,
                      titulo: 'Encontrar pelo número de telefone',
                      onTap: _buscarPorNumero,
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'A',
                          style: TextStyle(color: kTextDarkColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: kPrimaryColor,
                        child: Icon(Icons.bookmark, color: Colors.black),
                      ),
                      title: const Text('Anotações', style: TextStyle(color: kTextColor)),
                      onTap: () => _abrirChat(SignalCore().meuUserId),
                    ),
                    const Divider(color: kDividerColor, height: 24.0),
                    ...filtrados.map(
                      (contato) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey,
                          backgroundImage: contato.foto != null
                              ? MemoryImage(contato.foto as Uint8List)
                              : null,
                          child: contato.foto == null
                              ? Text(contato.nome.isNotEmpty ? contato.nome[0].toUpperCase() : '?')
                              : null,
                        ),
                        title: Text(contato.nome, style: const TextStyle(color: kTextColor)),
                        subtitle: Text(
                          contato.telefoneRegistrado,
                          style: const TextStyle(color: kTextDarkColor),
                        ),
                        onTap: () => _abrirChat(contato.telefoneRegistrado),
                      ),
                    ),
                    if (filtrados.isEmpty && todos.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Nenhum contato encontrado pra essa busca.',
                          style: TextStyle(color: kTextDarkColor),
                        ),
                      ),
                    if (todos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Nenhum contato da sua agenda está registrado no Signal ainda.',
                          style: TextStyle(color: kTextDarkColor),
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 4.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mais',
                          style: TextStyle(color: kTextDarkColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    _buildOpcao(
                      icon: Icons.refresh,
                      titulo: 'Atualizar contatos',
                      subtitulo: 'Está faltando alguém? Tente atualizar',
                      onTap: _carregarContatos,
                    ),
                    _buildOpcao(
                      icon: Icons.mail_outline,
                      titulo: 'Convidar para o Signal',
                      onTap: () => _avisarIndisponivel(
                        'Convite automático ainda não configurado — compartilhe '
                        'o link de instalação manualmente por enquanto.',
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcao({
    required IconData icon,
    required String titulo,
    String? subtitulo,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: kchatBarMessage,
        child: Icon(icon, color: kPrimaryColor),
      ),
      title: Text(titulo, style: const TextStyle(color: kTextColor)),
      subtitle: subtitulo != null
          ? Text(subtitulo, style: const TextStyle(color: kTextDarkColor, fontSize: 12.0))
          : null,
      onTap: onTap,
    );
  }

  // Antes: erro de permissão negada virava um texto cru jogado no meio de
  // uma tela preta, sem nenhuma ação possível — exatamente o "tela preta"
  // que você viu. Agora tem botão de tentar de novo e uma explicação.
  Widget _buildErroPermissao(String erro) {
    final permissaoNegada = erro.contains('Permissão de contatos negada');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.contacts_outlined, color: kTextDarkColor, size: 48.0),
            const SizedBox(height: 12.0),
            Text(
              permissaoNegada
                  ? 'O app precisa de acesso aos seus contatos pra saber quem já usa o Signal.'
                  : 'Não foi possível carregar os contatos: $erro',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextColor),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _carregarContatos,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              child: const Text('Tentar novamente'),
            ),
            if (permissaoNegada) ...[
              const SizedBox(height: 8.0),
              const Text(
                'Se não aparecer o pedido de permissão, ative manualmente em '
                'Ajustes do sistema > Apps > (este app) > Permissões > Contatos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextDarkColor, fontSize: 12.0),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

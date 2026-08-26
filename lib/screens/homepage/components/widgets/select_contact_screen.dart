import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/contacts_service.dart';
import 'package:whatsapp_clone/core/signal_core.dart';
import 'package:whatsapp_clone/core/signal_user_lookup_service.dart';
import 'package:whatsapp_clone/screens/chats/chat_screen.dart';

const String _signalBridgeUrl = String.fromEnvironment('SIGNAL_BRIDGE_URL');

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

  int _verificados = 0;
  int _totalParaVerificar = 0;

  @override
  void initState() {
    super.initState();
    _carregarContatos();
    _buscaController.addListener(() {
      setState(() => _busca = _buscaController.text.trim());
    });
  }

  void _carregarContatos() {
    setState(() {
      _verificados = 0;
      _totalParaVerificar = 0;
      _futureContatos = SignalContactsService.buscarContatosRegistrados(
        bridgeBaseUrl: _signalBridgeUrl,
        contaTelefone: SignalCore().meuUserId,
        aoProgredir: (verificados, total) {
          if (!mounted) return;
          setState(() {
            _verificados = verificados;
            _totalParaVerificar = total;
          });
        },
      );
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

    if (numero == null || numero.isEmpty || !mounted) return;
    await _verificarEAbrir(numero);
  }

  Future<void> _buscarPorUsername() async {
    final usernameController = TextEditingController();

    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAppBarColor,
        title: const Text('Encontrar pelo nome de usuário', style: TextStyle(color: kTextColor)),
        content: TextField(
          controller: usernameController,
          autofocus: true,
          style: const TextStyle(color: kTextColor),
          decoration: const InputDecoration(
            hintText: 'usuario.123',
            hintStyle: TextStyle(color: kTextDarkColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, usernameController.text.trim()),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (username == null || username.isEmpty || !mounted) return;
    await _verificarEAbrir(username, ehUsername: true);
  }

  Future<void> _verificarEAbrir(String recipient, {bool ehUsername = false}) async {
    _avisarIndisponivel('Verificando no Signal...');

    try {
      final service = SignalUserLookupService(bridgeBaseUrl: _signalBridgeUrl);
      final resultado = await service.verificarStatus(
        telefoneConta: SignalCore().meuUserId,
        recipient: recipient,
      );

      if (resultado['registrado'] != true) {
        _avisarIndisponivel(
          'Esse ${ehUsername ? "nome de usuário" : "número"} não está registrado no Signal.',
        );
        return;
      }

      if (ehUsername) {
        // Usernames existem justamente pra NÃO expor o número de telefone.
        // Nossa criptografia (signal_bundles no Supabase) é indexada por
        // número, não por username/uuid — sem o número, não dá pra montar
        // sessão. É limitação de arquitetura, não bug — deixando isso
        // explícito em vez de fingir que funciona.
        _avisarIndisponivel(
          'Esse username existe no Signal, mas esse fork ainda só consegue '
          'abrir chat por número de telefone (a criptografia é indexada por '
          'número). Peça o número da pessoa por enquanto.',
        );
        return;
      }

      if (!mounted) return;
      _abrirChat(recipient);
    } catch (e) {
      _avisarIndisponivel('Não foi possível verificar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final buscaTemDigitos = RegExp(r'\d{3,}').hasMatch(_busca);
    final buscaTemLetras = RegExp(r'[a-zA-Z]').hasMatch(_busca);
    final buscando = _busca.isNotEmpty;

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
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  hintText: 'Nome, nome de usuário ou número',
                  hintStyle: const TextStyle(color: kTextDarkColor),
                  prefixIcon: const Icon(Icons.search, color: kTextDarkColor),
                  suffixIcon: buscando
                      ? IconButton(
                          icon: const Icon(Icons.close, color: kTextDarkColor),
                          onPressed: () => _buscaController.clear(),
                        )
                      : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ContatoSignal>>(
              future: _futureContatos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildCarregando();
                }

                if (snapshot.hasError) {
                  return _buildErroPermissao(snapshot.error.toString());
                }

                final todos = snapshot.data ?? [];
                final buscaMinuscula = _busca.toLowerCase();
                final filtrados = _busca.isEmpty
                    ? todos
                    : todos
                        .where((c) =>
                            c.nome.toLowerCase().contains(buscaMinuscula) ||
                            c.telefoneRegistrado.contains(_busca))
                        .toList();

                return ListView(
                  children: [
                    // As opções fixas de topo (Novo grupo, buscar por
                    // username/número em modal) só aparecem com a busca
                    // vazia — igual ao Signal real, que troca esse menu
                    // pelos resultados assim que você começa a digitar.
                    if (!buscando) ...[
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
                        onTap: _buscarPorUsername,
                      ),
                      _buildOpcao(
                        icon: Icons.tag,
                        titulo: 'Encontrar pelo número de telefone',
                        onTap: _buscarPorNumero,
                      ),
                    ],
                    _buildCabecalho('Contatos'),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: kPrimaryColor,
                        child: Icon(Icons.bookmark, color: Colors.black),
                      ),
                      title: const Text('Anotações', style: TextStyle(color: kTextColor)),
                      onTap: () => _abrirChat(SignalCore().meuUserId),
                    ),
                    if (!buscando) const Divider(color: kDividerColor, height: 24.0),
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
                    if (buscando && filtrados.isEmpty && todos.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Nenhum contato da sua agenda bate com essa busca.',
                            style: TextStyle(color: kTextDarkColor, fontSize: 12.0),
                          ),
                        ),
                      ),
                    if (todos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Nenhum contato da sua agenda está registrado no Signal ainda.',
                            style: TextStyle(color: kTextDarkColor, fontSize: 12.0),
                          ),
                        ),
                      ),

                    // Linha de resultado ao vivo, igual ao Signal real: assim
                    // que você digita algo com cara de número/username, some
                    // uma opção pra buscar exatamente aquilo direto no
                    // servidor — não fica dependendo só da agenda local.
                    if (buscando && buscaTemDigitos) ...[
                      _buildCabecalho('Encontrar pelo número de telefone'),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: kchatBarMessage,
                          child: Icon(Icons.search, color: kPrimaryColor),
                        ),
                        title: Text(_busca, style: const TextStyle(color: kTextColor)),
                        subtitle: const Text(
                          'Toque para verificar no Signal',
                          style: TextStyle(color: kTextDarkColor, fontSize: 12.0),
                        ),
                        onTap: () => _verificarEAbrir(_busca),
                      ),
                    ],
                    if (buscando && buscaTemLetras) ...[
                      _buildCabecalho('Encontrar pelo nome de usuário'),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: kchatBarMessage,
                          child: Icon(Icons.alternate_email, color: kPrimaryColor),
                        ),
                        title: Text(_busca, style: const TextStyle(color: kTextColor)),
                        subtitle: const Text(
                          'Toque para verificar no Signal',
                          style: TextStyle(color: kTextDarkColor, fontSize: 12.0),
                        ),
                        onTap: () => _verificarEAbrir(_busca, ehUsername: true),
                      ),
                    ],

                    _buildCabecalho('Mais'),
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

  Widget _buildCabecalho(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          texto,
          style: const TextStyle(color: kTextDarkColor, fontWeight: FontWeight.bold),
        ),
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

  // Verificar a agenda inteira contra o Signal (em lotes, pelo bridge) pode
  // levar alguns segundos com muitos contatos — mostra progresso em vez de
  // um spinner mudo, pra não parecer travado.
  Widget _buildCarregando() {
    final temProgresso = _totalParaVerificar > 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16.0),
          Text(
            temProgresso
                ? 'Verificando contatos no Signal... ($_verificados/$_totalParaVerificar)'
                : 'Carregando contatos...',
            style: const TextStyle(color: kTextDarkColor),
          ),
        ],
      ),
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

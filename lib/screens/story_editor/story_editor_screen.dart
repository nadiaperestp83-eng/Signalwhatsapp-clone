// lib/screens/story_editor/story_editor_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/signal_core.dart';
import 'package:whatsapp_clone/core/signal_story_service.dart';

const String _signalBridgeUrl = String.fromEnvironment('SIGNAL_BRIDGE_URL');

/// Cores de fundo disponíveis pra uma story de texto puro (sem foto).
const List<Color> _kStoryBackgroundColors = [
  Color(0xFF1F2C34),
  kPrimaryColor,
  Color(0xFF6A3DE8),
  Color(0xFFE84393),
  Color(0xFFE8A93D),
  Color(0xFF2D6CE8),
  Color(0xFFE84040),
  Colors.black,
];

/// Cores de texto disponíveis (ciclo ao tocar no botão de cor).
const List<Color> _kTextColors = [
  Colors.white,
  Colors.black,
  kPrimaryColor,
];

enum _DestinoStory { meuStatus, grupo }

class StoryEditorScreen extends StatefulWidget {
  static const routeName = '/story-editor';

  /// Se vier preenchida, a story é composta sobre essa foto (câmera/galeria).
  /// Se for null, é uma story de texto sobre fundo colorido.
  final File? imagemDeFundo;

  const StoryEditorScreen({super.key, this.imagemDeFundo});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final TextEditingController _textoController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _corFundoIndex = 0;
  int _corTextoIndex = 0;
  double _tamanhoFonte = 32.0;

  bool _enviando = false;
  _DestinoStory _destino = _DestinoStory.meuStatus;
  String? _groupId;

  bool get _temFoto => widget.imagemDeFundo != null;

  @override
  void initState() {
    super.initState();
    if (!_temFoto) {
      // Story de texto puro: já abre o teclado focado.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _textoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cicloCorFundo() {
    setState(() => _corFundoIndex = (_corFundoIndex + 1) % _kStoryBackgroundColors.length);
  }

  void _cicloCorTexto() {
    setState(() => _corTextoIndex = (_corTextoIndex + 1) % _kTextColors.length);
  }

  void _cicloTamanhoFonte() {
    setState(() => _tamanhoFonte = _tamanhoFonte >= 44 ? 22 : _tamanhoFonte + 6);
  }

  Future<void> _escolherDestino() async {
    final groupController = TextEditingController(text: _groupId ?? '');

    final resultado = await showModalBottomSheet<_DestinoStory>(
      context: context,
      backgroundColor: kAppBarColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quem pode ver essa story?',
                style: TextStyle(color: kTextColor, fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.public, color: kPrimaryColor),
                title: const Text('Meu status', style: TextStyle(color: kTextColor)),
                subtitle: const Text(
                  'Visível pra todos os seus contatos',
                  style: TextStyle(color: kTextDarkColor),
                ),
                onTap: () => Navigator.pop(context, _DestinoStory.meuStatus),
              ),
              const Divider(color: kDividerColor),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.group, color: kPrimaryColor),
                title: const Text('Grupo específico', style: TextStyle(color: kTextColor)),
                subtitle: TextField(
                  controller: groupController,
                  style: const TextStyle(color: kTextColor, fontSize: 13.0),
                  decoration: const InputDecoration(
                    hintText: 'ID do grupo (base64)',
                    hintStyle: TextStyle(color: kTextDarkColor),
                    isDense: true,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle, color: kPrimaryColor),
                  onPressed: () {
                    if (groupController.text.trim().isEmpty) return;
                    _groupId = groupController.text.trim();
                    Navigator.pop(context, _DestinoStory.grupo);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (resultado != null) setState(() => _destino = resultado);
  }

  Future<Uint8List> _renderizarPng() async {
    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final imagem = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await imagem.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _enviarStory() async {
    if (!_temFoto && _textoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva algo antes de publicar.')),
      );
      return;
    }
    if (_destino == _DestinoStory.grupo && (_groupId == null || _groupId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um grupo válido.')),
      );
      return;
    }

    setState(() => _enviando = true);
    _focusNode.unfocus();
    // Dá um frame pro teclado fechar e o cursor sumir antes de capturar.
    await Future.delayed(const Duration(milliseconds: 80));

    try {
      final png = await _renderizarPng();
      final service = SignalStoryService(bridgeBaseUrl: _signalBridgeUrl);
      final resultado = await service.enviarStory(
        telefone: SignalCore().meuUserId,
        imagemPng: png,
        groupId: _destino == _DestinoStory.grupo ? _groupId : null,
      );

      if (resultado['sucesso'] == true) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        throw StateError(resultado['erro']?.toString() ?? 'Falha ao publicar a story.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao publicar story: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final corFundo = _kStoryBackgroundColors[_corFundoIndex];
    final corTexto = _temFoto ? Colors.white : _kTextColors[_corTextoIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    width: double.infinity,
                    color: _temFoto ? Colors.black : corFundo,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_temFoto) Image.file(widget.imagemDeFundo!, fit: BoxFit.cover),
                        if (_temFoto)
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black54],
                              ),
                            ),
                          ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: TextField(
                              controller: _textoController,
                              focusNode: _focusNode,
                              maxLines: null,
                              textAlign: TextAlign.center,
                              cursorColor: kPrimaryColor,
                              style: TextStyle(
                                color: corTexto,
                                fontSize: _tamanhoFonte,
                                fontWeight: FontWeight.w600,
                                shadows: _temFoto
                                    ? const [Shadow(blurRadius: 6.0, color: Colors.black87)]
                                    : null,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: _temFoto ? 'Adicionar legenda' : 'Escreva algo...',
                                hintStyle: TextStyle(
                                  color: corTexto.withOpacity(0.6),
                                  fontSize: _tamanhoFonte,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: kIconColor, size: 28.0),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          IconButton(
            icon: const Text(
              'Aa',
              style: TextStyle(color: kIconColor, fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            tooltip: 'Tamanho do texto',
            onPressed: _cicloTamanhoFonte,
          ),
          IconButton(
            icon: Container(
              width: 26.0,
              height: 26.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _temFoto ? _kTextColors[_corTextoIndex] : _kStoryBackgroundColors[_corFundoIndex],
                border: Border.all(color: kIconColor, width: 1.5),
              ),
            ),
            tooltip: _temFoto ? 'Cor do texto' : 'Cor de fundo',
            onPressed: _temFoto ? _cicloCorTexto : _cicloCorFundo,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _escolherDestino,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: kchatBarMessage,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _destino == _DestinoStory.meuStatus ? Icons.public : Icons.group,
                      color: kPrimaryColor,
                      size: 18.0,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      _destino == _DestinoStory.meuStatus ? 'Meu status' : 'Grupo selecionado',
                      style: const TextStyle(color: kTextColor, fontSize: 13.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          _enviando
              ? const SizedBox(
                  width: 48.0,
                  height: 48.0,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: kPrimaryColor),
                  ),
                )
              : FloatingActionButton(
                  heroTag: 'enviarStoryBtn',
                  backgroundColor: kPrimaryColor,
                  onPressed: _enviarStory,
                  child: const Icon(Icons.send),
                ),
        ],
      ),
    );
  }
}

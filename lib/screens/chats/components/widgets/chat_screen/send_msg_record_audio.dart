import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';

class SendMessageAndRecordAudioWidget extends StatefulWidget {
  final Future<void> Function(String texto) onEnviar;

  const SendMessageAndRecordAudioWidget({
    super.key,
    required this.onEnviar,
  });

  @override
  State<SendMessageAndRecordAudioWidget> createState() =>
      _SendMessageAndRecordAudioWidgetState();
}

class _SendMessageAndRecordAudioWidgetState
    extends State<SendMessageAndRecordAudioWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _temTexto = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final temTexto = _controller.text.trim().isNotEmpty;
      if (temTexto != _temTexto) {
        setState(() => _temTexto = temTexto);
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    try {
      await widget.onEnviar(texto);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao enviar mensagem segura: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: kchatBarMessage,
            borderRadius: BorderRadius.circular(20.0),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.5),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.sentiment_satisfied_outlined),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * .47,
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviar(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: kTextDarkColor),
                    hintText: 'Message',
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.attach_file),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_outlined),
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _enviando ? null : (_temTexto ? _enviar : () {}),
            icon: _enviando
                ? const SizedBox(
                    width: 18.0,
                    height: 18.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.black),
                  )
                : Icon(
                    _temTexto ? Icons.send : Icons.mic,
                    color: Colors.black,
                  ),
          ),
        ),
      ],
    );
  }
}

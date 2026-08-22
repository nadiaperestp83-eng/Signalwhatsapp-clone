import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/signal_core.dart';
import 'package:whatsapp_clone/screens/signup/signup_screen.dart';

class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  bool _inicializando = false;

  Future<void> _verificarEIniciarCasulo(String codigo) async {
    if (_inicializando) return;
    setState(() => _inicializando = true);

    try {
      // Assume que a tela anterior (Login) passou o telefone como argumento da rota.
      final telefone = ModalRoute.of(context)?.settings.arguments as String?;

      if (telefone == null || telefone.isEmpty) {
        throw StateError(
          'Número de telefone não recebido da tela de login. '
          'Verifique se LoginScreen está passando `arguments: numero` no Navigator.pushNamed.',
        );
      }

      await SignalCore().inicializarCasulo(meuUserId: telefone);

      if (mounted) {
        Navigator.pushNamed(context, SignupScreen.routeName, arguments: telefone);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao iniciar o Casulo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _inicializando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * .5,
      child: _inicializando
          ? const CircularProgressIndicator()
          : TextField(
              decoration: const InputDecoration(
                hintText: '-  -  -  -  -  -',
                hintStyle: TextStyle(fontSize: 30.0, color: kTextColor),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kTextColor),
              textAlign: TextAlign.center,
              onChanged: (value) {
                if (value.isNotEmpty && value.length >= 6) {
                  _verificarEIniciarCasulo(value);
                }
              },
            ),
    );
  }
}

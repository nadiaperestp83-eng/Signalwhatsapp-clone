import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/signal_registration_service.dart';
import 'package:whatsapp_clone/screens/signup/signup_screen.dart';

const String _signalBridgeUrl = String.fromEnvironment('SIGNAL_BRIDGE_URL');

class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  bool _verificando = false;

  Future<void> _verificarCodigo(String codigo) async {
    if (_verificando) return;
    setState(() => _verificando = true);

    try {
      final telefone = ModalRoute.of(context)?.settings.arguments as String?;

      if (telefone == null || telefone.isEmpty) {
        throw StateError('Número de telefone não recebido da tela de login.');
      }

      final service = SignalRegistrationService(bridgeBaseUrl: _signalBridgeUrl);
      final resultado = await service.verificar(telefone: telefone, codigo: codigo);

      if (resultado['sucesso'] != true) {
        throw StateError(resultado['erro']?.toString() ?? 'Código inválido.');
      }

      if (mounted) {
        Navigator.pushNamed(context, SignupScreen.routeName, arguments: telefone);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha na verificação: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * .5,
      child: _verificando
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
                  _verificarCodigo(value);
                }
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/signal_registration_service.dart';
import 'package:whatsapp_clone/screens/captcha/captcha_screen.dart';
import 'package:whatsapp_clone/screens/otp/otp_screen.dart';

const String _signalBridgeUrl = String.fromEnvironment('SIGNAL_BRIDGE_URL');

class NextButton extends StatefulWidget {
  final String telefoneCompleto;

  const NextButton({
    super.key,
    required this.telefoneCompleto,
  });

  @override
  State<NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<NextButton> {
  bool _carregando = false;

  Future<void> _iniciarRegistro() async {
    if (widget.telefoneCompleto.isEmpty || _carregando) return;

    if (_signalBridgeUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SIGNAL_BRIDGE_URL não configurado. Rode com --dart-define-from-file=secrets.json.',
          ),
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    final service = SignalRegistrationService(bridgeBaseUrl: _signalBridgeUrl);

    try {
      var resultado = await service.registrar(telefone: widget.telefoneCompleto);

      if (resultado['precisaCaptcha'] == true) {
        if (!mounted) return;
        final token = await Navigator.pushNamed(context, CaptchaScreen.routeName);

        if (token == null || token is! String) {
          setState(() => _carregando = false);
          return;
        }

        resultado = await service.registrar(
          telefone: widget.telefoneCompleto,
          captchaToken: token,
        );
      }

      if (resultado['sucesso'] != true) {
        throw StateError(resultado['erro']?.toString() ?? 'Falha desconhecida no registro.');
      }

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        OTPScreen.routeName,
        arguments: widget.telefoneCompleto,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: kPrimaryColor,
      ),
      child: TextButton(
        onPressed: _carregando ? null : _iniciarRegistro,
        child: _carregando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Next', style: TextStyle(color: Colors.black)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:whatsapp_clone/common/screens/homescreen.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/signal_core.dart';

class UsernameInputField extends StatefulWidget {
  const UsernameInputField({
    super.key,
    required this.usernameController,
  });

  final TextEditingController usernameController;

  @override
  State<UsernameInputField> createState() => _UsernameInputFieldState();
}

class _UsernameInputFieldState extends State<UsernameInputField> {
  bool _concluindo = false;

  // Antes esse botão só fazia Navigator.popAndPushNamed(HomeScreen), sem ler
  // o telefone que veio da tela de OTP e sem chamar SignalCore().
  // inicializarCasulo(). Resultado: SignalCore().meuUserId ficava '' pra
  // sempre em qualquer cadastro novo, e qualquer ação que dependesse dele
  // (ex: publicar Story) quebrava com "Bad state: phone é obrigatório".
  Future<void> _concluirCadastro(BuildContext context) async {
    if (_concluindo) return;

    final telefone = ModalRoute.of(context)?.settings.arguments as String?;

    if (telefone == null || telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Número de telefone não recebido do cadastro. Volte e tente de novo.',
          ),
        ),
      );
      return;
    }

    setState(() => _concluindo = true);

    try {
      await SignalCore().inicializarCasulo(meuUserId: telefone);
      if (!context.mounted) return;
      Navigator.popAndPushNamed(context, HomeScreen.routeName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao concluir cadastro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _concluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * .87,
          padding: const EdgeInsets.all(20.0),
          child: TextField(
            controller: widget.usernameController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: kTextColor),
            ),
            keyboardType: TextInputType.name,
            style: const TextStyle(color: kTextColor),
            onChanged: (value) {},
          ),
        ),
        _concluindo
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              )
            : IconButton(
                onPressed: () => _concluirCadastro(context),
                color: kIconColor,
                icon: const Icon(Icons.check),
              ),
      ],
    );
  }
}

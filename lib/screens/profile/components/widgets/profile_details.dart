import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/signal_core.dart';
import 'package:whatsapp_clone/core/signal_profile_service.dart';

const String _signalBridgeUrl = String.fromEnvironment('SIGNAL_BRIDGE_URL');

class UserProfileDetails extends StatefulWidget {
  const UserProfileDetails({
    super.key,
  });

  @override
  State<UserProfileDetails> createState() => _UserProfileDetailsState();
}

class _UserProfileDetailsState extends State<UserProfileDetails> {
  String _nome = 'testuser';
  String _sobreMim = 'With great power comes great responsibility';

  Future<void> _editarCampo({
    required String tituloDialogo,
    required String valorAtual,
    required bool ehNome,
  }) async {
    final controller = TextEditingController(text: valorAtual);

    final novoValor = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kAppBarColor,
          title: Text(tituloDialogo, style: const TextStyle(color: kTextColor)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: kTextColor),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (novoValor == null || novoValor.isEmpty) return;

    try {
      final service = SignalProfileService(bridgeBaseUrl: _signalBridgeUrl);
      final resultado = await service.atualizarPerfil(
        telefone: SignalCore().meuUserId,
        nome: ehNome ? novoValor : _nome,
        sobreMim: ehNome ? _sobreMim : novoValor,
      );

      if (resultado['sucesso'] == true) {
        setState(() {
          if (ehNome) {
            _nome = novoValor;
          } else {
            _sobreMim = novoValor;
          }
        });
      } else {
        throw StateError(resultado['erro']?.toString() ?? 'Falha ao atualizar perfil.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person_outlined, color: kTextDarkColor),
          onTap: () => _editarCampo(
            tituloDialogo: 'Editar nome',
            valorAtual: _nome,
            ehNome: true,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Name', style: TextStyle(color: kTextDarkColor, fontSize: 14.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_nome, style: const TextStyle(color: kTextColor)),
                  const Icon(Icons.edit_outlined, color: kPrimaryColor),
                ],
              )
            ],
          ),
          subtitle: const Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 12.0, bottom: 10.0),
                child: Text(
                  'Esse nome não é seu usuário ou PIN. Fica visível pros seus contatos no Signal.',
                  style: TextStyle(
                    color: kTextDarkColor,
                    fontSize: 12.0,
                  ),
                ),
              ),
              Divider(color: kDividerColor),
            ],
          ),
        ),

        ListTile(
          leading: const Icon(Icons.info_outline, color: kTextDarkColor),
          onTap: () => _editarCampo(
            tituloDialogo: 'Editar sobre mim',
            valorAtual: _sobreMim,
            ehNome: false,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About',
                style: TextStyle(
                  color: kTextDarkColor,
                  fontSize: 14.0,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .7,
                    child: Text(
                      _sobreMim,
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 15.0,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, color: kPrimaryColor),
                ],
              )
            ],
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Divider(color: kDividerColor),
          ),
        ),

        ListTile(
          leading: const Icon(Icons.phone_outlined, color: kTextDarkColor),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phone', style: TextStyle(color: kTextDarkColor, fontSize: 14.0)),
              Text(SignalCore().meuUserId, style: const TextStyle(color: kTextColor)),
            ],
          ),
        ),
      ],
    );
  }
}

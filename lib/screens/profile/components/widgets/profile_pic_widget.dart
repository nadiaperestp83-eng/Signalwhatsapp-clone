import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/signal_core.dart';
import 'package:whatsapp_clone/core/signal_profile_service.dart';

const String _signalBridgeUrl = String.fromEnvironment('SIGNAL_BRIDGE_URL');

class UserProfilePictureWidget extends StatefulWidget {
  const UserProfilePictureWidget({
    super.key,
  });

  @override
  State<UserProfilePictureWidget> createState() => _UserProfilePictureWidgetState();
}

class _UserProfilePictureWidgetState extends State<UserProfilePictureWidget> {
  File? _avatarLocal;
  bool _enviando = false;

  Future<void> _trocarFoto() async {
    final picker = ImagePicker();
    final arquivo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (arquivo == null) return;

    setState(() => _enviando = true);

    try {
      final service = SignalProfileService(bridgeBaseUrl: _signalBridgeUrl);
      final resultado = await service.atualizarPerfil(
        telefone: SignalCore().meuUserId,
        novoAvatar: File(arquivo.path),
      );

      if (resultado['sucesso'] == true) {
        setState(() => _avatarLocal = File(arquivo.path));
      } else {
        throw StateError(resultado['erro']?.toString() ?? 'Falha ao atualizar avatar.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao trocar foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _avatarLocal != null
                ? FileImage(_avatarLocal as File)
                : const AssetImage('assets/img/default.png') as ImageProvider,
            radius: MediaQuery.of(context).size.height * .10,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _enviando ? null : _trocarFoto,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

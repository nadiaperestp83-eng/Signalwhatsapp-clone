import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whatsapp_clone/constants/colors.dart';

// Antes: onPressed: () {} — o botão da câmera não fazia nada, nunca abria
// nem câmera nem galeria. Agora abre o mesmo seletor usado no FAB de Story.
class UserProfilePicture extends StatelessWidget {
  const UserProfilePicture({
    super.key,
    required this.avatarSelecionado,
    required this.onAvatarSelecionado,
  });

  final File? avatarSelecionado;
  final ValueChanged<File?> onAvatarSelecionado;

  Future<void> _escolherFoto(BuildContext context) async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8.0),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: kPrimaryColor),
                title: const Text('Câmera', style: TextStyle(color: kTextColor)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: kPrimaryColor),
                title: const Text('Galeria', style: TextStyle(color: kTextColor)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        );
      },
    );

    if (origem == null) return;

    final picker = ImagePicker();
    final arquivo = await picker.pickImage(source: origem, imageQuality: 85);
    if (arquivo == null) return;

    onAvatarSelecionado(File(arquivo.path));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.withOpacity(0.3),
          backgroundImage: avatarSelecionado != null
              ? FileImage(avatarSelecionado!) as ImageProvider
              : const AssetImage('assets/img/default.png'),
          radius: MediaQuery.of(context).size.width * .17,
        ),
        Positioned(
          bottom: 2,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
            ),
            height: 45.0,
            width: 45.0,
            child: IconButton(
              onPressed: () => _escolherFoto(context),
              icon: const Icon(
                Icons.add_a_photo,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/screens/story_editor/story_editor_screen.dart';

class AddStatusNoteorAddMedia extends StatelessWidget {
  const AddStatusNoteorAddMedia({
    super.key,
  });

  Future<void> _abrirStoryDeTexto(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StoryEditorScreen()),
    );
  }

  Future<void> _escolherOrigemDaFoto(BuildContext context) async {
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

    if (origem == null || !context.mounted) return;

    final picker = ImagePicker();
    final arquivo = await picker.pickImage(source: origem, imageQuality: 90);
    if (arquivo == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryEditorScreen(imagemDeFundo: File(arquivo.path)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 0,
          bottom: 0,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'editStoryFab',
                backgroundColor: const Color(0xFF222F36),
                onPressed: () => _abrirStoryDeTexto(context),
                child: const Icon(Icons.edit, color: kTextDarkColor),
              ),
              const SizedBox(height: 10.0),
              FloatingActionButton(
                heroTag: 'cameraStoryFab',
                onPressed: () => _escolherOrigemDaFoto(context),
                child: const Icon(Icons.camera_alt),
              )
            ],
          ),
        )
      ],
    );
  }
}

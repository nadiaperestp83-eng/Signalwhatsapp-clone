import 'dart:io';
import 'package:flutter/material.dart';
import 'package:whatsapp_clone/screens/signup/components/profile_picture.dart';
import 'package:whatsapp_clone/screens/signup/components/username_input_field.dart';

class SignupScreenBody extends StatelessWidget {
  const SignupScreenBody({
    super.key,
    required this.usernameController,
    required this.avatarSelecionado,
    required this.onAvatarSelecionado,
  });

  final TextEditingController usernameController;
  final File? avatarSelecionado;
  final ValueChanged<File?> onAvatarSelecionado;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * .08),
            UserProfilePicture(
              avatarSelecionado: avatarSelecionado,
              onAvatarSelecionado: onAvatarSelecionado,
            ),
            UsernameInputField(
              usernameController: usernameController,
              avatarSelecionado: avatarSelecionado,
            ),
          ],
        ),
      ),
    );
  }
}

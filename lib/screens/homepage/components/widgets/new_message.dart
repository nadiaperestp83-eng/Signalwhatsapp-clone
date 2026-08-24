import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/screens/homepage/components/widgets/select_contact_screen.dart';

class NewMessageWidget extends StatelessWidget {
  const NewMessageWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: kPrimaryColor,
      onPressed: () => Navigator.pushNamed(context, SelectContactScreen.routeName),
      child: const Icon(Icons.message_rounded),
    );
  }
}

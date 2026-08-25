import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/screens/settings/settings_screen.dart';

void showHomepageMenuSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kbackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8.0),
            Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.4),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            const SizedBox(height: 8.0),
            ListTile(
              leading: const Icon(Icons.group_outlined, color: kTextColor),
              title: const Text('Novo grupo', style: TextStyle(color: kTextColor)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.done_all_outlined, color: kTextColor),
              title: const Text('Marcar todas como lidas', style: TextStyle(color: kTextColor)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.filter_list_outlined, color: kTextColor),
              title: const Text('Filtrar chats não lidos', style: TextStyle(color: kTextColor)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined, color: kTextColor),
              title: const Text('Perfil de notificações', style: TextStyle(color: kTextColor)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: kTextColor),
              title: const Text('Chats arquivados', style: TextStyle(color: kTextColor)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: kTextColor),
              title: const Text('Configurações', style: TextStyle(color: kTextColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, SettingsScreen.routeName);
              },
            ),
            const SizedBox(height: 12.0),
          ],
        ),
      );
    },
  );
}

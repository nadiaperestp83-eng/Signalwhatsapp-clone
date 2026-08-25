import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/screens/profile/profile_screen.dart';
import 'package:whatsapp_clone/screens/settings/components/widgets/options_widget.dart';
import 'package:whatsapp_clone/screens/settings/components/widgets/user_profile.dart';


class SettingsScreenBody extends StatelessWidget {
  const SettingsScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Column(
          children: [
            const UserProfileInfo(),
            const Divider(color: kDividerColor),

            OptionsWidget(
              icon: Icons.person_outline,
              optionsTitle: 'Conta',
              onTap: () {},
            ),
            OptionsWidget(
              icon: Icons.devices_outlined,
              optionsTitle: 'Dispositivos vinculados',
              onTap: () {},
            ),
            OptionsWidget(
              icon: Icons.favorite_border,
              optionsTitle: 'Doar para o Signal',
              onTap: () {},
            ),

            const Divider(color: kDividerColor),

            OptionsWidget(
              icon: Icons.contrast_outlined,
              optionsTitle: 'Aparência',
              onTap: () {},
            ),
            OptionsWidget(
              icon: Icons.chat_bubble_outline,
              optionsTitle: 'Chats',
              onTap: () {},
            ),
            OptionsWidget(
              icon: Icons.auto_stories_outlined,
              optionsTitle: 'Stories',
              onTap: () {},
            ),
            OptionsWidget(
              icon: Icons.notifications_outlined,
              optionsTitle: 'Notificações',
              onTap: () {},
            ),
            OptionsWidget(
              icon: Icons.lock_outline,
              optionsTitle: 'Privacidade',
              onTap: () {},
            ),
            OptionsWidget(
              icon: Icons.restore_outlined,
              optionsTitle: 'Backups',
              onTap: () {},
            ),
            OptionsWidget(
              icon: Icons.pie_chart_outline,
              optionsTitle: 'Dados e armazenamento',
              onTap: () {},
            ),
            OptionsWidget(
              icon: Icons.credit_card_outlined,
              optionsTitle: 'Pagamentos',
              onTap: () {},
            ),

            const Divider(color: kDividerColor),

            OptionsWidget(
              icon: Icons.help_outline,
              optionsTitle: 'Ajuda',
              onTap: () {},
            ),
            OptionsWidget(
              icon: Icons.mail_outline,
              optionsTitle: 'Convide seus amigos',
              onTap: () {},
            ),

            const Divider(color: kDividerColor),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: kIconColor, size: 12.0),
                  SizedBox(width: 7.0),
                  Text.rich(
                    TextSpan(
                      text: 'Your calls and messages are ',
                      style: TextStyle(color: kTextDarkColor, fontSize: 11.0),
                      children: [
                        TextSpan(
                          text: 'end-to-end encrypted',
                          style: TextStyle(color: kPrimaryColor, fontSize: 11.0),
                        ),
                      ]
                    )
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

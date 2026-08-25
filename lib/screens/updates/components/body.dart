// lib/screens/updates/components/body.dart
//
// Nota: a seção "Channels" (e "Suggested Channels") foi removida daqui porque
// esse conceito não existe no Signal/Molly — era herança do clone de
// WhatsApp. Os widgets em lib/screens/updates/components/widgets/channels/
// e lib/models/channels.dart foram deixados no projeto (não apagados),
// simplesmente não são mais referenciados por nenhuma tela.
import 'package:flutter/material.dart';
import 'package:whatsapp_clone/screens/updates/components/widgets/status/status_header.dart';
import 'package:whatsapp_clone/screens/updates/components/widgets/status/statuses.dart';

class UpdatesScreenBody extends StatelessWidget {
  const UpdatesScreenBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusHeader(),
          const SizedBox(height: 15.0),
          const StatusWidget(),
          const SizedBox(height: 135.0),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/signal_core.dart';

// Antes essa appbar era 100% mockada: sempre "Sarah J" com uma foto de
// assets/img/dps/8.jpg, não importava com quem você tava falando. Agora usa
// o targetUserId de verdade (o telefone da outra pessoa).
AppBar chatScreenAppBar(String targetUserId) {
  final ehVoceMesmo = targetUserId.isNotEmpty && targetUserId == SignalCore().meuUserId;
  final titulo = targetUserId.isEmpty
      ? 'Conversa'
      : (ehVoceMesmo ? 'Anotações' : targetUserId);

  return AppBar(
    centerTitle: false,
    leadingWidth: 35.0,
    title: Row(
      children: [
        CircleAvatar(
          backgroundColor: kPrimaryColor,
          child: Icon(
            ehVoceMesmo ? Icons.bookmark : Icons.person,
            color: Colors.black,
            size: 20.0,
          ),
        ),
        const SizedBox(width: 10.0),
        Flexible(
          child: Text(
            titulo,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
    actions: [
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.video_camera_front_outlined),
      ),
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.phone_outlined),
      ),
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.more_vert),
      ),
    ],
  );
}

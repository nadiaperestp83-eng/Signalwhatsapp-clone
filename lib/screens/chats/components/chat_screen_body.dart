import 'package:flutter/material.dart';
import 'package:whatsapp_clone/screens/chats/components/widgets/chat_messages.dart';
import 'package:whatsapp_clone/screens/chats/components/widgets/chat_screen/send_msg_record_audio.dart';

class ChatScreenBody extends StatelessWidget {
  final String targetUserId;

  const ChatScreenBody({
    super.key,
    required this.targetUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage('assets/img/whatsapp-doodle.png'),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ChatScreenMessagesWidget(targetUserId: targetUserId),
          SendMessageAndRecordAudioWidget(targetUserId: targetUserId),
        ],
      ),
    );
  }
}

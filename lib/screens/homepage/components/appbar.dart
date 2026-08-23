import 'package:flutter/material.dart';
import 'package:whatsapp_clone/screens/homepage/components/widgets/homepage_menu_sheet.dart';


AppBar homepageHeader(context) {
  return AppBar(
    automaticallyImplyLeading: false,
    title: const Text(
      'WhatsApp',
      style: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    ),
    actions: [
      IconButton(
        onPressed: () {}, 
        icon: const Icon(Icons.camera_alt_outlined),
      ),
      IconButton(
        onPressed: () {}, 
        icon: const Icon(Icons.search_outlined),
      ),
      IconButton(
        onPressed: () => showHomepageMenuSheet(context), 
        icon: const Icon(Icons.more_vert),
      ),
    ],
  );
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:xmpp_plugin/models/message_model.dart';

class XmppChat extends StatefulWidget {
  final String selfJid;
  final String peerJid;
  final Stream<MessageChat> incomingMessages;
  final Future<void> Function(String to, String body) sendMessage;
  final String title;

  const XmppChat({
    super.key,
    required this.selfJid,
    required this.peerJid,
    required this.incomingMessages,
    required this.sendMessage,
    this.title = 'Chat',
  });

  @override
  State<XmppChat> createState() => _XmppChatState();
}

class _XmppChatState extends State<XmppChat> {
  late final InMemoryChatController _chatController;
  late final StreamSubscription<MessageChat> _subscription;
@override
void initState() {
  super.initState();

  _chatController = InMemoryChatController();

  _subscription = widget.incomingMessages.listen((msg) {
    if (!mounted) return;
    if (msg.body == null || msg.body!.isEmpty) return;
    if (msg.from != widget.peerJid && msg.from != widget.selfJid) return;

    final Message chatMessage = TextMessage(
      id: msg.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: msg.from!,
      text: msg.body!,
      createdAt: DateTime.now().toUtc(),
    );

    _chatController.insertMessage(chatMessage);

  });
}


  @override
  void dispose() {
    _subscription.cancel();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Chat(
        chatController: _chatController,
        currentUserId: widget.selfJid,
        resolveUser: (name) async { print(name);},
        onMessageSend: (text) async {
          if (text.isEmpty) return;
          await widget.sendMessage(widget.peerJid, text);
        },
      ),
    );
  }
}

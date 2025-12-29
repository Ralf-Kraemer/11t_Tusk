import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wecq/parts/xmppchat.dart';
import 'package:wecq/model/contact.dart';
import 'package:xmpp_plugin/models/message_model.dart';
import 'package:wecq/state/objects/XMPPManager.dart';

class ContactListView extends StatefulWidget {
  final List<Contact> manualContacts;
  final Stream<MessageChat> incomingMessages;
  final String selfJid;
  final XmppManager xmppManager;

  const ContactListView({
    super.key,
    required this.manualContacts,
    required this.incomingMessages,
    required this.selfJid,
    required this.xmppManager,
  });

  @override
  State<ContactListView> createState() => _ContactListViewState();
}

class _ContactListViewState extends State<ContactListView> {
  final Map<String, Contact> _contactsMap = {};
  String _searchQuery = '';
  StreamSubscription<MessageChat>? _subscription;

  @override
  void initState() {
    super.initState();

    for (var contact in widget.manualContacts) {
      _contactsMap[contact.jid] = contact;
    }

    _subscription = widget.incomingMessages.listen((msg) {
      final from = msg.from ?? '';
      final body = msg.body ?? '';

      if (from.isEmpty || body.isEmpty || from == widget.selfJid) return;

      if (!mounted) return;

      setState(() {
        if (_contactsMap.containsKey(from)) {
          final contact = _contactsMap[from]!;
          contact.lastMessage = body;
          contact.lastSeen = DateTime.now();
          contact.unreadCount += 1;
        } else {
          _contactsMap[from] = Contact(
            jid: from,
            name: from.split('@').first,
            lastMessage: body,
            lastSeen: DateTime.now(),
            unreadCount: 1,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _contactsMap.values
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.jid.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) =>
          (b.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: contacts.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final contact = contacts[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Text(
                contact.name.isNotEmpty
                    ? contact.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(contact.name),
            subtitle: contact.lastMessage != null
                ? Text(contact.lastMessage!)
                : const Text('No messages yet'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (contact.unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${contact.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (contact.lastSeen != null)
                  Text(
                    '${contact.lastSeen!.hour.toString().padLeft(2, '0')}:${contact.lastSeen!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => XmppChat(
                    selfJid: widget.selfJid,
                    peerJid: contact.jid,
                    incomingMessages: widget.incomingMessages
                        .where((msg) => msg.from == (contact.jid).split('/').first),
                    sendMessage: (to, body) async {
                      await widget.xmppManager.sendMessage(to, body);
                    },
                    title: contact.name,
                  ),
                ),
              );

              if (!mounted) return;
              setState(() => contact.unreadCount = 0);
            },
          );
        },
      ),
    );
  }

}

class Contact {
  final String jid;
  final String name;
  String? lastMessage;
  DateTime? lastSeen;
  int unreadCount;

  Contact({
    required this.jid,
    required this.name,
    this.lastMessage,
    this.lastSeen,
    this.unreadCount = 0,
  });
}

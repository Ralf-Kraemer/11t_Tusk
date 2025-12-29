class StoredMessage {
  final String id;
  final String from;
  final String body;
  final int timestamp;
  final bool outgoing;

  StoredMessage({
    required this.id,
    required this.from,
    required this.body,
    required this.timestamp,
    required this.outgoing,
  });
}

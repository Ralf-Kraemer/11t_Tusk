import 'package:flutter/material.dart';
import '../state/objects/MatrixManager.dart';
import 'package:matrix/matrix.dart';

class ChatRoomView extends StatefulWidget {
  final String roomId; // Matrix Room ID
  final String title;
  final MatrixManager matrixManager;

  const ChatRoomView({
    super.key,
    required this.roomId,
    required this.matrixManager,
    this.title = 'Chat',
  });

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<_ChatEvent> _events = [];
  final TextEditingController _sendController = TextEditingController();
  Timeline? _timeline;

  @override
  void initState() {
    super.initState();
    _initTimeline();
  }

  Future<void> _initTimeline() async {
    // Find the room
    final room = widget.matrixManager.client.rooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => throw Exception('Room not found'),
    );

    // Get timeline for this room
    _timeline = await room.getTimeline(
      onInsert: (i) {
        final event = _timeline!.events[i];

        // Ignore reactions or non-message events
        if (event.relationshipEventId != null) return;

        // Get displayable event
        final display = event.getDisplayEvent(_timeline!);
        if (display.body.isEmpty) return;

        final chatEvent = _ChatEvent(
          id: event.eventId,
          sender: event.senderFromMemoryOrFallback.id,
          body: display.body,
          timestamp: event.originServerTs,
          pending: !event.status.isSent,
        );

        _events.insert(0, chatEvent);
        _listKey.currentState?.insertItem(0);
      },
      onUpdate: () => setState(() {}),
      onRemove: (i) {
        _events.removeAt(i);
        _listKey.currentState?.removeItem(i, (_, __) => const SizedBox());
      },
    );
  }

  @override
  void dispose() {
    _sendController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _sendController.text.trim();
    if (text.isEmpty) return;
    _sendController.clear();

    final localEvent = _ChatEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: widget.matrixManager.client.userID!,
      body: text,
      timestamp: DateTime.now().toUtc(),
      pending: true,
    );

    _events.insert(0, localEvent);
    _listKey.currentState?.insertItem(0);

    try {
      final room = widget.matrixManager.client.rooms
          .firstWhere((r) => r.id == widget.roomId);
      await widget.matrixManager.sendMessage(room, text);
      localEvent.pending = false;
      setState(() {});
    } catch (_) {
      // Keep pending if failed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: 
      SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedList(
                key: _listKey,
                reverse: true,
                initialItemCount: _events.length,
                itemBuilder: (context, i, animation) {
                  final event = _events[i];
                  final isSelf = event.sender == widget.matrixManager.client.userID;

                  return ScaleTransition(
                    scale: animation,
                    child: Opacity(
                      opacity: event.pending ? 0.5 : 1,
                      child: ListTile(
                        leading: isSelf
                            ? null
                            : CircleAvatar(
                                child: Text(event.sender.isNotEmpty
                                    ? event.sender[0].toUpperCase()
                                    : '?'),
                              ),
                        trailing: isSelf
                            ? const CircleAvatar(child: Icon(Icons.person))
                            : null,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isSelf ? 'You' : event.sender,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              event.timestamp.toIso8601String(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        subtitle: Text(event.body),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sendController,
                      decoration:
                          const InputDecoration(hintText: 'Send message'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEvent {
  final String id;
  final String sender;
  final String body;
  final DateTime timestamp;
  bool pending;

  _ChatEvent({
    required this.id,
    required this.sender,
    required this.body,
    required this.timestamp,
    this.pending = false,
  });
}

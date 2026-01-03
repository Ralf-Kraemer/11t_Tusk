import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import '../state/objects/MatrixManager.dart';
import 'chatroomview.dart';
import '../pages/homepage.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewListViewState();
}

class _ChatListViewListViewState extends State<ChatListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final MatrixManager _matrixManager;

  @override
  void initState() {
    super.initState();
    _matrixManager = MatrixManager();
    if (!_matrixManager.isLoggedIn) {
        _logout();

    }

    _searchController.addListener(() {
      final newQuery = _searchController.text;
      if (newQuery != _searchQuery) setState(() => _searchQuery = newQuery);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _logout() async {
    await _matrixManager.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (BuildContext context) => const HomePage()),
    );
  }

  void _join(Room room) async {
    if (room.membership != Membership.join) await room.join();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomView(title: room.getLocalizedDisplayname(), roomId: room.id, matrixManager: _matrixManager),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _matrixManager.client.rooms;

    // Filter and sort rooms
    final filteredRooms = rooms
        .where((r) =>
            r.getLocalizedDisplayname().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) {
        final aTs = a.lastEvent?.originServerTs ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTs = b.lastEvent?.originServerTs ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTs.compareTo(aTs);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search rooms...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<void>(
        stream: _matrixManager.client.onSync.stream,
        builder: (context, _) {
          return ListView.separated(
            itemCount: filteredRooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final room = filteredRooms[i];
              final lastEvent = room.lastEvent;

              // Use senderFromMemoryOrFallback to avoid deprecated 'sender'
              final senderName = lastEvent?.senderFromMemoryOrFallback;

              return ListTile(
                leading: CircleAvatar(
                  foregroundImage: room.avatar == null
                      ? null
                      : NetworkImage(
                          room.avatar!
                              .getThumbnailUri(_matrixManager.client, width: 56, height: 56)
                              .toString(),
                        ),
                ),
                title: Text(room.getLocalizedDisplayname()),
                subtitle: Text(
                  lastEvent != null
                      ? '${senderName != null ? senderName : 'Someone'}: ${lastEvent.body}'
                      : 'No messages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: room.notificationCount > 0
                    ? Material(
                        borderRadius: BorderRadius.circular(99),
                        color: Colors.red,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            '${room.notificationCount}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : null,
                onTap: () => _join(room),
              );
            },
          );
        },
      ),
    );
  }
}

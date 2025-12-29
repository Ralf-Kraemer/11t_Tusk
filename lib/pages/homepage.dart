import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wecq/state/apistate.dart';
import 'package:wecq/state/objects/XMPPManager.dart';
import '../utils/helper.dart';

import 'package:wecq/parts/MastodonFeed.dart';
import 'package:wecq/parts/scope.dart';
import 'package:wecq/parts/contactlistview.dart';
import 'package:wecq/model/contact.dart';
import 'package:wecq/parts/videoplayerscreen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends ConsumerState<HomePage> {
  int currentPageIndex = 0;
  final Helper helper = Helper.get();

  late final XmppManager xmppManager;
  bool xmppReady = false; // Track if the connection is ready

  // Pre-create navigation buttons
  late final List<NavigationDestination> navigationButtons;

  @override
  void initState() {
    super.initState();

    navigationButtons = [
      const NavigationDestination(icon: Icon(Icons.dynamic_feed), label: 'Feed'),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: true,
          backgroundColor: Colors.blue,
          label: const Text(''),
          child: const Icon(Icons.sensors_rounded),
        ),
        label: 'Scope',
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: true,
          backgroundColor: Colors.blue,
          label: const Text('0'),
          child: const Icon(Icons.messenger),
        ),
        label: 'Chat',
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: false,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.ondemand_video),
        ),
        label: 'Watch',
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: false,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.admin_panel_settings),
        ),
        label: 'You',
      ),
    ];

    // Start XMPP connection safely
    _initXmpp();
  }

  Future<void> _initXmpp() async {
    try {
      // Returns manager immediately, starts connection internally
      xmppManager = helper.connectToXmpp(
        'ralfkraemer',
        'sweepsweep123',
        'chatterboxtown.us',
      );

      // Optional: if XmppManager provides a Future for when connected, await here
      // await xmppManager.waitUntilConnected();

      // Set ready to true immediately, since helper.connectToXmpp already starts it
      setState(() {
        xmppReady = true;
      });
    } catch (e) {
      debugPrint('XMPP connection failed: $e');
      // Keep xmppReady false, Chat page can show an error
    }
  }

  List<Widget> get pages => [
        const MastodonFeed(),
        const Scope(),
        xmppReady
            ? ContactListView(
                manualContacts: [Contact(jid: 'supertestomat@5222.de', name: 'Bob the Builder')],
                incomingMessages: xmppManager.messages,
                selfJid: 'ralfkraemer@5222.de/Flutter',
                xmppManager: xmppManager,
              )
            : const Center(child: CircularProgressIndicator()),
        VideoPlayerScreen(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: const [
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 2'),
                  subtitle: Text('This is a notification'),
                ),
              ),
            ],
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.watch(statusesProvider); // Keep reactive

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (index) => setState(() => currentPageIndex = index),
        indicatorColor: colorScheme.secondaryContainer,
        backgroundColor: colorScheme.surface,
        destinations: navigationButtons,
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: pages,
      ),
    );
  }
}

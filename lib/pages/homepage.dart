import 'package:wecq/parts/videoplayerscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wecq/parts/MastodonFeed.dart';

import '../state/apistate.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends ConsumerState<HomePage> {
  
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.watch(statusesProvider); // keep reactive

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() => currentPageIndex = index);
        },

        // Theme-driven colors
        indicatorColor: colorScheme.secondaryContainer,
        backgroundColor: colorScheme.surface,

        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),

          NavigationDestination(
            icon: Badge(
              isLabelVisible: true,
              backgroundColor: colorScheme.primary,
              label: const Text(''),
              child: const Icon(Icons.sensors_rounded),
            ),
            label: 'Scope',
          ),

          NavigationDestination(
            icon: Badge(
              isLabelVisible: true,
              backgroundColor: colorScheme.primary,
              label: const Text('0'),
              child: const Icon(Icons.messenger),
            ),
            label: 'Chat',
          ),

          NavigationDestination(
            icon: Badge(
              isLabelVisible: false,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.ondemand_video),
            ),
            label: 'Watch',
          ),

          NavigationDestination(
            icon: Badge(
              isLabelVisible: false,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.admin_panel_settings),
            ),
            label: 'You',
          ),
        ],
      ),

      body: <Widget>[
        /// Feed
        const MastodonFeed(),

        /// Scope
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: const <Widget>[
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 1'),
                  subtitle: Text('This is a notification'),
                ),
              ),
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

        /// Chat
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: const <Widget>[
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 1'),
                  subtitle: Text('This is a notification'),
                ),
              ),
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

        /// Watch
        const VideoPlayerScreen(),

        /// You
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: const <Widget>[
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
      ][currentPageIndex],
    );
  }
}

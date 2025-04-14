import 'package:icp/parts/videoplayerscreen.dart';
import 'package:btox/background_service.dart';
import 'package:btox/btox_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toot_ui/models/api/v1/mastodonuser.dart';
import 'package:toot_ui/toot_ui.dart';

import '../state/apistate.dart';
import '../parts/loadingindicator.dart';
import '../parts/statusgrid.dart';

class HomePage extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomePage> createState() => _NavigationWrapperState();

}

class _NavigationWrapperState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  int currentPageIndex = 0;
  int videoViewIndex = 0;

  List<Widget> watchQueue = [];
  var lastVideo = null;
  Widget _videoWrapper(int _index){
            return VideoPlayerScreen(key: Key('LocalVideoScreen_$_index'), videoUrl: '', videoViewIndex: _index,);
  }

  void updateWatchQueue(int index) {
        
      watchQueue.add(_videoWrapper(videoViewIndex++));

      if(index > 0 && watchQueue.length > 4) {
        watchQueue.removeAt(0);
      }

      setState(() {
        watchQueue = watchQueue;
      });
  }

  void _initializeServices() async {
    await initializeService();
  }

  @override
  Widget build(BuildContext context) {
    var statuses = ref.watch(statusesProvider);
    _initializeServices();
    updateWatchQueue(0);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.greenAccent,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed, color: Colors.black),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Badge(label: Text(''), child: Icon(Icons.sensors_rounded, color: Colors.black,), isLabelVisible: true, backgroundColor: Color(0xFF007700)),
            label: 'Scope',
          ),
          NavigationDestination(
            icon: Badge(label: Text('0'), child: Icon(Icons.messenger, color: Colors.black,), isLabelVisible: true, backgroundColor: Color(0xFF007700)),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.ondemand_video, color: Colors.black,), isLabelVisible: false, backgroundColor: Color(0xFF007700)),
            label: 'Watch',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.admin_panel_settings, color: Colors.black,), isLabelVisible: false, backgroundColor: Color(0xFF007700)),
            label: 'You',
          ),
        ],
      ),
      body:
          <Widget>[
            /// Home page
            EmbeddedTootView.fromToot(MastodonStatus(
              id: "1234567890",
              createdAt: "2016-03-16T14:44:31",
              url: "https://mastodon.social/@luckytran@med-mastodon.com/114292590531657885",
              content: "This is a sample toot!",
              account: MastodonUser(
                id: "123",
                displayName: "Ralf Krämer",
                username: "greenFurby",
                verified: false,
                avatarUrl: "https://files.mastodon.social/accounts/avatars/109/246/884/833/502/206/original/7a68fc87a820d5e6.jpg"
              ),
              reblogsCount: 1,
              repliesCount: 2,
              favouritesCount: 3,
              favourited: true,
              reblogged: true,
              bookmarked: true,
              mediaUrls: ["https://files.mastodon.social/media_attachments/files/114/240/815/038/745/877/original/c71fb5be7e961d85.jpg","https://files.mastodon.social/media_attachments/files/114/240/815/213/306/939/original/5012f7212f67e1fa.jpg"]
            )),
                      

            /// Scope page
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
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


            /// Chat page
            BtoxApp(),
                      

            /// Watch page
            PageView(
                scrollDirection: Axis.vertical,
                onPageChanged: updateWatchQueue,
                children: watchQueue
            ),

            
            /// 'You' page
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  
                 
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
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'videoplayercontainer.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final List<Widget> watchQueue = [];
  List<String> videoUris = [];
  int seed = Random().nextInt(99);

  @override
  void initState() {
    super.initState();
    _updateWatchQueue(seed);
    _updateWatchQueue(0);
  }

  Future<List<String>> _fetchPeerTubeVideoUrls(String instanceDomain, int _index, String search) async {
    final searchUrl = Uri.https(instanceDomain, "api/v1/search/videos");
    try {
      final response = await http.get(searchUrl, headers: {
        'count': '15',
        'durationMax': '240',
        'start': _index.toString(),
        'sort': (seed % 5 > 2) ? '-publishedAt' : '-views',
        'search': search,
        'languageOneOf': 'en,de',
      });

      if (response.statusCode != 200) return [];
      final data = json.decode(response.body);
      if (data['data'].isEmpty) return [];

      return List<String>.from(data['data'].map((item) => "$instanceDomain/api/v1/videos/${item['uuid']}"));
    } catch (e) {
      debugPrint("Failed to fetch video URLs: $e");
      return [];
    }
  }

  String _selectPeerTubeInstance() {
    const instances = [
      'tube.shanti.cafe',
      'p.lu',
      'peertube.1312.media',
      'video.antopie.org',
      'tilvids.com',
      'videovortex.tv',
      'video.infosec.exchange',
      'peertube.ch',
      'makertube.net',
      'video.4d2.org',
      'video.causa-arcana.com',
      'watch.libertaria.space',
      'tube.gayfr.online',
      'peertube.expi.studio',
      'video.coales.co',
      'peertube.craftum.pl',
      'peertube.keazilla.net',
      'peertube.fedihub.online',
      'tube.fediverse.games',
      'videos.domainepublic.net',
      'video.rubdos.be',
      'peertube.tweb.tv',
      'peertube.existiert.ch',
      'video.liberta.vip',
      'fediverse.tv',
      'videos.trom.tf',
      'peertube2.cpy.re',
      'peertube3.cpy.re',
      'framatube.org',
      'tube.p2p.legal',
      'peertube.gaialabs.ch',
      'peertube.uno',
      'peertube.slat.org',
      'peertube.opencloud.lu',
      'tube.nx-pod.de',
      'video.hardlimit.com',
      'tube.graz.social',
      'p.eertu.be'
    ];
    return instances[Random().nextInt(instances.length)];
  }

  Future<void> _updateWatchQueue(int _index) async {

    List<String> _videoUris = await _fetchPeerTubeVideoUrls(_selectPeerTubeInstance(), _index, '');

    videoUris.addAll(_videoUris);

    if(watchQueue.length >= 12) {
      watchQueue.removeAt(0);
    } else {
        int _selector = Random().nextInt(videoUris.length);
        watchQueue.add(VideoPlayerContainer(videoUri: videoUris[_selector], videoViewIndex: _index));
        print(videoUris[_selector]);
        videoUris.removeAt(_selector);
    }

    setState(() {
      seed = Random().nextInt(99);
    });
  }

  @override
  Widget build(BuildContext context) {
    return watchQueue.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : PageView.builder(
            scrollDirection: Axis.vertical,
            onPageChanged: _updateWatchQueue,
            itemCount: watchQueue.length,
            itemBuilder: (context, index) => watchQueue[index],
          );
  }
}

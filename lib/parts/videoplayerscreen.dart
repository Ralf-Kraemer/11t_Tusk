import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final int videoViewIndex;

  const VideoPlayerScreen({Key? key, required this.videoUrl, required this.videoViewIndex}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late BetterPlayerController _controller;
  String? targetVideo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        aspectRatio: 9/16,
        autoPlay: false,
        looping: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableFullscreen: true,
          enablePlayPause: true,
        ),
      ),
    );
    loadVideo();
  }
/*
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
*/
  Future<void> loadVideo() async {
    targetVideo = widget.videoUrl.isNotEmpty
        ? widget.videoUrl
        : await curateVideo(widget.videoViewIndex);

    if (targetVideo == null || targetVideo!.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    _controller.setupDataSource(
      BetterPlayerDataSource.network(
        targetVideo!,
        videoFormat: BetterPlayerVideoFormat.hls,
        headers: {"User-Agent": "Flutter"},
      ),
    );

    _controller.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<String?> curateVideo(int seed) async {
    String instance = (seed % 3 != 0) ? 'videovortex.tv' : 'videos.trom.tf';
    return await getPeerTubeStreamUrl(instance, seed);
  }

  Future<String?> getPeerTubeStreamUrl(String instanceDomain, int seed) async {
    final searchUrl = Uri.https(instanceDomain, "api/v1/videos");
    final searchResponse = await http.get(searchUrl, headers: {'count': '1', 'start': '$seed'});

    if (searchResponse.statusCode != 200) return null;

    final searchResults = json.decode(searchResponse.body);
    if (searchResults['data'].isEmpty) return null;

    String videoId = searchResults['data'][0]['uuid'];
    final videoUrl = Uri.https(instanceDomain, "api/v1/videos/$videoId");
    final videoResponse = await http.get(videoUrl);
    if (videoResponse.statusCode != 200) return null;

    final videoData = json.decode(videoResponse.body);
    return videoData['streamingPlaylists']?.isNotEmpty == true
        ? videoData['streamingPlaylists'][0]['playlistUrl']
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : (targetVideo != null && targetVideo!.isNotEmpty)
                ? BetterPlayer(controller: _controller)
                : Text("Failed to load video"),
      
    );
  }
}

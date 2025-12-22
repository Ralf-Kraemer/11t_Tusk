import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoPlayerContainer extends StatefulWidget {
  final String videoUri;
  final int videoViewIndex;

  const VideoPlayerContainer({Key? key, required this.videoUri, required this.videoViewIndex}) : super(key: key);

  @override
  State<VideoPlayerContainer> createState() => _VideoPlayerContainerState();
}

class _VideoPlayerContainerState extends State<VideoPlayerContainer> with AutomaticKeepAliveClientMixin {
  late final BetterPlayerController _controller;
  String? _targetVideo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        aspectRatio: 9 / 16,
        autoPlay: true,
        looping: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableFullscreen: true,
          enablePlayPause: true,
        ),
      ),
    );
    _loadVideo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    try {
      final uri = Uri.parse("https://${widget.videoUri}");
      final response = await http.get(uri);
      if (!mounted || response.statusCode != 200) return;

      final data = json.decode(response.body);
      final playlistUrl = data['streamingPlaylists']?.isNotEmpty == true
          ? data['streamingPlaylists'][0]['playlistUrl']
          : null;

      if (playlistUrl != null) {
        _targetVideo = playlistUrl;
        _controller.setupDataSource(
          BetterPlayerDataSource.network(
            _targetVideo!,
            videoFormat: BetterPlayerVideoFormat.hls,
            headers: const {"User-Agent": "Flutter"},
          ),
        );
        _controller.addEventsListener((event) {
          if (event.betterPlayerEventType == BetterPlayerEventType.initialized && mounted) {
            setState(() => _isLoading = false);
          }
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print('Error loading video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: _isLoading
          ? const CircularProgressIndicator()
          : (_targetVideo != null && _targetVideo!.isNotEmpty)
              ? BetterPlayer(controller: _controller)
              : Text("Failed to load video from ${widget.videoUri}"),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

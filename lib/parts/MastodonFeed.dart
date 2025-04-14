import 'dart:math';
import 'package:flutter/material.dart';
import 'DisplayPic.dart';
import 'DisplayToot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MastodonFeed extends ConsumerStatefulWidget {
  @override
  _MastodonFeedState createState() => _MastodonFeedState();
}

class _MastodonFeedState extends ConsumerState<MastodonFeed> {
  double pixelfedMastodonRatio = 0.5;
  double biasRecency = 0.5;
  double biasHome = 0.5;
  double entropy = 0.5;
  List<Widget> feedItems = [];
  String hoveringLayer = "Default";

  void loadNewPost() {
    if (!mounted) return;  // Check if the widget is still in the widget tree before calling setState()
    
    print("Loading new post");
    setState(() {
      entropy = Random().nextDouble() + 0.5;
      bool addPixelfed = Random().nextDouble() < pixelfedMastodonRatio * entropy;
      feedItems.add(addPixelfed ? DisplayPic() : DisplayToot());
    });
  }

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (this._scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (mounted) {
        loadNewPost();  // Call loadNewPost when user reaches the bottom of the feed
      }
    }
  }

  List<Widget> tootList = [
    ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: feedItems.length,
            itemBuilder: (context, index) => feedItems[index],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedState() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: feedItems.length,
            itemBuilder: (context, index) => feedItems[index],
          ),
        ),
      ],
    );
  }

  Widget _buildHoveringButtons() {
    switch (hoveringLayer) {
      case "Filter":
        print("Hovering layer: $hoveringLayer");
        return Positioned(
          bottom: 16,
          left: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: Icon(Icons.article), onPressed: () {}),
              IconButton(icon: Icon(Icons.people), onPressed: () {}),
              IconButton(icon: Icon(Icons.emoji_emotions), onPressed: () {}),
              IconButton(icon: Icon(Icons.trending_up), onPressed: () {}),
              IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () => setState(() => hoveringLayer = "Default")),
            ],
          ),
        );
      case "CreatePicker":
        print("Hovering layer: $hoveringLayer");
        return Positioned(
          bottom: 16,
          left: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: Icon(Icons.photo), onPressed: () {}),
              IconButton(icon: Icon(Icons.text_fields), onPressed: () {}),
              IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () => setState(() => hoveringLayer = "Default")),
            ],
          ),
        );
      default:
        print("Hovering layer: $hoveringLayer");
        return Positioned(
          bottom: 0.25 * MediaQuery.of(context).size.height,
          right: 0.25 * MediaQuery.of(context).size.width,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  icon: Icon(Icons.create),
                  onPressed: () => setState(() => hoveringLayer = "CreatePicker")),
              IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () => setState(() => hoveringLayer = "Filter")),
            ],
          ),
        );
    }
  }

}

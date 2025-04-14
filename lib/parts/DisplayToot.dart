import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DisplayToot extends StatefulWidget {
  final String? tootId;
  final double? biasRecency;
  final double? biasHome;

  const DisplayToot({
    super.key,
    this.tootId,
    this.biasRecency,
    this.biasHome,
  });

  @override
  _DisplayTootState createState() => _DisplayTootState();
}

class _DisplayTootState extends State<DisplayToot> {
  late Future<Map<String, dynamic>> _tootData;
  final String mastodonInstance = "https://mastodon.social"; // Change to your Mastodon instance

  @override
  void initState() {
    super.initState();
    _tootData = widget.tootId != null
        ? _fetchTootFromMastodon(widget.tootId!)
        : _fetchRecentTootFromMastodon();
  }

  Future<Map<String, dynamic>> _fetchTootFromMastodon(String tootId) async {
    final response = await http.get(Uri.parse("$mastodonInstance/api/v1/statuses/$tootId"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'username': data['account']['username'],
        'profilePic': data['account']['avatar'],
        'content': data['content'],
        'likes': data['favourites_count'],
        'comments': data['replies_count'],
        'boosts': data['reblogs_count']
      };
    } else {
      throw Exception('Failed to load toot');
    }
  }

  Future<Map<String, dynamic>> _fetchRecentTootFromMastodon() async {
    final response = await http.get(Uri.parse("$mastodonInstance/api/v1/timelines/home"));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        final firstToot = data.first;
        return {
          'username': firstToot['account']['username'],
          'profilePic': firstToot['account']['avatar'],
          'content': firstToot['content'],
          'likes': firstToot['favourites_count'],
          'comments': firstToot['replies_count'],
          'boosts': firstToot['reblogs_count']
        };
      } else {
        throw Exception('No recent toots found');
      }
    } else {
      throw Exception('Failed to load recent toots');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _tootData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading toot'));
        }

        final data = snapshot.data!;
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(data['profilePic']),
                ),
                title: Text(data['username'], style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(data['content']),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
                    IconButton(icon: Icon(Icons.comment), onPressed: () {}),
                    IconButton(icon: Icon(Icons.repeat), onPressed: () {}),
                    IconButton(icon: Icon(Icons.bookmark_border), onPressed: () {}),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('${data['boosts']} boosts • ${data['likes']} likes • ${data['comments']} replies',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      },
    );
  }
}

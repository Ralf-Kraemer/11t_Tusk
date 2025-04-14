import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DisplayPic extends StatefulWidget {
  final String? mediaId;
  final double? biasRecency;
  final double? biasHome;

  const DisplayPic({
    super.key,
    this.mediaId,
    this.biasRecency,
    this.biasHome,
  });

  @override
  _DisplayPicState createState() => _DisplayPicState();
}

class _DisplayPicState extends State<DisplayPic> {
  late Future<Map<String, dynamic>> _postData;
  final String pixelfedInstance = "https://pixelfed.social"; // Change to your Pixelfed instance

  @override
  void initState() {
    super.initState();
    _postData = widget.mediaId != null
        ? _fetchPostFromPixelfed(widget.mediaId!)
        : _fetchRecentPostFromPixelfed();
  }

  Future<Map<String, dynamic>> _fetchPostFromPixelfed(String mediaId) async {
    final response = await http.get(Uri.parse("$pixelfedInstance/api/v1/media/$mediaId"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'username': data['account']['username'],
        'profilePic': data['account']['avatar'],
        'imageUrl': data['url'],
        'likes': data['favourites_count'],
        'comments': data['replies_count'],
        'shares': data['reblogs_count']
      };
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map<String, dynamic>> _fetchRecentPostFromPixelfed() async {
    final response = await http.get(Uri.parse("$pixelfedInstance/api/v1/timelines/home"));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        final firstPost = data.first;
        return {
          'username': firstPost['account']['username'],
          'profilePic': firstPost['account']['avatar'],
          'imageUrl': firstPost['url'],
          'likes': firstPost['favourites_count'],
          'comments': firstPost['replies_count'],
          'shares': firstPost['reblogs_count']
        };
      } else {
        throw Exception('No recent posts found');
      }
    } else {
      throw Exception('Failed to load recent posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _postData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading post'));
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
                child: Image.network(data['imageUrl'], fit: BoxFit.cover),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
                    IconButton(icon: Icon(Icons.comment), onPressed: () {}),
                    IconButton(icon: Icon(Icons.share), onPressed: () {}),
                    IconButton(icon: Icon(Icons.bookmark_border), onPressed: () {}),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('${data['shares']} shares • ${data['likes']} likes • ${data['comments']} comments',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      },
    );
  }
}

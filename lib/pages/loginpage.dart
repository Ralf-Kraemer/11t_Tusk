import 'package:flutter/material.dart';
import 'package:icp/utils/helper.dart';
import 'package:icp/utils/httpclient.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';

import 'package:app_links/app_links.dart';
import '../state/objects/ApiOAuth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final appLinks = AppLinks();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Method to handle the incoming link (when the app is already running)
  void _handleIncomingLinks() {
    appLinks.uriLinkStream.listen((uri) async {
      if (uri != null) {
        await _handleUri(uri);
      }
    }, onError: (Object err) {
      print('Error occurred while handling URI: $err');
    });
  }

  // Extract the code from the URI
  String? extractCodeFromUri(Uri uri) {
    var parameters = Uri.splitQueryString(uri.query);
    return parameters.containsKey('code') ? parameters['code'] : null;
  }

  // Method to handle the URI after the user returns to the app from the web browser
  Future<void> _handleUri(Uri uri) async {
    var code = extractCodeFromUri(uri);
    if (code != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        var api = ApiOAuth();
        await api.exchangeCodeForTokens(code);  // Exchange code for tokens
        // Close the browser after the token exchange
        await FlutterWebBrowser.close();
        Navigator.pushReplacementNamed(context, '/homepage'); // Redirect to homepage after login
      } catch (e) {
        print('Error exchanging code for tokens: $e');
        setState(() {
          _isLoading = false;
        });
        // Handle error gracefully (e.g., show an error message to the user)
      }
    } else {
      print('No code found in URI');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to initiate the OAuth login process
  Future<void> _startOAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var api = ApiOAuth();
      var redirectUrl = await api.getRedirectUrl();
      // Open the browser to the OAuth URL
      await FlutterWebBrowser.openWebPage(url: redirectUrl);
    } catch (e) {
      print('Error starting OAuth process: $e');
      setState(() {
        _isLoading = false;
      });
      // Handle error gracefully (e.g., show an error message to the user)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator() // Show loading indicator when waiting for the login process
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _startOAuth, // Start OAuth login
                    child: Text('Login with OAuth'),
                  ),
                ],
              ),
      ),
    );
  }
}

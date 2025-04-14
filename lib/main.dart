import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:app_links/app_links.dart';

import 'state/objects/ApiOAuth.dart';
import 'AppTheme.dart';
import 'pages/homepage.dart';
import 'pages/loginpage.dart';
import 'utils/helper.dart';  // Assuming Helper class is in utils folder

void main() {
  runApp(ProviderScope(child: TuskApp()));
}

class TuskApp extends ConsumerStatefulWidget {
  @override
  _TuskAppState createState() => _TuskAppState();
}

class _TuskAppState extends ConsumerState<TuskApp> {
  final appLinks = AppLinks();
  StreamSubscription? _sub;
  bool _isLoading = true;  // Add a loading state
  bool _userIsLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();  // Check if the user is logged in when the app starts
    _handleIncomingLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Method to check if a valid token exists in the storage
  Future<void> _checkLoginStatus() async {
    var accessToken = await Helper.get().getPrefString('accessToken');
    if (accessToken != null) {
      // If there is an access token, try to validate it by calling the API or checking expiration
      var api = ApiOAuth();
      try {
        bool isValid = await api.maybeRefreshAccessToken() != null; // Validate token
        setState(() {
          _userIsLoggedIn = isValid;
          _isLoading = false;  // Set loading to false once the login check is done
        });
      } catch (e) {
        print("Error validating token: $e");
        setState(() {
          _userIsLoggedIn = false;
          _isLoading = false;  // Set loading to false even if there's an error
        });
      }
    } else {
      setState(() {
        _userIsLoggedIn = false;
        _isLoading = false;  // Set loading to false if no token exists
      });
    }
  }

  String? extractCodeFromUri(Uri uri) {
    var parameters = Uri.splitQueryString(uri.query);
    return parameters.keys.contains('code') ? parameters['code'] : null;
  }

  Future<void> loadTokens(Uri? uri) async {
    if (uri == null) return;
    print(uri.toString());
    var code = extractCodeFromUri(uri);
    if (code != null) {
      try {
        var api = ApiOAuth();
        await api.exchangeCodeForTokens(code);
        setState(() {
          _userIsLoggedIn = true;
        });
      } catch (e) {
        print("Error exchanging code for tokens: $e");
        // Handle error here, maybe show a dialog to the user or log it
      }
    } else {
      print("No authorization code found in the URI.");
    }

    // Close browser only if it was opened.
    try {
      await FlutterWebBrowser.close();
    } catch (e) {
      print("Error closing web browser: $e");
    }
  }

  // Handle incoming links while the app is already started.
  void _handleIncomingLinks() {
    _sub = appLinks.uriLinkStream.listen((Uri? uri) {
      if (!mounted) return;
      loadTokens(uri);
    }, onError: (Object err) {
      if (!mounted) return;
      print('Error in handling incoming link: $err');
      // Handle incoming link errors
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        title: 'icp.social',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),  // Loading indicator while checking login status
        ),
      );
    }

    return MaterialApp(
      title: 'icp.social',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _userIsLoggedIn ? HomePage() : LoginPage(),
    );
  }
}

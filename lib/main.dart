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
  runApp(ProviderScope(child: WeCQApp()));
}

class WeCQApp extends ConsumerStatefulWidget {
  @override
  _WeCQAppState createState() => _WeCQAppState();
}

class _WeCQAppState extends ConsumerState<WeCQApp> {
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
      var api = ApiOAuth();
      try {
        bool isValid = await api.maybeRefreshAccessToken() != null; 
        setState(() {
          _userIsLoggedIn = isValid;
          _isLoading = false;  
        });
      } catch (e) {
        setState(() {
          _userIsLoggedIn = false;
          _isLoading = false;  
        });
      }
    } else {
      setState(() {
        _userIsLoggedIn = false;
        _isLoading = false;  
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
      }
    } else {
      print("No authorization code found in the URI.");
    }

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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        title: 'wecq.social',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),  
        ),
      );
    }

    return MaterialApp(
            title: 'wecq.social',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: _userIsLoggedIn ? HomePage() : LoginPage(),
          );
  }
}

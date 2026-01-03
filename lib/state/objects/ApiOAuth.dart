import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiOAuth {
  final String _clientName = 'iqon';
  final String _clientWebsite = 'https://ralfkraemer.eu/iqon';
  final String _redirectUri = 'iqon://ralfkraemer.eu';
  final String _scope = 'read write follow push';

  // Helper class to store and retrieve data from SharedPreferences
  Future<String?> _getPrefString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<bool> _setPrefString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  Future<int?> _getPrefInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<bool> _setPrefInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key, value);
  }

  // Store tokens received from the OAuth response
  Future<void> storeTokens(dynamic tokens) async {
    if (tokens.containsKey('access_token')) {
      await _setPrefString('accessToken', tokens['access_token']);
    }
    if (tokens.containsKey('refresh_token')) {
      await _setPrefString('refreshToken', tokens['refresh_token']);
    }
    // No expiration is being stored here as per your requirement
  }

  // Set the base URL for the OAuth provider
  Future<void> setBaseUrl(String baseUrl) async {
    baseUrl = baseUrl.toLowerCase();
    if (!baseUrl.startsWith('https://') || baseUrl.isEmpty) {
      throw Exception('Base URL is not valid');
    }
    await _setPrefString('baseUrl', baseUrl);
  }

  // Get the redirect URL for OAuth
  Future<String> getRedirectUrl() async {
    final clientId = await _getPrefString('clientId');
    final baseUrl = await _getPrefString('baseUrl');
    final redirectUrl = '$baseUrl/oauth/authorize?client_id=$clientId&redirect_uri=$_redirectUri&response_type=code&scope=$_scope';
    return Uri.encodeFull(redirectUrl);
  }

  // Fetch client ID and secret if they don't exist yet
  Future<void> fetchClientIdSecret() async {
    final baseUrl = await _getPrefString('baseUrl');
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/apps'),
      body: {
        'client_name': _clientName,
        'redirect_uris': _redirectUri,
        'scopes': _scope,
        'website': _clientWebsite,
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      await _setPrefString('clientId', result['client_id'].toString());
      await _setPrefString('clientSecret', result['client_secret']);
    } else {
      throw Exception('Failed to load client ID and secret');
    }
  }

  // Exchange the OAuth code for tokens
  Future<void> exchangeCodeForTokens(String code) async {
    final baseUrl = await _getPrefString('baseUrl');
    final clientId = await _getPrefString('clientId');
    final clientSecret = await _getPrefString('clientSecret');

    final response = await http.post(
      Uri.parse('$baseUrl/oauth/token'),
      body: {
        'grant_type': 'authorization_code',
        'redirect_uri': _redirectUri,
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final tokens = json.decode(response.body);
      await storeTokens(tokens);
    } else {
      throw Exception('Failed to exchange code for tokens');
    }
  }

  // Refresh the access token using the refresh token
  Future<bool> refreshAccessToken() async {
    final baseUrl = await _getPrefString('baseUrl');
    final refreshToken = await _getPrefString('refreshToken');
    final clientId = await _getPrefString('clientId');
    final clientSecret = await _getPrefString('clientSecret');

    final response = await http.post(
      Uri.parse('$baseUrl/oauth/token'),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final tokens = json.decode(response.body);
      await storeTokens(tokens);
      return true;
    }
    return false;
  }

  // Check if the access token is valid or needs refreshing
  Future<String?> maybeRefreshAccessToken() async {
    var accessToken = await _getPrefString('accessToken');

    if (accessToken == null) {
      return null;  // No token exists
    }

    // Token is still valid if it's available
    return accessToken;
  }
}

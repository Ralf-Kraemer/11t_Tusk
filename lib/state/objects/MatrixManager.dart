import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

/// Singleton Matrix background service
class MatrixManager with WidgetsBindingObserver {
  static final MatrixManager _instance = MatrixManager._internal();
  factory MatrixManager() => _instance;

  MatrixManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  Client? _client;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get isLoggedIn => _client?.isLogged() ?? false;

  Client get client {
    final c = _client;
    if (c == null) {
      throw StateError('MatrixManager not initialized');
    }
    return c;
  }

  /// Initialize Matrix client + database
  Future<void> init({String appName = 'MatrixApp'}) async {
    if (_initialized) return;

    final dir = await getApplicationSupportDirectory();
    final db = await sqlite.openDatabase('${dir.path}/matrix.sqlite');

    _client = Client(
      appName,
      database: await MatrixSdkDatabase.init(
        appName,
        database: db,
      ),
    );

    await _client!.init();
    _initialized = true;
  }

  /// Login (POSitional args – correct)
  Future<void> login(
    String homeserver,
    String username,
    String password,
  ) async {
    if (!_initialized) {
      throw StateError('MatrixManager.init() must be called first');
    }

    final c = client;

    await c.checkHomeserver(Uri.https(homeserver, ''));

    await c.login(
      LoginType.mLoginPassword,
      identifier: AuthenticationUserIdentifier(user: username),
      password: password,
    );
  }

  /// Logout
  Future<void> logout() async {
    if (!_initialized) return;
    await client.logout();
  }

  /// Rooms (always read directly from client)
  List<Room> get rooms => client.rooms;

  /// Send text message
  Future<void> sendMessage(Room room, String text) {
    return room.sendTextEvent(text);
  }

  /// Join room if needed
  Future<void> joinRoom(Room room) async {
    if (room.membership != Membership.join) {
      await room.join();
    }
  }

  /// Lifecycle handling (NO fake reconnect logic)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Matrix SDK handles sync internally
  }

  /// Dispose
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }
}

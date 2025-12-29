// xmpp_manager.dart
import 'dart:async';

import 'package:xmpp_plugin/xmpp_plugin.dart';
import 'package:xmpp_plugin/models/message_model.dart';
import 'package:xmpp_plugin/models/connection_event.dart';
import 'package:xmpp_plugin/error_response_event.dart';
import 'package:xmpp_plugin/success_response_event.dart';
import 'package:xmpp_plugin/models/present_mode.dart';
import 'package:xmpp_plugin/models/chat_state_model.dart';

class XmppManager {
  XmppConnection? _connection;
  XmppListenerImpl? _listener;

  final _messages = StreamController<MessageChat>.broadcast();
  Stream<MessageChat> get messages => _messages.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> connect({
    required String username,
    required String password,
    required String host,
    String resource = 'Flutter',
    int port = 5222,
    bool requireSSL = false,
    bool autoDeliveryReceipt = true,
    bool useStreamManagement = false,
    bool automaticReconnection = true,
  }) async {
    final config = {
      'user_jid': '$username@$host/$resource',
      'password': password,
      'host': host,
      'port': port,
      'requireSSLConnection': requireSSL,
      'autoDeliveryReceipt': autoDeliveryReceipt,
      'useStreamManagement': useStreamManagement,
      'automaticReconnection': automaticReconnection,
    };

    _connection = XmppConnection(config);

    if (_listener != null) {
      XmppConnection.removeListener(_listener!);
    }

    _listener = XmppListenerImpl(
      onMessage: (msg) => _messages.add(msg),
      onConnection: (event) {
        print('XMPP connection event: ${event.type}');
        _isConnected = _checkConnected(event);
        if (_isConnected) {
          _sendInitialPresence();
        }
      },
      onError: (error) => print('XMPP error: ${error.error}'),
      onSuccess: (success) => print('XMPP success: ${success.type}'),
      onPresence: (presence) {
        print(
            'XMPP presence: type=${presence.presenceType ?? "null"}, '
            'mode=${presence.presenceMode ?? "null"}');
      },
    );

    XmppConnection.addListener(_listener!);

    try {
      await _connection!.start((error) {
        print('XMPP start error: $error');
        _isConnected = false;
      });

      await _connection!.login();
      print('XMPP login completed');

      // Do not send presence here; wait for authenticated event
    } catch (e) {
      print('Error during connect/login: $e');
      _isConnected = false;
    }
  }

  bool _checkConnected(ConnectionEvent event) {
    final typeStr = event.type.toString().toLowerCase();
    return typeStr.contains('authenticated') || typeStr.contains('success');
  }

  Future<void> _sendInitialPresence() async {
    if (_connection == null || !_isConnected) return;
    try {
      await _connection!.changePresenceType('available', 'chat');
      print('XMPP initial presence sent');
    } catch (e) {
      print('Error sending initial presence: $e');
    }
  }

  Future<void> changePresence(String mode) async {
    if (_connection == null || !_isConnected) return;
    try {
      await _connection!.changePresenceType('available', mode);
      print('XMPP presence changed: mode=$mode');
    } catch (e) {
      print('Error changing presence: $e');
    }
  }

  Future<void> sendMessage(String to, String body) async {
    if (_connection == null || !_isConnected) {
      print('XMPP not connected → cannot send');
      return;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'msg_$timestamp';
    try {
      await _connection!.sendMessage(to, body, id, timestamp);
    } catch (e) {
      print('Error sending XMPP message: $e');
    }
  }

  Future<void> dispose() async {
    if (_listener != null) {
      XmppConnection.removeListener(_listener!);
      _listener = null;
    }
    try {
      await _connection?.logout();
    } catch (_) {}
    await _messages.close();
    _isConnected = false;
    print('XmppManager disposed');
  }
}

class XmppListenerImpl implements DataChangeEvents {
  final void Function(MessageChat) onMessage;
  final void Function(ConnectionEvent) onConnection;
  final void Function(ErrorResponseEvent) onError;
  final void Function(SuccessResponseEvent) onSuccess;
  final void Function(PresentModel) onPresence;

  XmppListenerImpl({
    required this.onMessage,
    required this.onConnection,
    required this.onError,
    required this.onSuccess,
    required this.onPresence,
  });

  @override
  void onChatMessage(MessageChat m) => onMessage(m);

  @override
  void onNormalMessage(MessageChat m) => onMessage(m);

  @override
  void onGroupMessage(MessageChat m) => onMessage(m);

  @override
  void onConnectionEvents(ConnectionEvent e) => onConnection(e);

  @override
  void onXmppError(ErrorResponseEvent e) => onError(e);

  @override
  void onSuccessEvent(SuccessResponseEvent e) => onSuccess(e);

  @override
  void onPresenceChange(PresentModel? p) {
    if (p == null) return;
    onPresence(p);
  }

  @override
  void onChatStateChange(ChatState c) {}
}

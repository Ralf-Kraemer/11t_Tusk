import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import '../state/objects/MatrixManager.dart';
import 'chatlistview.dart';

class ChatLogin extends StatefulWidget {

  const ChatLogin({super.key});

  @override
  State<ChatLogin> createState() => _ChatLoginState();
}

class _ChatLoginState extends State<ChatLogin> {
  final _homeserverController = TextEditingController(text: 'matrix.org');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);

    final homeserver = _homeserverController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      // Check homeserver availability
      await MatrixManager().client.checkHomeserver(Uri.https(homeserver, ''));

      // Perform login
      await MatrixManager().client.login(
        LoginType.mLoginPassword,
        password: password,
        identifier: AuthenticationUserIdentifier(user: username),
      );

      if (!mounted) return;

      // Navigate to room/ChatListView list
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ChatListView()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matrix Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _homeserverController,
              readOnly: _loading,
              decoration: const InputDecoration(
                labelText: 'Homeserver',
                prefixText: 'https://',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              readOnly: _loading,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              readOnly: _loading,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iqon/utils/helper.dart';

class Scope extends StatefulWidget {
  const Scope({super.key});

  @override
  State<Scope> createState() => _ScopeState();
}

class _ScopeState extends State<Scope> {

  final Helper helper = Helper.get();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const ExpansionTile(
          title: Text('👥 People'),
          initiallyExpanded: false,
          subtitle: Text('Trailing expansion arrow icon'),
          children: <Widget>[ListTile(title: Text('This is tile number 1'))],
        ),
        const ExpansionTile(
          title: Text('📈 #Trends '),
          initiallyExpanded: false,
          subtitle: Text('Trailing expansion arrow icon'),
          children: <Widget>[ListTile(title: Text('This is tile number 2'))],
        ),
        const ExpansionTile(
          title: Text('🔔 Alerts'),
          initiallyExpanded: true,
          subtitle: Text('Trailing expansion arrow icon'),
          children: <Widget>[
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 1'),
                  subtitle: Text('This is a notification'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 2'),
                  subtitle: Text('This is a notification'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 3'),
                  subtitle: Text('This is a notification'),
                ),
              ),
            ],
        ),
      ],
    );
  }
}
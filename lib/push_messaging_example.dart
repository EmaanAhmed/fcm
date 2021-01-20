import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'item.dart';

final Map<String, Item> items = <String, Item>{};
Item _itemForMessage(Map<String, dynamic> message) {
  final dynamic data = message['data'] ?? message;
  final String itemId = data['id'];
  final Item item = items.putIfAbsent(itemId, () => Item(itemId: itemId))
    ..status = data['status'];
  return item;
}

class PushMessagingExample extends StatefulWidget {
  PushMessagingExample({Key key}) : super(key: key);

  @override
  _PushMessagingExampleState createState() => _PushMessagingExampleState();
}

class _PushMessagingExampleState extends State<PushMessagingExample> {
  String _homeScreenText = 'Waiting for token...';
  bool _topicButtonsDisabled = false;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final TextEditingController _topicController =
      TextEditingController(text: 'topic');

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.configure(
      onMessage: (message) async {
        print('onMessage: $message');
        _showItemDialog(message);
      },
      onLaunch: (message) async {
        print('onLaunch: $message');
        _navigatToItemDetail(message);
      },
      onResume: (message) async {
        print('onResume: $message');
        _navigatToItemDetail(message);
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print('Settings registered: $settings');
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      setState(() {
        _homeScreenText = 'Push Messaging token: $token';
      });
      print(_homeScreenText);
    });
  }

  Widget _buildDialog(BuildContext context, Item item) {
    return AlertDialog(
      content: Text('Item ${item.itemId} has been updated'),
      actions: [
        FlatButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text('CLOSE'),
        ),
        FlatButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text('SHOW'),
        ),
      ],
    );
  }

  void _showItemDialog(Map<String, dynamic> message) {
    showDialog<bool>(
      context: context,
      builder: (_) => _buildDialog(context, _itemForMessage(message)),
    ).then((bool shouldNavigate) {
      if (shouldNavigate) {
        _navigatToItemDetail(message);
      }
    });
  }

  void _navigatToItemDetail(Map<String, dynamic> message) {
    final Item item = _itemForMessage(message);
    // Clear away dialogs
    Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
    if (!item.route.isCurrent) {
      Navigator.push(context, item.route);
    }
  }

  void _clearTopicText() {
    setState(() {
      _topicController.text = '';
      _topicButtonsDisabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Push Messaging Demo'),
      ),
      // For testing -- simulate a message being received
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(<String, dynamic>{
          "data": <String, String>{"id": "2", "status": "out of stock"}
        }),
        tooltip: 'Simulate Message',
        child: Icon(Icons.message),
      ),
      body: Material(
        child: Column(
          children: [
            Center(
              child: Text(_homeScreenText),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: _topicController,
                      onChanged: (String v) {
                        setState(() {
                          _topicButtonsDisabled = v.isEmpty;
                        });
                      }),
                ),
                FlatButton(
                  child: const Text("subscribe"),
                  onPressed: _topicButtonsDisabled
                      ? null
                      : () {
                          _firebaseMessaging
                              .subscribeToTopic(_topicController.text);
                          _clearTopicText();
                        },
                ),
                FlatButton(
                  child: const Text("unsubscribe"),
                  onPressed: _topicButtonsDisabled
                      ? null
                      : () {
                          _firebaseMessaging
                              .unsubscribeFromTopic(_topicController.text);
                          _clearTopicText();
                        },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

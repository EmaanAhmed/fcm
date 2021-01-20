import 'dart:async';

import 'package:flutter/material.dart';

import 'item.dart';
import 'push_messaging_example.dart';

class DetailPage extends StatefulWidget {
  final String itemId;
  DetailPage(this.itemId);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Item _item;
  StreamSubscription<Item> _subscription;

  @override
  void initState() {
    super.initState();
    _item = items[widget.itemId];
    _subscription = _item.onChanged.listen((Item item) {
      if (!mounted) {
        _subscription.cancel();
      } else {
        setState(() {
          _item = item;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item ${_item.itemId}'),
      ),
      body: Material(
        child: Center(
          child: Text('Item status: ${_item.status}'),
        ),
      ),
    );
  }
}

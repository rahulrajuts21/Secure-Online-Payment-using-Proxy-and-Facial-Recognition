import 'package:flutter/material.dart';

import 'home.dart';

class Profile extends StatelessWidget {
  const Profile({Key key, @required this.username}) : super(key: key);

  final String username;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment complete!'),
        leading: Container(),
      ),
      body: Container(
        child: Column(
          children: [
            RaisedButton(
              child: Text('Done'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

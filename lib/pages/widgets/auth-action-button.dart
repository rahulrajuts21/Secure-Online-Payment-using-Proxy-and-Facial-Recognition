import 'package:FaceNetAuthentication/pages/db/database.dart';
import 'package:FaceNetAuthentication/pages/profile.dart';
import 'package:FaceNetAuthentication/services/facenet.service.dart';
import 'package:flutter/material.dart';
import '../home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:random_string/random_string.dart';
import 'dart:math';

class User {
  String user;
  String password;
  String uniqcode;

  User({@required this.user, @required this.password, @required uniqcode});

  static User fromDB(String dbuser) {
    return new User(
        user: dbuser.split(':')[0],
        password: dbuser.split(':')[1],
        uniqcode: dbuser.split(':')[2]);
  }
}

class AuthActionButton extends StatefulWidget {
  AuthActionButton(this._initializeControllerFuture,
      {@required this.onPressed, @required this.isLogin});
  final Future _initializeControllerFuture;
  final Function onPressed;
  final bool isLogin;
  @override
  _AuthActionButtonState createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  /// service injection
  final FaceNetService _faceNetService = FaceNetService();
  final DataBaseService _dataBaseService = DataBaseService();

  final TextEditingController _userTextEditingController =
      TextEditingController(text: '');
  final TextEditingController _passwordTextEditingController =
      TextEditingController(text: '');

  User predictedUser;

  Future<http.Response> registerUserWithBank(
      String user, String accountnumber, String data) {
    try {
      return http.post('http://192.168.1.102:5000/register', body: {
        "user": user,
        "accountnumber": accountnumber,
        "data": data.toString()
      }).timeout(Duration(seconds: 15));
    } on TimeoutException catch (e) {
      print('Timeout Error: $e');
    } on SocketException catch (e) {
      print('Socket Error: $e');
    } on Error catch (e) {
      print('General Error: $e');
    }
    return null;
  }

  Future _signUp(context) async {
    /// gets predicted data from facenet service (user face detected)
    List predictedData = _faceNetService.predictedData;
    String user = _userTextEditingController.text;
    String password = _passwordTextEditingController.text;

    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();
    String getRandomString(int length) =>
        String.fromCharCodes(Iterable.generate(
            length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
    String uniqcode = getRandomString(15);

    /// creates a new user in the 'database'
    await _dataBaseService.saveData(user, password, predictedData, uniqcode);

    /// Send data to the bank's database
    final response = await registerUserWithBank(user, password, uniqcode);
    print(response);

    /// resets the face stored in the face net sevice
    this._faceNetService.setPredictedData(null);
    Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) => MyHomePage()));
  }

  Future _signIn(context) async {
    String password = _passwordTextEditingController.text;

    // if (this.predictedUser.password == password) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => Profile(
                  username: this.predictedUser.user,
                )));
    // } else {
    //   print(" WRONG PASSWORD!");
    // }
  }

  String _predictUser() {
    String userAndPass = _faceNetService.predict();
    print(userAndPass);
    return userAndPass ?? null;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      label: widget.isLogin ? Text('Pay') : Text('Register'),
      icon: Icon(Icons.camera_alt),
      // Provide an onPressed callback.
      onPressed: () async {
        try {
          // Ensure that the camera is initialized.
          await widget._initializeControllerFuture;
          // onShot event (takes the image and predict output)
          bool faceDetected = await widget.onPressed();

          if (faceDetected) {
            if (widget.isLogin) {
              print("in");
              var userAndPass = _predictUser();
              print("out");
              if (userAndPass != null) {
                this.predictedUser = User.fromDB(userAndPass);
              }
            }
            Scaffold.of(context)
                .showBottomSheet((context) => signSheet(context));
          }
        } catch (e) {
          // If an error occurs, log the error to the console.
          print(e);
        }
      },
    );
  }

  signSheet(context) {
    return Container(
      padding: EdgeInsets.all(20),
      height: 300,
      child: Column(
        children: [
          widget.isLogin && predictedUser != null
              ? Container(
                  child: Text(
                    'Welcome back, ' + predictedUser.user + '! 😄',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : widget.isLogin
                  ? Container(
                      child: Text(
                      'User not found 😞',
                      style: TextStyle(fontSize: 20),
                    ))
                  : Container(),
          !widget.isLogin
              ? Padding(
                  padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.lightBlueAccent)),
                    child: TextField(
                      controller: _userTextEditingController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: "Name",
                      ),
                    ),
                  ))
              : Container(),
          SizedBox(height: 10),
          widget.isLogin
              ? Container()
              : Padding(
                  padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.blueGrey)),
                    child: TextField(
                      controller: _passwordTextEditingController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: "Account number",
                      ),
                    ),
                  )),
          SizedBox(height: 10),
          widget.isLogin && predictedUser != null
              ? RaisedButton(
                  textColor: Colors.white,
                  padding: const EdgeInsets.all(0.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Color(0xFF0D47A1),
                          Color(0xFF1976D2),
                          Color(0xFF42A5F5),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(15.0),
                    child: const Text('Proceed for payment',
                        style: TextStyle(fontSize: 20)),
                  ),
                  onPressed: () async {
                    _signIn(context);
                  },
                )
              : !widget.isLogin
                  ? RaisedButton(
                      child: Text('Sign Up!'),
                      onPressed: () async {
                        await _signUp(context);
                      },
                    )
                  : Container(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

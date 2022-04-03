import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const AutoAgnigarh());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class AutoAgnigarh extends StatelessWidget {
  const AutoAgnigarh({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoAgnigarh',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: const MyHomePage(title: 'AutoAgnigarh'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String username = "",
      password = "",
      logoutUrl = "https://192.168.193.1:1442/logout?090706070f040c06",
      keepAliveUrl = "",
      message = "Not logged In.";
  bool isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    final usernameController = TextEditingController(text: username);
    final passwordController = TextEditingController(text: password);
    const agnigarhLoginUrl = "https://agnigarh.iitg.ac.in:1442/login?";

    void _launchURL(url) async {
      if (!await launch(url)) throw 'Could not launch $url';
    }

    Timer keepAliveTimer = Timer(const Duration(seconds: 0), () => {});
    void _cancelKeepAliveTimer() {
      keepAliveTimer.cancel();
    }

    void _keepAlive(Timer timer) async {
      try {
        print("keeping alive...");
        if (keepAliveUrl == "") {
          return;
        }
        final resp = await http.get(Uri.parse(keepAliveUrl));
        if (resp.statusCode == 200) {
          print("refreshed!");
        } else {
          throw Exception();
        }
      } catch (e) {
        print(e);
        _cancelKeepAliveTimer();
        setState(() {
          isLoggedIn = false;
          message = "Could not login.";
        });
      }
    }

    void _login() async {
      String msg = message;
      bool loginSuccess = false;
      try {
        var resp = await http.get(Uri.parse(agnigarhLoginUrl));
        if (resp.statusCode == 200) {
          String body = resp.body;
          final regExp = RegExp(r'value="[a-zA-Z0-9.\/:\?]*');
          final matches = regExp.allMatches(resp.body).take(2);
          String tredir = matches.first.group(0).toString().substring(7);
          String magic = matches.elementAt(1).group(0).toString().substring(7);
          Map<String, String> data = {
            "4Tredir": tredir,
            "magic": magic,
            "username": username,
            "password": password
          };
          print("Logging in as $username.....\n");
          resp = await http.post(Uri.parse("https://agnigarh.iitg.ac.in:1442"),
              body: data);

          if (resp.body.contains("logged in as")) {
            print("logged in!");
            loginSuccess = true;
            msg = "You are logged in as $username.";
            final logoutRegex =
                RegExp(r'https:\/\/[a-zA-Z0-9.:]*\/logout\?[a-zA-Z0-9]*');
            final keepAliveRegex =
                RegExp(r'https:\/\/[a-zA-Z0-9.:]*\/keepalive\?[a-zA-Z0-9]*');
            var match = logoutRegex.firstMatch(resp.body);
            if (match != null) {
              logoutUrl = match.group(0).toString();
            }
            match = keepAliveRegex.firstMatch(resp.body);
            if (match != null) {
              keepAliveUrl = match.group(0).toString();
            }
            keepAliveTimer =
                Timer.periodic(const Duration(seconds: 100), _keepAlive);
          } else if (resp.body.contains("Firewall authentication failed")) {
            loginSuccess = false;
            msg = "Firewall authentication failed. Please try again.";
          } else if (resp.body.contains("concurrent authentication")) {
            loginSuccess = false;
            msg = "You are logged in somewhere else too.";
          } else {
            msg = "Caught error while logging in.";
          }
        } else {
          loginSuccess = false;
          msg = "Login failed. Please try again!";
        }
      } catch (e) {
        print(e.toString());
        loginSuccess = false;
        msg = "Can't connect with agnigarh server.";
      }
      setState(() {
        message = msg;
        isLoggedIn = loginSuccess;
      });
    }

    void _logout() async {
      if (logoutUrl == "" || isLoggedIn == false) {
        return;
      }
      try {
        final resp = await http.get(Uri.parse(logoutUrl));
        if (resp.statusCode == 200) {
          setState(() {
            isLoggedIn = false;
            message = "Logged out successfully!";
          });
        } else {
          setState(() {
            message = "Unable to logout";
          });
        }
      } catch (e) {
        print(e.toString());
        setState(() {
          message = "Unable to logout";
        });
      }
    }

    // button handlers

    void _loginBtnHandler() async {
      setState(() {
        username = usernameController.text;
        password = passwordController.text;
      });
      _login();
    }

    void _logoutBtnHandler() async {
      _cancelKeepAliveTimer();
      _logout();
    }

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.title)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: Text(
                  (isLoggedIn ? "Logged" : "Sign") + " in to the IITG Network",
                  style: const TextStyle(fontSize: 22),
                )),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(10),
              child: TextField(
                enabled: !isLoggedIn,
                controller: usernameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'User Name',
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: TextField(
                obscureText: true,
                enabled: !isLoggedIn,
                textInputAction: TextInputAction.done,
                controller: passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  _launchURL("https://online.iitg.ac.in/user/resetpwd"),
              child: const Text(
                'Forgot Password',
              ),
            ),
            Container(
                height: 50,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: ElevatedButton(
                  child: Text(isLoggedIn ? 'Logout' : 'Login'),
                  onPressed: () =>
                      isLoggedIn ? _logoutBtnHandler() : _loginBtnHandler(),
                )),
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 12),
                )),
          ],
        ),
      ),
    );
  }
}

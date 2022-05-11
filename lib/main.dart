import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'iitg_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final auth = Auth();
  bool isLoginBtnDisabled = false;
  @override
  Widget build(BuildContext context) {
    final usernameController = TextEditingController(text: auth.username);
    final passwordController = TextEditingController(text: auth.password);

    void _launchURL(url) async {
      if (!await launch(url)) throw 'Could not launch $url';
    }

    Timer keepAliveTimer = Timer(const Duration(seconds: 0), () => {});
    // Timer autoLoginTimer = Timer(const Duration(seconds: 0), () => {});

    void _cancelKeepAliveTimer() {
      keepAliveTimer.cancel();
    }

    // void _cancelAutoLoginTimer() {
    //   autoLoginTimer.cancel();
    // }

    Future<void> _keepAlive(Timer timer) async {
      bool done = await auth.keepAlive();
      if (!done) {
        print("keepAlive failed. Trying to login again.");
        setState(() {
          _cancelKeepAliveTimer();
        });
        await auth.login();
        setState(() {});
        if (auth.isLoggedIn) {
          keepAliveTimer =
              Timer.periodic(const Duration(seconds: 100), _keepAlive);
        }
      }
    }

    // button handlers

    Future<void> _loginBtnHandler() async {
      setState(() {
        isLoginBtnDisabled = true;
        auth.username = usernameController.text;
        auth.password = passwordController.text;
        auth.message = "Logging in...";
      });
      await auth.login();
      if (auth.isLoggedIn) {
        keepAliveTimer =
            Timer.periodic(const Duration(seconds: 100), _keepAlive);
      }
      setState(() {
        isLoginBtnDisabled = false;
      });

      // if (!autoLoginTimer.isActive) {
      //   autoLoginTimer =
      //       Timer.periodic(const Duration(seconds: 5), (timer) async {
      //     if (!auth.isLoggedIn && auth.username != "" && auth.password != "") {
      //       await _loginBtnHandler();
      //     }
      //   });
      // }
    }

    Future<void> _logoutBtnHandler() async {
      _cancelKeepAliveTimer();
      // _cancelAutoLoginTimer();
      await auth.logout();
      setState(() {});
    }

    Future<void> loadCredentials() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var username = await prefs.getString('username');
      var password = await prefs.getString('password');
      if (username != null) {
        auth.username = usernameController.text = username;
      }
      if (password != null) {
        auth.password = passwordController.text = password;
      }
      // autoLoginTimer =
      //     Timer.periodic(const Duration(seconds: 5), (timer) async {
      //   if (!auth.isLoggedIn && auth.username != "" && auth.password != "") {
      //     await _loginBtnHandler();
      //   }
      // });
    }

    return FutureBuilder(
        future: loadCredentials(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
                appBar: AppBar(
                  title: Center(child: Text(widget.title)),
                ),
                body: Center(child: Text("Loading...")));
          } else {
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
                          (auth.isLoggedIn ? "Logged" : "Sign") +
                              " in to the IITG Network",
                          style: const TextStyle(fontSize: 22),
                        )),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        enabled: !auth.isLoggedIn,
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
                        enabled: !auth.isLoggedIn,
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
                          child: Text(auth.isLoggedIn ? 'Logout' : 'Login'),
                          onPressed: isLoginBtnDisabled
                              ? null
                              : () => auth.isLoggedIn
                                  ? _logoutBtnHandler()
                                  : _loginBtnHandler(),
                        )),
                    Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          auth.message,
                          style: const TextStyle(fontSize: 12),
                        )),
                  ],
                ),
              ),
            );
          }
        });
  }
}

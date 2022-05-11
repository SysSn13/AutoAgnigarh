import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class Auth {
  String username = "",
      password = "",
      logoutUrl = "https://192.168.193.1:1442/logout?090706070f040c06",
      keepAliveUrl = "",
      message = "Not logged In.";
  bool isLoggedIn = false;

  Auth() {}
  static const agnigarhLoginUrl = "https://agnigarh.iitg.ac.in:1442/login?";
  Future<void> login() async {
    // update the credentials
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);

    String msg = message;
    bool loginSuccess = false;
    try {
      var resp = await http.get(Uri.parse(agnigarhLoginUrl));
      if (resp.statusCode == 200) {
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
        } else if (resp.body.contains("Firewall authentication failed")) {
          loginSuccess = false;
          msg = "Firewall authentication failed. Please try again.";
        } else if (resp.body.contains("concurrent authentication")) {
          loginSuccess = false;
          msg = "You are logged in somewhere else too.";
        } else {
          msg = "Couldn't login.";
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
    isLoggedIn = loginSuccess;
    message = msg;
    print(message);
  }

  Future<void> logout() async {
    if (logoutUrl == "" || isLoggedIn == false) {
      return;
    }
    try {
      final resp = await http.get(Uri.parse(logoutUrl));
      if (resp.statusCode == 200) {
        isLoggedIn = false;
        message = "Logged out successfully!";
      } else {
        message = "Unable to logout";
      }
    } catch (e) {
      print(e.toString());
      message = "Unable to logout";
    }
  }

  Future<bool> keepAlive() async {
    try {
      print("keeping alive...");
      if (keepAliveUrl == "") {
        return false;
      }
      final resp = await http.get(Uri.parse(keepAliveUrl));
      if (resp.statusCode == 200) {
        print("refreshed!");
        return true;
      } else {
        throw Exception();
      }
    } catch (e) {
      print(e);
      isLoggedIn = false;
      message = "Could not login.";
      return false;
    }
  }
}

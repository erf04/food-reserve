import 'package:application/main.dart';
import 'package:application/repository/HttpClient.dart';
import 'package:application/repository/tokenManager.dart';
import 'package:application/widgets/MainPage.dart';
import 'package:flutter/material.dart';

class PostData {


  Future<void> getAuthLogin(
      String myUser, String myPass, context) async {
    final response = await HttpClient.instance.post('auth/jwt/create/',
        data: {'username': myUser, 'password': myPass});
    if (response.statusCode == 200) {
      TokenManager.saveTokens(response.data["access"], response.data["refresh"]);
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) =>MainPage()));
    } else {}
  }

}

import 'package:application/repository/HttpClient.dart';
import 'package:application/repository/sharedPreferences.dart';
import 'package:application/widgets/MainPage.dart';
import 'package:application/widgets/loginSignUp_state.dart';
import 'package:flutter/cupertino.dart';

enum VerifyToken {
  expired,
  loggedOut,
  verified;
}

class TokenManager {
  static Future<Widget> initialPage() async {
    String? myAccess = await TokenManager.getAccessToken();
    if (myAccess == null) {
      return const LoginSignUp();
    }
    try{
    await HttpClient.instance
        .post('auth/jwt/verify/', data: {'token': myAccess});
    return MainPage();
    }catch (e){ 
      try{
      await HttpClient.instance.post('auth/jwt/refresh/', data: {
        "refresh": await TokenManager.getRefreshToken()});
        return MainPage();
      }
      catch(e){
        return LoginSignUp();
      }
    }
  }

  static Future<VerifyToken?> verifyAccess(BuildContext context) async {
    String? myAccess = await TokenManager.getAccessToken();
    //print(myAccess);
    if (myAccess == null) {
      return VerifyToken.loggedOut;
    }
    return await HttpClient.instance
        .post('auth/jwt/verify/', data: {"token": myAccess}).then((response) {
      //print(';aha');
      return VerifyToken.verified;
    }).catchError((error) async {
      final response2 = await HttpClient.instance.post('auth/jwt/refresh/',
          data: {
            "refresh": await TokenManager.getRefreshToken()
          }).then((response2) {
        TokenManager.setAccessToken(response2.data["access"]);
        //print("TRUE");
        return VerifyToken.verified;
      }).catchError((onError) {
        //print("LETS SEE");
        Future.delayed(const Duration(milliseconds: 1)).then((value) {
          Navigator.of(context)
              .pushReplacement(CupertinoPageRoute(builder: (context) {
            return const LoginSignUp();
          }));
        });
        //print("SHADIDAN RIDIN");
        return VerifyToken.expired;
      });
      return response2;
    });
  }

  static Future<void> saveTokens(
      String accessToken, String refreshToken) async {
    await SharedPreferencesManager.instance
        .setString('accessToken', accessToken);
    await SharedPreferencesManager.instance
        .setString('refreshToken', refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await SharedPreferencesManager.instance.getString('accessToken');
  }

  static Future<String?> getRefreshToken() async {
    return await SharedPreferencesManager.instance.getString('refreshToken');
  }

  static Future<void> setAccessToken(String token) async {
    await SharedPreferencesManager.instance.setString('accessToken', token);
    return;
  }

  static Future<void> setRefreshToken(String token) async {
    SharedPreferencesManager.instance.setString('refreshToken', token);
  }

  static Future<void> clearTokens() async {
    await SharedPreferencesManager.instance.remove('accessToken');
    await SharedPreferencesManager.instance.remove('refreshToken');
  }
}

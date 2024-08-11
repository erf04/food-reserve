import 'dart:convert';

import 'package:application/gen/assets.gen.dart';
import 'package:application/main.dart';
import 'package:application/repository/HttpClient.dart';
import 'package:application/repository/tokenManager.dart';
import 'package:application/widgets/MainPage.dart';
import 'package:application/widgets/SoftenPageTransition.dart';
import 'package:application/widgets/forgotPassword.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class EnglishInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Regular expression for English characters (letters, numbers, and some punctuation)
    final RegExp regExp = RegExp(r'^[a-zA-Z0-9\s\.,?!]*$');

    // Check if the new value matches the regular expression
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }

    // If not, return the old value
    return oldValue;
  }
}

class LoginSignUp extends StatefulWidget {
  const LoginSignUp({super.key});

  @override
  State<LoginSignUp> createState() => _LoginSignUpState();
}

class _LoginSignUpState extends State<LoginSignUp> {
  bool signUpError = false;
  bool isInError = false;
  bool isInSignUp = false;
  bool obscurity = true;
  String? loginError = null;
  String? emailError = null;
  String? userNameError = null;
  String? passwordError = null;
  String? notALike = null;
  TextEditingController myController1 = TextEditingController();
  TextEditingController myController2 = TextEditingController();
  TextEditingController myController3 = TextEditingController();
  TextEditingController myController4 = TextEditingController();
  TextEditingController myController5 = TextEditingController();
  TextEditingController myController6 = TextEditingController();
  Future<void> getAuthLogin(String myUser, String myPass, context) async {
    try {
      final response = await HttpClient.instance.post('api/login/',
          options: Options(
            followRedirects: false,
            validateStatus: (status) {
              return status! < 500;
            },
          ),
          data: {'username': myUser, 'password': myPass}).then((response) {
        TokenManager.saveTokens(
            response.data["access"], response.data["refresh"]);
        FadePageRoute.navigateToNextPage(context, MainPage());
        //print(response.data);
      });
    } catch (e) {
        setState(() {
          loginError = 'اطلاعات وارد شده معتبر نیست';
        });
    }
  }

  Future<Map<String, dynamic>?> getAuthSignUp(
      String myUser,
      String myPass,
      String firstName,
      String lastName,
      String email,
      BuildContext context) async {
    firstName =
        firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
    lastName = lastName[0].toUpperCase() + lastName.substring(1).toLowerCase();
    Map<String, dynamic>? responseBody;
    final response;
    var me;
    try {
      response = await HttpClient.instance.post('api/register/',
          options: Options(
            followRedirects: false,
            validateStatus: (status) {
              return status! < 500;
            },
            headers: <String, String>{'App-Token': dotenv.env['API_KEY']!},
          ),
          data: {
            'username': myUser,
            'password': myPass,
            'first_name': firstName,
            'last_name': lastName,
            'email': email
          });
      if (response.statusCode == 201) {
        getAuthLogin(myUser, myPass, context);
        return null;
      }
      if (response.statusCode == 400) {
        setState(() {
          this.emailError = response.data?['email'][0];
          this.userNameError = response.data?['username'][0];
          this.passwordError = response.data?['password'][0];
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/new4.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: const [BoxShadow(blurRadius: 2)],
                  borderRadius: BorderRadius.circular(12)),
              width: MediaQuery.of(context).size.width * 0.8,
              height: isInSignUp
                  ? MediaQuery.of(context).size.height * 0.86
                  : MediaQuery.of(context).size.height * 0.64,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: isInSignUp ? getSignUp(context) : getLogin(context),
              ),
            ),
          ),
        )
      ],
    )));
  }

  Column getLogin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  this.isInSignUp = false;
                });
              },
              child: Text(
                "ورود",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: isInSignUp ? Colors.blueGrey : Colors.black),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  this.isInSignUp = true;
                });
              },
              child: Text(
                "ثبت نام",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: isInSignUp ? Colors.black : Colors.blueGrey),
              ),
            ),
          ],
        ),
        Column(children: [
          const SizedBox(
            height: 40,
          ),
          TextField(
            controller: myController1,
            enableSuggestions: true,
            autocorrect: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
            ],
            decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                fillColor: Colors.black12,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                filled: true,
                label: Text('نام کاربری')),
          ),
          const SizedBox(
            height: 20,
          ),
          TextField(
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
            ],
            controller: myController2,
            enableSuggestions: false,
            autocorrect: false,
            obscureText: obscurity,
            decoration: InputDecoration(
                errorText: loginError,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                fillColor: Colors.black12,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                filled: true,
                suffixIcon: TextButton(
                    onPressed: () {
                      setState(() {
                        obscurity = !obscurity;
                      });
                    },
                    child: Text(obscurity ? 'نمایش' : 'پنهان',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey))),
                label: const Text('پسورد')),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("آیا اکانت دارید؟",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 15)),
              TextButton(
                  onPressed: () {
                    setState(() {
                      isInSignUp = true;
                    });
                  },
                  child: Text(
                    "ثبت نام کنید",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Colors.blueGrey, fontSize: 15),
                  ))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "فراموشی پسورد؟",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 15),
              ),
              TextButton(
                  onPressed: () {
                    FadePageRoute.navigateToNextPage(
                        context, ForgotPasswordPage());
                  },
                  child: Text(
                    "کلیک کنید",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Colors.blueGrey, fontSize: 15),
                  ))
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          ElevatedButton(
              onPressed: () {
                getAuthLogin(myController1.text, myController2.text, context);
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width, 50),
                  backgroundColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: Text("تایید",
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)))
        ])
      ],
    );
  }

  Widget getSignUp(BuildContext context) {
    bool notEqualError = false;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    this.isInSignUp = false;
                  });
                },
                child: Text(
                  "ورود",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      color: isInSignUp ? Colors.blueGrey : Colors.black),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    this.isInSignUp = true;
                  });
                },
                child: Text(
                  "ثبت نام",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      color: isInSignUp ? Colors.black : Colors.blueGrey),
                ),
              ),
            ],
          ),
          Column(children: [
            const SizedBox(
              height: 40,
            ),
            TextField(
              controller: myController1,
              enableSuggestions: true,
              autocorrect: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
              ],
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  errorText: userNameError,
                  fillColor: Colors.black12,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                  filled: true,
                  label: Text('نام کاربری')),
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
              ],
              controller: myController4,
              enableSuggestions: true,
              autocorrect: true,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  fillColor: Colors.black12,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                  filled: true,
                  label: Text('نام')),
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
              ],
              controller: myController5,
              enableSuggestions: true,
              autocorrect: true,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  fillColor: Colors.black12,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                  filled: true,
                  label: Text('نام خانوادگی')),
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
              ],
              controller: myController6,
              enableSuggestions: true,
              autocorrect: true,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  errorText: emailError,
                  fillColor: Colors.black12,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                  filled: true,
                  label: Text('ایمیل')),
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
              ],
              controller: myController2,
              enableSuggestions: false,
              autocorrect: false,
              obscureText: obscurity,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  fillColor: Colors.black12,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                  filled: true,
                  suffixIcon: TextButton(
                      onPressed: () {
                        setState(() {
                          obscurity = !obscurity;
                        });
                      },
                      child: Text(obscurity ? 'نمایش' : 'پنهان',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey))),
                  errorText: passwordError,
                  label: const Text('پسورد')),
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
              ],
              controller: myController3,
              enableSuggestions: false,
              autocorrect: false,
              obscureText: obscurity,
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                fillColor: Colors.black12,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                filled: true,
                suffixIcon: TextButton(
                    onPressed: () {
                      setState(() {
                        obscurity = !obscurity;
                      });
                    },
                    child: Text(obscurity ? 'نمایش' : 'پنهان',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey))),
                label: const Text('تایید پسورد'),
                errorText: notALike,
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
                onPressed: () async {
                  if (myController2.text == myController3.text) {
                    setState(() {
                      notALike = null;
                    });
                    await getAuthSignUp(
                        myController1.text,
                        myController2.text,
                        myController4.text,
                        myController5.text,
                        myController6.text,
                        context);
                  } else {
                    setState(() {
                      notALike = 'پسورد های وارد شده یکی نیستند';
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(MediaQuery.of(context).size.width, 50),
                    backgroundColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: Text("تایید",
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)))
          ])
        ],
      ),
    );
  }
}

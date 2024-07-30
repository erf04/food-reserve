import 'package:application/repository/HttpClient.dart';
import 'package:application/widgets/SoftenPageTransition.dart';
import 'package:application/widgets/loginSignUp_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController controller1 = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  bool correctPass = false;
  bool showCode = false;
  String myEmail = '';
  bool success = false;

  Future<void> resetPassword(String email) async {
    final response = await HttpClient.instance.post('api/password/reset/',
        options: Options(headers: {'App-Token': dotenv.env['API_KEY']}),
        data: {
          'email': email,
        }).then((onValue) {
      setState(() {
        this.showCode = true;
        myEmail = email;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code sent to email')),
        );
      });
    }).catchError((onError) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incorrect email address')),
        );
      });
    });
  }

  Future<void> sendCode(String code) async {
    final response = await HttpClient.instance.post('api/check-code/',
        data: {'code': code, 'email': myEmail}).then((onValue) {
      setState(() {
        correctPass = true;
        showCode = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Write down your new password!')),
        );
      });
    }).catchError((onError) {
      setState(() {
        showCode = false;
        correctPass = false;
        myEmail = '';
        codeController.text = '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wrong information please try again')),
        );
      });
    });
  }

  Future<void> sendPass(String password) async {
    final response = await HttpClient.instance.post(
        'api/password/reset/confirm/',
        data: {'email': myEmail, 'new_password': password}).then((onValue) {
      setState(() {
        success = true;
      });
    }).catchError((onError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password is too weak.Try again')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: <Widget>[
            Localizations.override(
              context: context,
              locale: const Locale('en'),
              child: Builder(
                builder: (context) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                        onPressed: () {
                          FadePageRoute.navigateToNextPage(
                              context, LoginSignUp());
                        },
                        icon: Icon(
                          CupertinoIcons.back,
                          size: 40,
                          color: Color.fromARGB(255, 2, 16, 43),
                        )),
                    Text('Forgot Password'),
                    SizedBox()
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      body: SafeArea(
        child: success
            ? AlertDialog(
                title: const Text('Successfuly reseted'),
                content: Text(
                  "Click ok to resume!",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        success = false;
                        FadePageRoute.navigateToNextPage(
                            context, LoginSignUp());
                      });
                    },
                    child: Text('OK'),
                  ),
                ],
              )
            : Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: <Widget>[
                    Localizations.override(
                      context: context,
                      locale: const Locale('en'),
                      child: Builder(
                        builder: (context) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              showCode
                                  ? 'Enter the emailed code'
                                  : correctPass
                                      ? 'Enter your new password'
                                      : 'Enter your email to reset password',
                              style: TextStyle(fontSize: 18.sp),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20.h),
                            showCode
                                ? SizedBox()
                                : TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Email',
                                    ),
                                  ),
                            showCode
                                ? TextField(
                                    controller: codeController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      label: Text('Enter the code'),
                                      border: OutlineInputBorder(),
                                    ),
                                  )
                                : correctPass
                                    ? Column(
                                        children: [
                                          TextField(
                                            controller: controller1,
                                            decoration: InputDecoration(
                                              label: Text(
                                                'Enter your new password',
                                              ),
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          TextField(
                                            controller: controller2,
                                            decoration: InputDecoration(
                                              label:
                                                  Text('Confirm your password'),
                                              border: OutlineInputBorder(),
                                            ),
                                          )
                                        ],
                                      )
                                    : Row(),
                            SizedBox(height: 20.h),
                            ElevatedButton(
                              onPressed: () {
                                if (showCode) {
                                  setState(() {
                                    sendCode(codeController.text);
                                  });
                                } else if (correctPass) {
                                  if (controller1.text == controller2.text) {
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Password and Confirm Password are not the same')),
                                    );
                                  }
                                } else {
                                  setState(() {
                                    resetPassword(_emailController.text);
                                    _emailController.text = '';
                                  });
                                }
                              },
                              child: Text(
                                showCode
                                    ? 'Send Code'
                                    : correctPass
                                        ? 'Reset Password'
                                        : 'Send Email',
                                style: TextStyle(fontSize: 18.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

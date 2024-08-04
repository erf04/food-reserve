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
  bool loginError = false;
  bool signUpError = false;
  bool isInError = false;
  bool isInSignUp = false;
  bool obscurity = true;
  TextEditingController myController1 = TextEditingController();
  TextEditingController myController2 = TextEditingController();
  TextEditingController myController3 = TextEditingController();
  TextEditingController myController4 = TextEditingController();
  TextEditingController myController5 = TextEditingController();
  TextEditingController myController6 = TextEditingController();
  static Future<void> getAuthLogin(
      String myUser, String myPass, context) async {
    try {
      final response = await HttpClient.instance.post('api/login/',
          data: {'username': myUser, 'password': myPass}).then((response) {
        TokenManager.saveTokens(
            response.data["access"], response.data["refresh"]);
        FadePageRoute.navigateToNextPage(context, MainPage());
        print(response.data);
      });
    } on DioException catch (e) {
      if (e.response != null) {
        print(e.response?.data);
        print('Error status code: ${e.response?.statusCode}');
        print('Error data: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }
    }
  }

  static Future<void> getAuthSignUp(
      String myUser,
      String myPass,
      String firstName,
      String lastName,
      String email,
      BuildContext context) async {
    try {
      firstName = firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
      lastName = lastName[0].toUpperCase() + lastName.substring(1).toLowerCase();

      final response;
      response = await HttpClient.instance.post('api/register/',
          options: Options(headers: {'App-Token': dotenv.env['API_KEY']}),
          data: {
            'username': myUser,
            'password': myPass,
            'first_name': firstName,
            'last_name': lastName,
            'email': email
          }).then((onValue) {
        _LoginSignUpState.getAuthLogin(myUser, myPass, context);
        print(onValue);
      });
    } on DioException catch (e) {
      if (e.response != null) {
        print('Error status code: ${e.response?.statusCode}');
        print('Error data: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }
    }
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
              fit: BoxFit
                  .cover, // This ensures the image covers the entire background
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
                setState(() {
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    loginError = true;
                  });
                });
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

  Column getSignUp(BuildContext context) {
    bool notEqualError = false;

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
            decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
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
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey))),
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
                label: const Text('تایید پسورد')),
          ),
          const SizedBox(
            height: 30,
          ),
          ElevatedButton(
              onPressed: () {
                if (myController2.text == myController3.text) {
                  _LoginSignUpState.getAuthSignUp(
                      myController1.text,
                      myController2.text,
                      myController4.text,
                      myController5.text,
                      myController6.text,
                      context);
                } else {
                  setState(() {
                    signUpError = true;
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
    );
  }
}

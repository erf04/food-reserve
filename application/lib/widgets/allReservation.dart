// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:application/design/meal.dart';
import 'package:application/design/shiftmeal.dart';
import 'package:application/design/user.dart';
import 'package:application/repository/HttpClient.dart';
import 'package:application/repository/tokenManager.dart';
import 'package:application/widgets/MainPage.dart';
import 'package:application/widgets/SoftenPageTransition.dart';
import 'package:application/widgets/profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:choice/choice.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class MealReservationsPage extends StatefulWidget {
  @override
  _MealReservationsPageState createState() => _MealReservationsPageState();
}

class _MealReservationsPageState extends State<MealReservationsPage> {
  Jalali? selectedDate;
  TextEditingController searchController = TextEditingController();
  List<Reservation> reservations = [];

  @override
  void initState() {
    super.initState();
    selectedDate = Jalali.now(); // Default value
  }

  Future<void> _selectDate(BuildContext context) async {
    Jalali? picked = await showPersianDatePicker(
      context: context,
      initialDate: selectedDate!,
      firstDate: Jalali(1300, 1, 1),
      lastDate: Jalali(1450, 12, 29),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        fetchReservations();
      });
    }
  }

  bool showMeal = false;
  Meal? meal;
  String emptyString = '';
  String dashString = ' - ';

  Future<List<UserMeal>> fetchReservations() async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      String myDate =
          selectedDate!.formatCompactDate().replaceAll('/', '-').trim();
      final response = await HttpClient.instance.post('api/reservations/all/',
          options: Options(headers: {'Authorization': "JWT $myAccess"}),
          data: {
            'user': searchController.text,
            'date': myDate,
            'shift': selectedValue
          });
      reservations = [];
      List<UserMeal> userMeals = [];
      List<int> ids = [];
      if (response.statusCode == 200) {
        for (var i in response.data) {
          UserMeal myUserMeal = UserMeal.fromJson(i);
          if (!ids.contains(myUserMeal.user.id)) {
            userMeals.add(myUserMeal);
            ids.add(myUserMeal.user.id);
          } else {
            int index = ids.indexOf(myUserMeal.user.id);
            if (userMeals[index].dinner == null && myUserMeal.dinner != null) {
              userMeals[index].dinner = myUserMeal.dinner;
            } else if (userMeals[index].lunch == null &&
                myUserMeal.lunch != null) {
              userMeals[index].lunch = myUserMeal.lunch;
            }
          }
        }
        return userMeals;
      }
    }
    return [];
  }

  List<String> choices = ['A', 'B', 'C', 'D'];
  String? selectedValue;

  void setSelectedValue(String? value) {
    setState(() {
      selectedValue = value;
      if (selectedDate != null && selectedValue != null) {
        fetchReservations();
      }
    });
  }

  Future<User?> getProfileForMainPage() async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();

      final response = await HttpClient.instance.get("api/profile/",
          options: Options(headers: {"Authorization": "JWT $myAccess"}));
      User myUser = User.fromJson(response.data);
      return myUser;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leadingWidth:110 ,
        leading: IconButton(
                onPressed: () {
                  FadePageRoute.navigateToNextPage(context, MainPage());
                },
                icon: const Icon(
                  CupertinoIcons.back,
                  size: 40,
                  color: Color.fromARGB(255, 2, 16, 43),
                )),
        title: Text(
          'رزرو های روز',
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        actions: [
          SizedBox(width: 10,),
          FutureBuilder<User?>(
                future: getProfileForMainPage(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return InkWell(
                      onTap: () {
                        FadePageRoute.navigateToNextPage(context, Profile());
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.deepOrange,
                        radius: 20,
                        child: ClipOval(
                          child: Container(
                            child: CachedNetworkImage(
                                imageUrl:
                                    'http://10.0.2.2:8000${snapshot.data?.profilePhoto}',
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    Center(child: Icon(Icons.error)),
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40),
                          ),
                        ),
                      ),
                    );
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    return IconButton(
                        onPressed: () {
                          FadePageRoute.navigateToNextPage(context, Profile());
                        },
                        icon: Icon(CupertinoIcons.profile_circled));
                  }
                }),
                SizedBox(width: 50,)
        ],
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                //color: Colors.white,
                image: DecorationImage(
                  image: AssetImage('assets/new1.jpg'),
                  fit: BoxFit
                      .cover, // This ensures the image covers the entire background
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(children: [
                    Center(
                      child: Choice<String>.inline(
                        clearable: true,
                        value: ChoiceSingle.value(selectedValue),
                        onChanged: ChoiceSingle.onChanged(setSelectedValue),
                        itemCount: choices.length,
                        itemBuilder: (state, i) {
                          return ChoiceChip(
                            selected: state.selected(choices[i]),
                            onSelected: state.onSelected(choices[i]),
                            label: Text(choices[i]),
                          );
                        },
                        listBuilder: ChoiceList.createScrollable(
                          spacing: 10,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 25,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration:
                                  InputDecoration(labelText: 'انتخاب تاریخ'),
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              controller: TextEditingController(
                                text: selectedDate != null
                                    ? selectedDate!.formatCompactDate()
                                    : '',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: TextField(
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9@._-\s]')),
                        ],
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'جستجو با اسم',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            fetchReservations();
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                  ]),
                  Expanded(
                    child:
                     showMeal ? 
                     AlertDialog(
                          title: Text(this.meal!.food.name),
                          content: Text(
                            "${meal!.diet != null ? meal!.diet!.name: emptyString}${meal!.desert!=null ? dashString + meal!.desert!.name : emptyString}${meal!.drink.isEmpty ? emptyString : '\n${meal!.drinkToString()}' }",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          actions: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      showMeal = false;
                                      meal = null;
                                    });
                                  },
                                  child: Text('ok'),
                                ),
                              ],
                            ),
                          ],
                        )
                     : FutureBuilder<List<UserMeal>>(
                        future: fetchReservations(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return SingleChildScrollView(
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text('نام و نام خانوادگی')),
                                  DataColumn(label: Text('ناهار')),
                                  DataColumn(label: Text('شام')),
                                ],
                                rows: snapshot.data!.map((reservation) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(reservation.user.firstName +
                                          ' ' +
                                          reservation.user.lastName)),
                                      DataCell(InkWell(
                                        onTap: () {
                                          if (reservation.lunch != null) {
                                            setState(() {
                                              showMeal = true;
                                              meal = reservation.lunch!.meal;
                                            });
                                          }
                                        },
                                        child: Text(reservation.lunch == null
                                            ? ''
                                            : reservation
                                                .lunch!.meal.food.name),
                                      )),
                                      DataCell(InkWell(
                                        onTap: () {
                                          if (reservation.dinner != null) {
                                            setState(() {
                                              showMeal = true;
                                              meal = reservation.dinner!.meal;
                                            });
                                          }
                                        },
                                        child: Text(reservation.dinner == null
                                            ? ''
                                            : reservation
                                                .dinner!.meal.food.name),
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                            );
                          } else if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(snapshot.error.toString()),
                            );
                          } else {
                            return Center(
                              child: Text('No data'),
                            );
                          }
                        }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserMeal {
  final User user;
  ShiftMeal? lunch;
  ShiftMeal? dinner;

  UserMeal({
    required this.user,
    required this.lunch,
    required this.dinner,
  });

  factory UserMeal.fromJson(Map<String, dynamic> json) {
    return UserMeal(
        user: User.fromJson(json['user']),
        lunch: json['lunch'] == null ? null : ShiftMeal.fromJson(json['lunch']),
        dinner:
            json['dinner'] == null ? null : ShiftMeal.fromJson(json['dinner']));
  }
}

class Reservation {
  final User user;
  final ShiftMeal shiftMeal;
  final String date;

  Reservation({
    required this.user,
    required this.shiftMeal,
    required this.date,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
        user: User.fromJson(json['user']),
        shiftMeal: ShiftMeal.fromJson(json['shift_meal']),
        date: json['date']);
  }
}

extension JalaliExtensions on Jalali {
  String toIso8601String() {
    final DateTime gregorian = this.toGregorian().toDateTime();
    return gregorian.toIso8601String();
  }

  String formatFullDate() {
    return '${this.year}/${this.month}/${this.day}';
  }
}

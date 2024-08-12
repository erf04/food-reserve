// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:application/design/food.dart';
import 'package:application/design/meal.dart';
import 'package:application/design/reserve.dart';
import 'package:application/design/shift.dart';
import 'package:application/design/shiftmeal.dart';
import 'package:application/design/user.dart';
import 'package:application/gen/assets.gen.dart';
import 'package:application/repository/HttpClient.dart';
import 'package:application/repository/tokenManager.dart';
import 'package:application/widgets/MainPage.dart';
import 'package:application/widgets/SoftenPageTransition.dart';
import 'package:application/widgets/profile.dart';
import 'package:application/widgets/reserveFood.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:choice/choice.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ReservePage extends StatefulWidget {
  @override
  _ReservePageState createState() => _ReservePageState();
}

class _ReservePageState extends State<ReservePage> {
  Jalali? selectedDate;
  String? myShiftName;
  bool selectedDateForMeal = false;
  bool selectedShiftForMeal = false;
  bool notAvailable = false;

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

  Future<List<ShiftMeal>> getMenu(String? shiftName) async {
    VerifyToken? verifyToken = await TokenManager.verifyAccess(context);
    if (verifyToken == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      final response = await HttpClient.instance.post('api/get-menu/',
          data: {
            "date": selectedDate!.toJalaliDateTime().substring(0, 10),
            'shift': shiftName
          },
          options: Options(headers: {'Authorization': 'JWT $myAccess'}));
      List<ShiftMeal> myShiftMeals = [];

      for (var i in response.data) {
        Food food1 = Food(
            id: i["meal"]["food"]["id"],
            name: i["meal"]["food"]["name"],
            type: i["meal"]["food"]["type"]);
        Food? diet;
        if (i["meal"]["diet"] == null) {
          diet = null;
        } else {
          diet = Food(
              id: i["meal"]["diet"]["id"],
              name: i["meal"]["diet"]["name"],
              type: i["meal"]["diet"]["type"]);
        }

        Food? dessert;
        if (i["meal"]["dessert"] == null) {
          dessert = null;
        } else {
          dessert = Food(
              id: i["meal"]["dessert"]["id"],
              name: i["meal"]["dessert"]["name"],
              type: i["meal"]["dessert"]["type"]);
        }
        List<Drink> myDrinks = [];
        for (var j in i["meal"]["drinks"]) {
          myDrinks.add(Drink(name: j["name"], id: j['id']));
        }
        Meal myMeal = Meal(
            drink: myDrinks,
            id: i["meal"]["id"],
            food: food1,
            diet: diet,
            desert: dessert,
            dailyMeal: i["meal"]["daily_meal"]);
        Shift myShift =
            Shift(id: i["shift"]["id"], shiftName: i["shift"]["shift_name"]);
        ShiftMeal temp = ShiftMeal(
            id: i["id"],
            date: i["date"],
            meal: myMeal,
            shift: myShift,
            isReserved: i["is_reserved"]);
        myShiftMeals.add(temp);
      }
      return myShiftMeals;
    }
    return [];
  }

  List<String> choices = ['A', 'B', 'C', 'D'];

  String? selectedValue;

  void setSelectedValue(String? value) {
    setState(() {
      selectedShiftForMeal = false;
    });
    setState(() {
      selectedValue = value;
      if (value == 'B') {
        myShiftName = value;
        selectedShiftForMeal = true;
      } else {
        notAvailable = true;
        selectedValue = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          leadingWidth: 110,
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                CupertinoIcons.back,
                size: 40,
                color: Color.fromARGB(255, 2, 16, 43),
              )),
          title: Text(
            'صفحه ی رزرو',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          actions: [
            SizedBox(
              width: 20,
            ),
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
                                    'https://reserve-backend.chbk.run${snapshot.data?.profilePhoto}',
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
                      child: SizedBox(),
                    );
                  } else {
                    return IconButton(
                        onPressed: () {
                          FadePageRoute.navigateToNextPage(context, Profile());
                        },
                        icon: Icon(CupertinoIcons.profile_circled));
                  }
                }),
            SizedBox(
              width: 50,
            )
          ],
          backgroundColor: Colors.white,
        ),
        body: SafeArea(
            child: Stack(fit: StackFit.expand, children: [
          Container(
            decoration: const BoxDecoration(
              //color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/new7.jpg'),
                fit: BoxFit
                    .cover, // This ensures the image covers the entire background
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  0, 0, 0, MediaQuery.of(context).size.height * 0.62),
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [BoxShadow(blurRadius: 2)],
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24))),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.35,
                child: Column(children: [
                  const SizedBox(
                    height: 15,
                  ),
                  Text(
                    "شیفت و تاریخ مورد نظر را انتخاب کنید",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontSize: 18),
                  ),
                  Choice<String>.inline(
                    clearable: false,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(),
                      ElevatedButton(
                          onPressed: _pickDate,
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(
                                  MediaQuery.of(context).size.width * 0.4, 45),
                              backgroundColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16))),
                          child: Text("انتخاب تاریخ",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white))),
                      Text(
                        selectedDate == null
                            ? "YYYY-MM-DD"
                            : selectedDate!.toJalaliDateTime().substring(0, 10),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox()
                    ],
                  )
                ]),
              ),
            ),
          ),
          selectedDateForMeal && selectedShiftForMeal
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, MediaQuery.of(context).size.height * 0.28, 0, 0),
                  child: foodListBuilder(),
                )
              : notAvailable == true
                  ? Center(
                      child: AlertDialog(
                      title: const Text('امکان پذیر نیست'),
                      content: Text(
                        "این شیفت در حال حاضر در دسترس نمی باشد",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            setState(() {
                              notAvailable = false;
                            });
                          },
                          child: Text('OK'),
                        ),
                      ],
                    ))
                  : Center(
                      child: AlertDialog(
                        title: Text(
                          'تاریخ و شیفت خود را انتخاب کنید',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontSize: 20),
                        ),
                      ),
                    )
        ])));
  }

  FutureBuilder<List<ShiftMeal>> foodListBuilder() {
    return FutureBuilder<List<ShiftMeal>>(
        future: getMenu(myShiftName),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: SizedBox(height: 10, child: Text("Something went wrong!")),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: const CircularProgressIndicator());
          } else if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "غذایی موجود نیست !",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: Colors.black54),
                ),
              );
            }
            return ReserveList(
              myMeal: snapshot.data!,
              myPage: this,
            );
          } else {
            return const Center(
              child: SizedBox(height: 10, child: Text("خطایی رخ داده است !")),
            );
          }
        });
  }

  Future<void> _pickDate() async {
    Jalali? pickedDate = await showPersianDatePicker(
      context: context,
      initialDate: selectedDate ?? Jalali.now(),
      firstDate: Jalali(1385, 8),
      lastDate: Jalali(1450, 9),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDateForMeal = false;
      });
      setState(() {
        selectedDate = pickedDate;
        selectedDateForMeal = true;
      });
    }
  }
}

class ReserveList extends StatefulWidget {
  ReserveList({
    Key? key,
    required this.myMeal,
    required this.myPage,
  }) : super(key: key);
  final List<ShiftMeal> myMeal;
  final _ReservePageState myPage;
  @override
  State<ReserveList> createState() => _ReserveListState(myList: myMeal, myPage);
}

class _ReserveListState extends State<ReserveList> {
  int selectedIndex = -1;
  final List<ShiftMeal> myList;
  final _ReservePageState myPage;
  _ReserveListState(this.myPage, {required this.myList});
  bool success = false;
  bool error = false;
  Future<void> reserveFood(int shiftMealId) async {
    VerifyToken? verifyToken = await TokenManager.verifyAccess(context);
    if (verifyToken == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      final response = await HttpClient.instance
          .post('api/reserve/',
              data: {"shift-meal-id": shiftMealId},
              options: Options(headers: {'Authorization': 'JWT $myAccess'}))
          .then((value) {
        setState(() {
          success = true;
        });
      }).catchError((onError) {
        setState(() {
          error = true;
        });
      });
    }
    // User myUser = User(
    //     id: response.data["user"]["id"],
    //     userName: response.data["user"]["username"],
    //     profilePhoto: response.data["user"]["profile"],
    //     isSuperVisor: response.data["user"]["is_supervisor"],
    //     isShiftManager: response.data["user"]["is_shift_manager"]);
    // Reserve myReserve =
    //     Reserve(id: response.data["id"], user: user, shiftMeal: shiftMeal);
  }

  @override
  Widget build(BuildContext context) {
    return error
        ? Padding(
            padding: EdgeInsets.fromLTRB(
                0, 0, 0, MediaQuery.of(context).size.height / 4),
            child: AlertDialog(
              title: const Text('امکان پذیر نیست'),
              content: Text(
                "شما نمی توانید این و وعده را رزرو کنید !",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    setState(() {
                      error = false;
                    });
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          )
        : success
            ? Padding(
                padding: EdgeInsets.fromLTRB(
                    0, 0, 0, MediaQuery.of(context).size.height / 4),
                child: AlertDialog(
                  title: const Text('موفقیت آمیز بود'),
                  content: Text(
                    "برای ادامه کلیک کنید ! ",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          success = false;
                          selectedIndex = -1;
                        });
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: myList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: selectedIndex == index
                            ? MediaQuery.of(context).size.height * (2 / 5)
                            : 75,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color.fromARGB(255, 242, 200, 145),
                            boxShadow: const [BoxShadow(blurRadius: 4)]),
                        child: Padding(
                          padding: selectedIndex == index
                              ? const EdgeInsets.all(32)
                              : const EdgeInsets.all(16.0),
                          child: selectedIndex == index
                              ? _columnMethod(
                                  myList!,
                                  index,
                                  context,
                                )
                              : _rowMethod(
                                  myList!,
                                  index,
                                  context,
                                ),
                        ),
                      ),
                    ),
                  );
                });
  }

  Column _columnMethod(
      List<ShiftMeal> shiftMeal, int index, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                  onPressed: () {
                    setState(() {
                      if (selectedIndex != index) {
                        selectedIndex = index;
                      } else {
                        selectedIndex = -1;
                      }
                    });
                  },
                  child: Text(
                    'شیفت : ${shiftMeal[index].shift.shiftName}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                  )),
              Text('غذا : ${shiftMeal[index].meal.food.name}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300)),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 9,
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        MediaQuery.of(context).size.width * 1 / 8, 0, 0, 0),
                    width: MediaQuery.of(context).size.width * 5 / 8,
                    height: 30,
                    child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: shiftMeal[index].meal.drink.length + 1,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index1) {
                          if (index1 == 0) {
                            String emptyString = 'نوشیدنی ها : ';
                            String myString = 'نوشیدنی موجود نمی باشد !';

                            return Container(
                                margin: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                                child: Text(
                                    shiftMeal[index].meal.drink.length == 0
                                        ? myString
                                        : emptyString,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w300)));
                          }
                          if (index1 == shiftMeal[index].meal.drink.length) {
                            return Container(
                                margin: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                                child: Text(
                                    shiftMeal[index]
                                        .meal
                                        .drink[index1 - 1]
                                        .name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w300)));
                          } else {
                            return Container(
                                margin: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                                child: Text(
                                    '${shiftMeal[index].meal.drink[index1 - 1].name} -',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w300)));
                          }
                        }),
                  ),
                ],
              ),

              // Text('drinks: ${shiftMeal[index].meal.food.name}',
              //   style: Theme.of(context)
              //       .textTheme
              //       .titleLarge!
              //       .copyWith(fontSize: 19, fontWeight: FontWeight.w300)),
              const SizedBox(
                height: 8,
              ),
              Text(
                  shiftMeal[index].meal.diet == null
                      ? 'رژیمی : غذای رژیمی موجود نیست'
                      : 'رژیمی : ${shiftMeal[index].meal.diet!.name}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300)),
              const SizedBox(
                height: 8,
              ),
              Text(
                  shiftMeal[index].meal.desert == null
                      ? 'دسر : دسر موجود نیست'
                      : 'دسر : ${shiftMeal[index].meal.desert!.name}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300)),
              const SizedBox(
                height: 8,
              ),
              ElevatedButton(
                  onPressed: () async {
                    if (!shiftMeal[index].isReserved) {
                      setState(() {
                        reserveFood(shiftMeal[index].id);
                        for (var i in shiftMeal) {
                          if (i.isReserved &&
                              i.meal.dailyMeal ==
                                  shiftMeal[index].meal.dailyMeal) {
                            i.isReserved = false;
                          }
                        }
                        shiftMeal[index].isReserved = true;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width, 50),
                      backgroundColor: shiftMeal[index].isReserved
                          ? Colors.white24
                          : Colors.black26,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: Text("رزرو کنید !",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)))
            ],
          ),
        )
      ],
    );
  }

  Row _rowMethod(List<ShiftMeal> shiftMeals, int index, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(shiftMeals[index].meal.food.name,
            style:
                Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 19)),
        Text(
          shiftMeals[index].meal.dailyMeal,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 19),
        ),
      ],
    );
  }
}

import 'dart:convert';

import 'package:application/design/food.dart';
import 'package:application/design/meal.dart';
import 'package:application/design/reserve.dart';
import 'package:application/design/shift.dart';
import 'package:application/design/shiftmeal.dart';
import 'package:application/design/user.dart';
import 'package:application/repository/HttpClient.dart';
import 'package:application/repository/tokenManager.dart';
import 'package:application/widgets/Manager.dart';
import 'package:application/widgets/SoftenPageTransition.dart';
import 'package:application/widgets/allReservation.dart';
import 'package:application/widgets/createMeal.dart';
import 'package:application/widgets/loginSignUp_state.dart';
import 'package:application/widgets/profile.dart';
import 'package:application/widgets/reservation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = -1;
  Future<void> deleteReservation(int deletedId) async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      final response = await HttpClient.instance.delete(
          "api/delete-reservation/$deletedId/",
          options: Options(headers: {"Authorization": "JWT $myAccess"}));
    }
  }

  Future<List<Reserve>> getPendingReservations() async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      final response = await HttpClient.instance.get("api/pending-list/",
          options: Options(headers: {"Authorization": "JWT $myAccess"}));

      List<Reserve> myList = [];
      for (var j in response.data) {
        var i = j["shift_meal"];
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
            id: i["meal"]["id"],
            drink: myDrinks,
            food: food1,
            diet: diet,
            desert: dessert,
            dailyMeal: i["meal"]["daily_meal"]);

        Shift myShift =
            Shift(id: i["shift"]["id"], shiftName: i["shift"]["shift_name"]);
        ShiftMeal temp1 = ShiftMeal(
            id: i["id"],
            date: i["date"],
            meal: myMeal,
            shift: myShift,
            isReserved: true);
        Reserve temp = Reserve(
            id: j['id'],
            user: User.fromJson(j['user']),
            shiftMeal: temp1,
            date: j['date']);

        myList.add(temp);
      }
      return myList;
    }
    return [];
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

  bool onErrorCreate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          foregroundColor: Colors.white,
          leadingWidth: 120,
          leading: IconButton(
                  onPressed: () {
                    FadePageRoute.navigateToNextPage(
                        context, const LoginSignUp());
                  },
                  icon: const Icon(
                    CupertinoIcons.back,
                    size: 40,
                    color: Color.fromARGB(255, 2, 16, 43),
                  )),
          title: Text(
            'صفحه اصلی',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          actions: [
            SizedBox(width: 30,),
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
                            FadePageRoute.navigateToNextPage(
                                context, Profile());
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
                    image: AssetImage('assets/new5.jpg'),
                    fit: BoxFit
                        .cover, // This ensures the image covers the entire background
                  ),
                ),
                child: FutureBuilder<User?>(
                  future: getProfileForMainPage(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: AlertDialog(
                          title: const Text('مشکل اینترنت'),
                          content: Text(
                            "به نظر می رسد مشکلی رخ داده است. دوباره تلاش کنید!",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          actions: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      getProfileForMainPage();
                                    });
                                  },
                                  child: Text('تلاش دوباره!'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      Navigator.of(context)
                                          .pushReplacement(CupertinoPageRoute(
                                        builder: (context) =>
                                            const LoginSignUp(),
                                      ));
                                    });
                                  },
                                  child: Text('بازگشت'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasData) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  onTap: () {
                                    FadePageRoute.navigateToNextPage(
                                        context, ReservePage());
                                  },
                                  child: Container(
                                    height: 65,
                                    width:
                                        MediaQuery.of(context).size.width - 60,
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        color: Colors.white70),
                                    child: Center(
                                      child: Text(
                                        'رزرو غذا',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (snapshot.data!.isSuperVisor) {
                                      FadePageRoute.navigateToNextPage(
                                          context, MealCreationPage());
                                    } else {
                                      setState(() {
                                        onErrorCreate = true;
                                      });
                                    }
                                  },
                                  child: Container(
                                    height: 65,
                                    width: MediaQuery.of(context).size.width *
                                            1 /
                                            2 -
                                        30,
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        color: Colors.white70),
                                    child: Center(
                                      child: Text(
                                        'ایجاد غذا',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(),
                                InkWell(
                                  onTap: () {
                                    if (snapshot.data!.isSuperVisor) {
                                      FadePageRoute.navigateToNextPage(
                                          context, MealReservationsPage());
                                    } else {
                                      setState(() {
                                        onErrorCreate = true;
                                      });
                                    }
                                  },
                                  child: Container(
                                    height: 65,
                                    width: MediaQuery.of(context).size.width *
                                            1 /
                                            2 -
                                        30,
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        color: Colors.white70),
                                    child: Center(
                                      child: Text(
                                        'رزرو های روز',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (snapshot.data!.isShiftManager) {
                                      FadePageRoute.navigateToNextPage(context,
                                          const SupervisorAssignmentPage());
                                    } else {
                                      setState(() {
                                        onErrorCreate = true;
                                      });
                                    }
                                  },
                                  child: Container(
                                    height: 65,
                                    width:
                                        MediaQuery.of(context).size.width - 60,
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        color: Colors.white70),
                                    child: Center(
                                      child: Text(
                                        'صفحه سرپرست',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 2, color: Colors.white),
                          const SizedBox(
                            height: 20,
                          ),
                          onErrorCreate
                              ? Center(
                                  child: AlertDialog(
                                    title: const Text('خطا'),
                                    content: Text(
                                      "شما اجازه ی ورود به این صفحه را ندارید!",
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    actions: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                onErrorCreate = false;
                                              });
                                            },
                                            child: const Text('تلاش دوباره!'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : FutureBuilder<List<Reserve>>(
                                  future: getPendingReservations(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Center(
                                        child: AlertDialog(
                                          title: const Text('مشکل اینترنت'),
                                          content: Text(
                                            "به نظر می رسد مشکلی رخ داده است. دوباره تلاش کنید!",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                          actions: <Widget>[
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      getPendingReservations();
                                                    });
                                                  },
                                                  child: const Text(
                                                      'تلاش دوباره!'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    } else if (snapshot.hasData) {
                                      return Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                (2 / 5),
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: ListView.builder(
                                            itemCount: snapshot.data!.length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedIndex = index;
                                                    });
                                                  },
                                                  child: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    height: selectedIndex ==
                                                            index
                                                        ? MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            (1 / 3)
                                                        : 75,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 242, 200, 145),
                                                        boxShadow: const [
                                                          BoxShadow(
                                                              blurRadius: 4)
                                                        ]),
                                                    child: Padding(
                                                      padding:
                                                          selectedIndex == index
                                                              ? const EdgeInsets
                                                                  .all(32)
                                                              : const EdgeInsets
                                                                  .all(16.0),
                                                      child: selectedIndex ==
                                                              index
                                                          ? _columnMethod(
                                                              snapshot.data!,
                                                              index,
                                                              context,
                                                            )
                                                          : _rowMethod(
                                                              snapshot.data!,
                                                              index,
                                                              context,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                      );
                                    } else {
                                      return Center(
                                        child: Text(
                                          " NO DATA",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(color: Colors.white),
                                        ),
                                      );
                                    }
                                  },
                                )
                        ],
                      );
                    } else {
                      return Center(
                          child: Text("NO DATA",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(color: Colors.white)));
                    }
                  },
                ),
              ),
            ],
          ),
        ));
  }

  Row _rowMethod(List<Reserve> reserves, int index, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('شیفت : ${reserves[index].shiftMeal.shift.shiftName} ',
            style:
                Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 19)),
        Text(
          reserves[index].shiftMeal.meal.dailyMeal,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 19),
        ),
        Text(
          reserves[index].shiftMeal.date.substring(5, 10),
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 19),
        ),
        IconButton(
            hoverColor: Colors.red,
            onPressed: () {
              setState(() {
                deleteReservation(reserves[index].id);
              });
            },
            icon: const Icon(
              CupertinoIcons.delete,
            ))
      ],
    );
  }

  Column _columnMethod(
      List<Reserve> reserves, int index, BuildContext context) {
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
                    'شیفت : ${reserves[index].shiftMeal.shift.shiftName} ',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                  )),
              Text(
                  'غذا : ${reserves[index].shiftMeal.meal.food.name} ',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontSize: 19, fontWeight: FontWeight.w300)),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width /9,),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        MediaQuery.of(context).size.width * 1 / 8, 0, 0, 0),
                    width: MediaQuery.of(context).size.width * 5/8,
                    height: 30,
                    child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: reserves[index].shiftMeal.meal.drink.length + 1,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index1) {
                          if (index1 == 0) {
                            String emptyString = 'نوشیدنی ها : ';
                            String myString = 'نوشیدنی موجود نمی باشد !';
                            
                            return Container(
                                margin: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                                child: Text(reserves[index].shiftMeal.meal.drink.isEmpty ? myString : emptyString,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w300)));
                          }
                          if (index1 == reserves[index].shiftMeal.meal.drink.length) {
                            return Container(
                                margin: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                                child: Text(
                                    reserves[index].shiftMeal
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
                                    '${reserves[index].shiftMeal.meal.drink[index1 - 1].name} -',
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
              Text(
                  reserves[index].shiftMeal.meal.diet == null
                      ? 'رژیمی : غذای رژیمی موجود نیست'
                      : 'رژیمی : ${reserves[index].shiftMeal.meal.diet!.name} ',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300)),

              Text(
                  reserves[index].shiftMeal.meal.desert == null
                      ? 'دسر : دسر موجود نیست'
                      : 'دسر : ${reserves[index].shiftMeal.meal.desert!.name}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300)),
              const SizedBox(
                height: 8,
              ),
              Text(reserves[index].date,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300)),
            ],
          ),
        )
      ],
    );
  }
}

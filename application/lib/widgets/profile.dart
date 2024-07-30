import 'package:application/design/food.dart';
import 'package:application/design/meal.dart';
import 'package:application/design/reserve.dart';
import 'package:application/design/shift.dart';
import 'package:application/design/shiftmeal.dart';
import 'package:application/design/user.dart';
import 'package:application/gen/assets.gen.dart';
import 'package:application/main.dart';
import 'package:application/repository/HttpClient.dart';
import 'package:application/repository/tokenManager.dart';
import 'package:application/widgets/MainPage.dart';
import 'package:application/widgets/SoftenPageTransition.dart';
import 'package:application/widgets/loginSignUp_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isInHistory = false;

  static Future<List<ShiftMeal>> getReserveHistory(BuildContext context) async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();

      final response = await HttpClient.instance.get("api/get-reservations/",
          options: Options(headers: {"Authorization": "JWT $myAccess"}));

      List<ShiftMeal> myList = [];
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
            id: i["meal"]["id"],
            drink: myDrinks,
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
            isReserved: true);

        myList.add(temp);
      }
      return myList;
    }
    return [];
  }

  Future<User?> getProfile() async {
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
        appBar: isInHistory
            ? myAppBar(context, 'تاریخچه', true)
            : myAppBar(context, 'کاربر', false),
        body: isInHistory ? const ReserveHistory() : getNormalProfileWidget());
  }

  FutureBuilder<User?> getNormalProfileWidget() {
    return FutureBuilder<User?>(
        future: getProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: SizedBox(height: 10, child: Text("Something went wrong!")),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: const CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return SafeArea(
                child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    //color: Colors.white,
                    image: DecorationImage(
                      image: AssetImage('assets/new4.jpg'),
                      fit: BoxFit
                          .cover, // This ensures the image covers the entire background
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        0, 0, 0, MediaQuery.of(context).size.height * 0.7),
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.deepOrange,
                          radius: 80,
                          child: ClipOval(
                            child: Container(
                              child: CachedNetworkImage(
                                  imageUrl:
                                      'http://10.0.2.2:8000${snapshot.data?.profilePhoto}',
                                  placeholder: (context, url) => const Center(
                                      child: Center(
                                          child: CircularProgressIndicator())),
                                  errorWidget: (context, url, error) =>
                                      Center(child: Icon(Icons.error)),
                                  fit: BoxFit.cover,
                                  width: 160,
                                  height: 160),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () {},
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(40)),
                              child: Image.asset(
                                'assets/cameraIcon.jpg',
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextButton(
                          onPressed: () {},
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: Color.fromARGB(205, 255, 255, 255),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(24))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(snapshot.data!.userName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontWeight: FontWeight.bold)),
                                IconButton(
                                    onPressed: () {
                                      //todo change user name
                                    },
                                    icon: const Icon(CupertinoIcons.pen))
                              ],
                            ),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: TextButton(
                          onPressed: () {},
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: Color.fromARGB(205, 255, 255, 255),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(24))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  'Change Password',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                    onPressed: () {
                                      //todo change user name
                                    },
                                    icon: const Icon(CupertinoIcons.pen)),
                              ],
                            ),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: TextButton(
                          onPressed: () {},
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: Color.fromARGB(205, 255, 255, 255),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(24))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(
                                  width: 12,
                                ),
                                Text('Change Profile Image',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontWeight: FontWeight.bold)),
                                IconButton(
                                    onPressed: () {
                                      //todo change user name
                                    },
                                    icon: const Icon(CupertinoIcons.pen))
                              ],
                            ),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: TextButton(
                          onPressed: () {},
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: Color.fromARGB(205, 255, 255, 255),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(24))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  'See food records',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isInHistory = true;
                                      });
                                    },
                                    icon: const Icon(CupertinoIcons.bookmark)),
                              ],
                            ),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: TextButton(
                          onPressed: () {},
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: Color.fromARGB(205, 255, 255, 255),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(24))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(
                                  width: 12,
                                ),
                                Text('Currently In Charge',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontWeight: FontWeight.bold)),
                                Icon(
                                  snapshot.data!.isSuperVisor
                                      ? CupertinoIcons.check_mark
                                      : CupertinoIcons.xmark,
                                ),
                                const SizedBox(
                                  width: 4,
                                )
                              ],
                            ),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: TextButton(
                          onPressed: () {},
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: Color.fromARGB(205, 255, 255, 255),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(24))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(
                                  width: 12,
                                ),
                                Text('Currently Is Manager',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontWeight: FontWeight.bold)),
                                Icon(
                                  snapshot.data!.isShiftManager
                                      ? CupertinoIcons.check_mark
                                      : CupertinoIcons.xmark,
                                ),
                                const SizedBox(
                                  width: 4,
                                )
                              ],
                            ),
                          )),
                    )
                  ],
                )
              ],
            ));
          } else {
            return const Center(
              child: SizedBox(height: 10, child: Text("Something went wrong!")),
            );
          }
        });
  }

  AppBar myAppBar(BuildContext context, String title, bool inHistory) {
    return AppBar(
      foregroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
              onPressed: () {
                if (inHistory == true) {
                  setState(() {
                    this.isInHistory = false;
                  });
                } else {
                  FadePageRoute.navigateToNextPage(context, MainPage());
                }
                //Navigator.pushReplacement(context, MyHomePage(title: ''));
              },
              icon: const Icon(
                CupertinoIcons.back,
                size: 40,
                color: Color.fromARGB(255, 2, 16, 43),
              )),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          FutureBuilder<User?>(
              future: getProfile(),
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
                                  child: Center(
                                      child: CircularProgressIndicator())),
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
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  return IconButton(
                      onPressed: () {
                        FadePageRoute.navigateToNextPage(context, Profile());
                      },
                      icon: Icon(CupertinoIcons.profile_circled));
                }
              }),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}

class ReserveHistory extends StatefulWidget {
  const ReserveHistory({super.key});

  @override
  State<ReserveHistory> createState() => _ReserveHistoryState();
}

class _ReserveHistoryState extends State<ReserveHistory> {
  int selectedIndex = -1;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Stack(
      fit: StackFit.expand,
      children: [
        Container(
            decoration: const BoxDecoration(
              //color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/new4.jpg'),
                fit: BoxFit
                    .cover, // This ensures the image covers the entire background
              ),
            ),
            child: Column(children: [
              FutureBuilder<List<ShiftMeal>>(
                  future: _ProfileState.getReserveHistory(context),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: SizedBox(
                            height: 30,
                            child: Column(
                              children: [
                                Text(snapshot.error.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(color: Colors.white)),
                                Text(
                                  "Something went wrong!",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(color: Colors.white),
                                ),
                              ],
                            )),
                      );
                    } else if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: const CircularProgressIndicator());
                    } else if (snapshot.hasData) {

                      if (snapshot.data!.isEmpty) {
                        return Container(
                          color: Colors.white60,
                          child: const Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                              child: Text("No history available!"),
                            ),
                          ),
                        );
                      } else {
                        return Expanded(
                          child: ListView.builder(
                              itemCount: snapshot.data!.length,
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
                                          ? MediaQuery.of(context).size.height *
                                              (1 / 3)
                                          : 75,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          color: const Color.fromARGB(
                                              255, 242, 200, 145),
                                          boxShadow: const [
                                            BoxShadow(blurRadius: 4)
                                          ]),
                                      child: Padding(
                                        padding: selectedIndex == index
                                            ? const EdgeInsets.all(32)
                                            : const EdgeInsets.all(16.0),
                                        child: selectedIndex == index
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
                      }
                    } else {
                      return Center(
                          child: Text("NO DATA!",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(color: Colors.white)));
                    }
                  }),
            ]))
      ],
    ));
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
                    'Shift : ${shiftMeal[index].shift.shiftName}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                  )),
              TextButton(
                  onPressed: () {},
                  child: Text('foods: ${shiftMeal[index].meal.food.name}',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontSize: 19, fontWeight: FontWeight.w300))),
              const SizedBox(
                height: 6,
              ),
              Text(
                  shiftMeal[index].meal.diet == null
                      ? 'diet: no diet food available'
                      : 'diet: ${shiftMeal[index].meal.diet!.name}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300)),
              const SizedBox(
                height: 8,
              ),
              Text(
                  shiftMeal[index].meal.desert == null
                      ? 'dessert: no dessert food available'
                      : 'dessert: ${shiftMeal[index].meal.desert!.name}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300)),
              const SizedBox(
                height: 8,
              ),
              Text(shiftMeal[index].date,
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

  Row _rowMethod(List<ShiftMeal> shiftMeals, int index, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(shiftMeals[index].shift.shiftName,
            style:
                Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 19)),
        Text(
          shiftMeals[index].date,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 19),
        ),
      ],
    );
  }
}

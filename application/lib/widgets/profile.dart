import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
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
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Future<void> changeInfo(String firstName, String lastName, String email,
      String userName, File? profileImage) async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      FormData formData;
      if (profileImage != null) {
        String fileName = profileImage!.path.split('/').last;
        formData = FormData.fromMap({
          "profile": await MultipartFile.fromFile(profileImage.path,
              filename: fileName),
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          "username": userName
        });
        
      } else {
        formData = FormData.fromMap({
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          "username": userName
        });
      }
      String? myAccess = await TokenManager.getAccessToken();
      final response = await HttpClient.instance
          .put("api/user/update/",
              options: Options(headers: {"Authorization": "JWT $myAccess"}),
              data: formData)
          .then((onValue) {
        //print("Success");
        if(profileImage == null){
          Navigator.pop(context);
        }
      }).catchError((onError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('اطلاعات وارد شده قابل قبول نیست !')),
        );
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status == PermissionStatus.granted) {
      print('Permission granted');
    } else if (status == PermissionStatus.denied) {
      print('Permission denied');
    } else if (status == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
  }

  void _showChangeUsernameDialog(User myUser) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('نام کاربری جدید'),
          content: TextField(
            controller: controller1,
            decoration: InputDecoration(labelText: 'نام کاربری'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('بازگشت'),
            ),
            TextButton(
              onPressed: () {
                changeInfo(myUser.firstName, myUser.lastName, myUser.email,
                    controller1.text, null);
              },
              child: Text('تایید'),
            ),
          ],
        );
      },
    );
  }

  void _showChangeEmailDialog(User myUser) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ایمیل جدید'),
          content: TextField(
            controller: controller2,
            decoration: InputDecoration(labelText: 'ایمیل جدید'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('بازگشت'),
            ),
            TextButton(
              onPressed: () {
                changeInfo(myUser.firstName, myUser.lastName, controller2.text,
                    myUser.userName, null);
              },
              child: Text('تایید'),
            ),
          ],
        );
      },
    );
  }

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
  bool _isUpdatingImage = false;
  final ImagePicker _picker = ImagePicker();
  bool isInChangePassword = false;
  bool isInChangeUsername = false;
  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();

  Future<void> _pickImage(ImageSource source, User myUser) async {
    await _requestPermission(Permission.camera);
    await _requestPermission(Permission.photos);
    
    XFile? imagePickerThis = await _picker.pickImage(source: source);
    File image = File(imagePickerThis!.path);

    setState(() {
      _isUpdatingImage = true;
    });

    await changeInfo(myUser.firstName, myUser.lastName, myUser.email, myUser.userName,
        image);

    setState(() {
      _isUpdatingImage = false;
    });
  }

  Widget getNormalProfileWidget() {
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
          FutureBuilder<User?>(
              future: getProfile(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: SizedBox(height: 10, child: Text("خطایی رخ داد !")),
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: const CircularProgressIndicator());
                } else if (snapshot.hasData) {
                  return SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.deepOrange,
                              radius: 80,
                              child: _isUpdatingImage
          ? CircularProgressIndicator(): 
                              ClipOval(
                                child: Container(
                                  child: CachedNetworkImage(
                                      imageUrl:
                                          'https://reserve-backend.chbk.run${snapshot.data?.profilePhoto}',
                                      placeholder: (context, url) => const Center(
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator())),
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
                                onTap: () {
                                  _pickImage(
                                      ImageSource.gallery, snapshot.data!);
                                },
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(40)),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text(snapshot.data!.userName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                                fontWeight: FontWeight.bold)),
                                    IconButton(
                                        onPressed: () {
                                          _showChangeUsernameDialog(
                                              snapshot.data!);
                                        },
                                        icon: const Icon(CupertinoIcons.pen))
                                  ],
                                ),
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text(snapshot.data!.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    IconButton(
                                        onPressed: () {
                                          _showChangeEmailDialog(
                                              snapshot.data!);
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      'تاریخچه رزرو',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                    ),
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            isInHistory = true;
                                          });
                                        },
                                        icon: const Icon(
                                            CupertinoIcons.bookmark)),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text('وضعیت نظارت',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18)),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text('وضعیت مدیریت',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18)),
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
                    ),
                  );
                } else {
                  return const Center(
                    child: SizedBox(height: 10, child: Text("خطایی رخ داد !")),
                  );
                }
              }),
        ],
      ),
    );
  }

  AppBar myAppBar(BuildContext context, String title, bool inHistory) {
    return AppBar(
      foregroundColor: Colors.white,
      leadingWidth: 120,
      leading: IconButton(
          onPressed: () {
            if (inHistory == true) {
              setState(() {
                this.isInHistory = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(
            CupertinoIcons.back,
            size: 40,
            color: Color.fromARGB(255, 2, 16, 43),
          )),
      title: Center(
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      actions: [
        SizedBox(
          width: 30,
        ),
        Center(
          child: FutureBuilder<User?>(
              future: getProfile(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return InkWell(
                    onTap: () {},
                    child: CircleAvatar(
                      backgroundColor: Colors.deepOrange,
                      radius: 20,
                      child: ClipOval(
                        child: Container(
                          child: CachedNetworkImage(
                              imageUrl:
                                  'https://reserve-backend.chbk.run${snapshot.data?.profilePhoto}',
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
                    child: Center(child: SizedBox()),
                  );
                } else {
                  return IconButton(
                      onPressed: () {},
                      icon: Icon(CupertinoIcons.profile_circled));
                }
              }),
        ),
        SizedBox(
          width: 50,
        )
      ],
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
                                  "خطایی رخ داد !",
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
                      return Column(
                        children: [
                          SizedBox(
                            height: 60,
                          ),
                          Center(child: const CircularProgressIndicator()),
                        ],
                      );
                    } else if (snapshot.hasData) {
                      if (snapshot.data!.isEmpty) {
                        return Container(
                          color: Colors.white60,
                          child: const Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                              child: Text("تاریخچه ی شما خالی است !"),
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
        Text(
          shiftMeals[index].date,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 19),
        ),
      ],
    );
  }
}

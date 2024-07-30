import 'package:application/design/food.dart';
import 'package:application/design/meal.dart';
import 'package:application/design/user.dart';
import 'package:application/repository/HttpClient.dart';
import 'package:application/repository/tokenManager.dart';
import 'package:application/widgets/MainPage.dart';
import 'package:application/widgets/SoftenPageTransition.dart';
import 'package:application/widgets/createMeal.dart';
import 'package:application/widgets/profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:choice/choice.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class MealSelectionPage extends StatefulWidget {
  @override
  _MealSelectionPageState createState() => _MealSelectionPageState();
}

class _MealSelectionPageState extends State<MealSelectionPage> {
  String? selectedShift;
  Food? selectedFood;
  Food? selectedDessert;
  Food? selectedDiet;
  List<Drink> selectedDrinks = [];
  String? selectedDate;
  var _selectedDate;
  int selectedIndex = -1;
  bool internetError = false;
  bool alreadyCreated = false;
  bool success = false;
  bool selectedLaunch = false;
  bool selectedDinner = false;
  bool selectedCreateNew = false;
  List<Food> food = [];
  List<Food> diet = [];
  List<Food> dessert = [];
  List<Drink> drinks = [];
  List<Food> myfood = [];
  List<Food> mydiet = [];
  List<Food> mydessert = [];
  List<Drink> mydrinks = [];

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      final response = await HttpClient.instance.get('api/meal/create/',
          options: Options(headers: {'Authorization': 'JWT $myAccess'}));
      
      if (response.statusCode == 200) {
        setState(() {
          for (var i in response.data['foods']) {
            food.add(Food.fromJson(i));
          }
          for (var i in response.data['diets']) {
            diet.add(Food.fromJson(i));
          }
          for (var i in response.data['desserts']) {
            dessert.add(Food.fromJson(i));
          }
          for (var i in response.data['drinks']) {
            drinks.add(Drink.fromJson(i));
          }
        });
      } else {
        setState(() {
          if (response.statusCode == 306) {
            alreadyCreated = true;
          } else {
            internetError = true;
          }
        });
      }
    }
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

  List<String> choices = ['ناهار', 'شام'];

  Future<void> submitData() async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      List<int?> myIds = [];
      for (var i in selectedDrinks) {
        myIds.add(i.id);
      }
      final response = await HttpClient.instance.post(
        'api/meal/create/',
        options: Options(headers: {'Authorization': 'JWT $myAccess'}),
        data: jsonEncode(<String, dynamic>{
          'food': selectedFood!.id,
          'diet': selectedDiet?.id,
          'dessert': selectedDessert?.id,
          'daily_meal': selectedValue,
          "drinks": myIds
        }),
      );
      if (response.statusCode == 201) {
      } else {
        setState(() {
          internetError = true;
        });
      }
    }

    setState(() {
      success = true;
      selectedDate = null;
      selectedShift = null;
      selectedDessert = null;
      selectedFood = null;
      selectedDiet = null;
      selectedDrinks = [];
    });
  }

  String? selectedValue;
  void setSelectedValue(String? value) {
    setState(() {
      selectedValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
                onPressed: () {
                  FadePageRoute.navigateToNextPage(context, MealCreationPage());
                },
                icon: const Icon(
                  CupertinoIcons.back,
                  size: 40,
                  color: Color.fromARGB(255, 2, 16, 43),
                )),
            Text(
              'ایجاد وعده جدید',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 25, fontWeight: FontWeight.bold),
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
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/new7.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    success
                        ? Padding(
                            padding: EdgeInsets.fromLTRB(0, 0, 0,
                                MediaQuery.of(context).size.height / 4),
                            child: AlertDialog(
                              title: const Text('موفقیت آمیز بود'),
                              content: Text(
                                "برای ادامه کلیک کنید",
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
                        : Container(
                            height:
                                MediaQuery.of(context).size.height * (6 / 8) +
                                    10,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 16),
                                  _buildMealSection("غذا", food, 1, myfood),
                                  SizedBox(height: 16),
                                  _buildMealSection('رژیمی', diet, 3, mydiet),
                                  SizedBox(height: 16),
                                  _buildMealSection(
                                      'دسر', dessert, 2, mydessert),
                                  SizedBox(height: 16),
                                  _buildDrinkSection(
                                      'نوشیدنی ها', drinks, mydrinks),
                                  Choice<String>.inline(
                                    clearable: false,
                                    value: ChoiceSingle.value(selectedValue),
                                    onChanged: ChoiceSingle.onChanged(
                                        setSelectedValue),
                                    itemCount: choices.length,
                                    itemBuilder: (state, i) {
                                      return ChoiceChip(
                                        selected: state.selected(choices[i]),
                                        onSelected:
                                            state.onSelected(choices[i]),
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
                                ]),
                          ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white70,
                        minimumSize:
                            Size(MediaQuery.of(context).size.width * 0.8, 50),
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      onPressed: () async {
                        if ((selectedFood != null)) {
                          await submitData();
                        }
                      },
                      child: Text('تایید'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(String? title, List<Food> selectedMeals, int number,
      List<Food> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title!,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: selected.map((food) {
            return Chip(
              label: Text(food.name),
              onDeleted: () {
                setState(() {
                  selected.remove(food);
                  if (number == 1) {
                    this.selectedFood = null;
                  } else if (number == 2) {
                    this.selectedDessert = null;
                  } else {
                    this.selectedDiet = null;
                  }
                });
              },
            );
          }).toList(),
        ),
        if (selected.length < 1)
          ElevatedButton(
            onPressed: () async {
              final selectedMeal =
                  await _showFoodSelectionDialog(title, selectedMeals);
              if (selectedMeal != null) {
                setState(() {
                  selected.add(selectedMeal);
                  if (number == 1) {
                    this.selectedFood = selectedMeal;
                  } else if (number == 2) {
                    this.selectedDessert = selectedMeal;
                  } else {
                    this.selectedDiet = selectedMeal;
                  }
                });
              }
            },
            child: Text('$title اضافه کنید'),
          ),
      ],
    );
  }

  Future<Food?> _showFoodSelectionDialog(
      String title, List<Food> myFood) async {
    return showDialog<Food>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('انتخاب کنید'),
          content: Container(
            width: double.minPositive,
            child: ListView(
              shrinkWrap: true,
              children: myFood
                  .map((food) => ListTile(
                        title: Text(food.name),
                        onTap: () {
                          Navigator.pop(
                              context, food); // Return the Meal object
                        },
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('بازگشت'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrinkSection(
      String? title, List<Drink> selectedMeals, List<Drink> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title!,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            children: selected.map((food) {
              return Chip(
                label: Text(food.name),
                onDeleted: () {
                  setState(() {
                    selected.remove(food);
                  });
                },
              );
            }).toList(),
          ),
        ),
        if (true)
          ElevatedButton(
            onPressed: () async {
              final selectedMeal =
                  await _showDrinkSelectionDialog(title, selectedMeals);
              if (selectedMeal != null) {
                setState(() {
                  selected.add(selectedMeal);
                  this.selectedDrinks.add(selectedMeal);
                });
              }
            },
            child: Text('$title اضافه کنید'),
          ),
      ],
    );
  }

  Future<Drink?> _showDrinkSelectionDialog(
      String title, List<Drink> thisFood) async {
    List<Drink> myFood = [];
    for (var i in thisFood) {
      if (!this.selectedDrinks.contains(i)) {
        myFood.add(i);
      }
    }
    return showDialog<Drink>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('انتخاب کنید'),
          content: Container(
            width: double.minPositive,
            child: ListView(
              shrinkWrap: true,
              children: myFood
                  .map((food) => ListTile(
                        title: Text(food.name),
                        onTap: () {
                          Navigator.pop(
                              context, food); // Return the Meal object
                        },
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('بازگشت'),
            ),
          ],
        );
      },
    );
  }
}

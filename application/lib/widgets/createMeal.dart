import 'package:application/design/meal.dart';
import 'package:application/design/shiftmeal.dart';
import 'package:application/design/user.dart';
import 'package:application/repository/HttpClient.dart';
import 'package:application/repository/tokenManager.dart';
import 'package:application/widgets/MainPage.dart';
import 'package:application/widgets/SoftenPageTransition.dart';
import 'package:application/widgets/profile.dart';
import 'package:application/widgets/selectNewMeal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:choice/choice.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class MealCreationPage extends StatefulWidget {
  @override
  _MealCreationPageState createState() => _MealCreationPageState();
}

class _MealCreationPageState extends State<MealCreationPage> {
  bool alreadyCreated = false;
  bool internetError = false;
  List<Meal> meals = [];
  bool selectedCreateNew = false;
  String? selectedDate;
  bool selectedDinner = false;
  int selectedIndex = -1;
  bool selectedLaunch = false;
  List<Meal?> selectedMeals = [];
  String? selectedShift;
  List<String> shifts = ['A', 'B', 'C', 'D'];
  bool success = false;

  var _selectedDate;
  List<Meal> _selectedDinnerMeals = [];
  List<Meal> _selectedLunchMeals = [];

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      final response = await HttpClient.instance.get('api/shiftmeal/create/',
          options: Options(headers: {'Authorization': 'JWT $myAccess'}));
      
      if (response.statusCode == 200) {
        setState(() {
          for (var i in response.data['meals']) {
            meals.add(Meal.fromJson(i));
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

  Future<void> deleteData(Meal meal, String title) async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      final response = await HttpClient.instance.delete(
          'api/meal/delete/${meal.id}/',
          options: Options(headers: {'Authorization': 'JWT $myAccess'}));
      if (response.statusCode == 204) {
        setState(() {
          meals.remove(meal);
          Navigator.pop(context);
          this._showMealSelectionDialog(title);
        });
      } else {
        setState(() {
          internetError = true;
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

  Future<void> fetchNew() async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      selectedDate = selectedDate!.replaceAll('/', '-');
      
      final response = await HttpClient.instance.post(
        'api/shiftmeal/filter/',
        options: Options(headers: {'Authorization': 'JWT $myAccess'}),
        data: jsonEncode(<String, dynamic>{
          'shift': selectedShift!,
          'date': selectedDate!,
        }),
      );
      if (response.statusCode == 200) {
        _selectedDinnerMeals = [];
        _selectedLunchMeals = [];
        for (var i in response.data) {
          ShiftMeal myShiftMeal = ShiftMeal.fromJson(i);
          if (myShiftMeal.meal.dailyMeal == 'ناهار') {
            _selectedLunchMeals.add(myShiftMeal.meal);
          } else {
            _selectedDinnerMeals.add(myShiftMeal.meal);
          }
          selectedMeals.add(myShiftMeal.meal);
        }
      } else {
        setState(() {
          internetError = true;
        });
      }

      setState(() {});
    }
  }

  Future<void> submitData() async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      selectedDate = selectedDate!.replaceAll('/', '-');
      
      List<int> mealId = [];
      for (var i in selectedMeals) {
        mealId.add(i!.id);
      }
      final response = await HttpClient.instance.post(
        'api/shiftmeal/create/',
        options: Options(headers: {'Authorization': 'JWT $myAccess'}),
        data: jsonEncode(<String, dynamic>{
          'shift-name': selectedShift!,
          'meal-id': mealId,
          'date': selectedDate!,
        }),
      );
      if (response.statusCode == 201) {
      } else {
        setState(() {
          internetError = true;
        });
      }

      setState(() {
        success = true;
        selectedDate = null;
        selectedMeals = [];
        selectedShift = null;
      });
    }
  }

  Widget _buildMealSection(String? title, List<Meal> selectedMeals) {
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
          children: selectedMeals.map((meal) {
            return Chip(
              label: Text(meal.food.name),
              onDeleted: () {
                setState(() {
                  selectedMeals.remove(meal);
                  this.selectedMeals.remove(meal);
                  this.selectedMeals.remove(meal);
                });
              },
            );
          }).toList(),
        ),
        if (selectedMeals.length < 2)
          ElevatedButton(
            onPressed: () async {
              final selectedMeal = await _showMealSelectionDialog(title);
              if (selectedMeal != null) {
                setState(() {
                  selectedMeals.add(selectedMeal);
                  this.selectedMeals.add(selectedMeal);
                  
                });
              }
            },
            child: Text('$title اضافه کنید'),
          ),
      ],
    );
  }

  Future<Meal?> _showMealSelectionDialog(String title) async {
    List<Meal> myMeals = [];
    for (var i in meals) {
      if (i.dailyMeal == "شام" &&
          title == 'شام' &&
          !_selectedDinnerMeals.contains(i)) {
        myMeals.add(i);
      }
      if (i.dailyMeal == "ناهار" &&
          title == 'ناهار' &&
          !_selectedLunchMeals.contains(i)) {
        myMeals.add(i);
      }
    }
    String emptyString = '';
    String notEmpty = ' - ';
    return showDialog<Meal>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('انتخاب کنید'),
          content: Container(
            width: double.minPositive,
            child: ListView(
              shrinkWrap: true,
              children: myMeals
                  .map((meal) => ListTile(
                        title: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '${meal.food.type} ${meal.food.name}${meal.diet != null ? notEmpty : emptyString}${meal.diet != null ? meal.diet!.name : emptyString}${meal.desert != null ? notEmpty : emptyString}${meal.desert != null ? meal.desert!.name : emptyString}'),
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      this.deleteData(meal, title);
                                    });
                                  },
                                  icon: Icon(CupertinoIcons.trash))
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(
                              context, meal); // Return the Meal object
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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context,
                    null); // Returning null to indicate creation of new meal
              },
              child: TextButton(
                  onPressed: () => FadePageRoute.navigateToNextPage(
                      context, MealSelectionPage()),
                  child: Text('وعده جدید')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 110,
        leading: IconButton(
                onPressed: () {
                  FadePageRoute.navigateToNextPage(context, MainPage());
                },
                icon: const Icon(
                  CupertinoIcons.back,
                  size: 40,
                  color: Color.fromARGB(255, 2, 16, 43),
                )),
        foregroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            
            Text(
              'ایجاد وعده',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            
          ],
        ),
        actions: [
          SizedBox(width: 20,),
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
                                    'https://reserve.chbk.run${snapshot.data?.profilePhoto}',
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
                image: DecorationImage(
                  image: AssetImage('assets/new7.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 2 - 25,
                          child: Card(
                            color: Colors.white38!.withOpacity(0.8),
                            margin: EdgeInsets.all(0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'انتخاب شیفت',
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 18),
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  Center(
                                    child: DropdownButton<String>(
                                      dropdownColor:
                                          Color.fromARGB(255, 237, 193, 115),
                                      hint: Text('شیفت'),
                                      value: selectedShift,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedShift = newValue;
                                          if (this.selectedDate != null) {
                                            fetchNew();
                                          }
                                        });
                                      },
                                      items: shifts
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value,
                                              style: TextStyle(
                                                  color: Colors.black)),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 2 - 25,
                          child: Card(
                            color: Colors.white38!.withOpacity(0.8),
                            margin: EdgeInsets.all(0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'انتخاب تاریخ',
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 18),
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black26,
                                        fixedSize: Size(
                                            MediaQuery.of(context).size.width,
                                            10)),
                                    onPressed: () async {
                                      Jalali? pickedDate =
                                          await showPersianDatePicker(
                                        context: context,
                                        initialDate: Jalali.now(),
                                        firstDate: Jalali(1385, 8),
                                        lastDate: Jalali(1450, 9),
                                      );
                                      if (pickedDate != null) {
                                        setState(() {
                                          _selectedDate = pickedDate;
                                          selectedDate =
                                              pickedDate.formatCompactDate();
                                          if (selectedShift != null) {
                                            fetchNew();
                                          }
                                        });
                                      }
                                    },
                                    child: Text(
                                      selectedDate == null
                                          ? 'تاریخ'
                                          : selectedDate!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                                MediaQuery.of(context).size.height * (4 / 7) +
                                    10,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 16),
                                  _buildMealSection(
                                      'ناهار', _selectedLunchMeals),
                                  SizedBox(height: 16),
                                  _buildMealSection(
                                      'شام', _selectedDinnerMeals),
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
                        
                        if (_selectedDate != null &&
                            (!selectedMeals.isEmpty) &&
                            selectedShift != null) {
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
}

//   String? selectedValue;

  // void setSelectedValue(String? value) {
  //   setState(() {
  //     selectedValue = value;
  //   });
  // }

//   Widget _createNewMeal() {
//     selectedValue = this.choices[0];
//     TextEditingController foodNameController = TextEditingController();
//     List<Meal> mySelectedMeals = []; 

//     return AlertDialog(
//       title: Text('غذای جدید'),
//       content: Container(
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 TextField(
//                   controller: foodNameController,
//                   decoration: InputDecoration(
//                       label: Text('نام غذای جدید'),
//                       hintText: 'optional'),
//                 ),
                // Choice<String>.inline(
                //   clearable: false,
                //   value: ChoiceSingle.value(selectedValue),
                //   onChanged: ChoiceSingle.onChanged(setSelectedValue),
                //   itemCount: choices.length,
                //   itemBuilder: (state, i) {
                //     return ChoiceChip(
                //       selected: state.selected(choices[i]),
                //       onSelected: state.onSelected(choices[i]),
                //       label: Text(choices[i]),
                //     );
                //   },
                //   listBuilder: ChoiceList.createScrollable(
                //     spacing: 10,
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 20,
                //       vertical: 25,
                //     ),
                //   ),
                // ),
//               ],
//             ),
//             TextField(
//               controller: foodNameController,
//               decoration: InputDecoration(
//                   label: Text('نام رژیمی جدید'),
//                   hintText: 'optional'),
//               ),
//               TextField(
//                 controller: foodNameController,
//                 decoration: InputDecoration(
//                     label: Text('نام دسر جدید'),
//                   hintText: 'optional'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:application/design/user.dart';
import 'package:application/repository/HttpClient.dart';
import 'package:application/repository/tokenManager.dart';
import 'package:application/widgets/MainPage.dart';
import 'package:application/widgets/SoftenPageTransition.dart';
import 'package:application/widgets/profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class SupervisorAssignmentPage extends StatefulWidget {
  const SupervisorAssignmentPage({super.key});

  @override
  _SupervisorAssignmentPageState createState() => _SupervisorAssignmentPageState();
}

class _SupervisorAssignmentPageState extends State<SupervisorAssignmentPage> {
  late Future<List<User>> futureUsers;
  User? selectedUser;
  Jalali? fromDate;
  Jalali? toDate;

  Future<List<User>> fetchUsers(BuildContext context) async {
    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      final response = await HttpClient.instance.get("api/manager/",
          options: Options(headers: {"Authorization": "JWT $myAccess"}));
      List<User> myUsers = [];
      for (var i in response.data) {
        myUsers.add(User.fromJson(i));
      }
      return myUsers;
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    futureUsers = fetchUsers(context);
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    Jalali? picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.now(),
      firstDate: Jalali(1300, 1, 1),
      lastDate: Jalali(1450, 12, 29),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  void _submit() async {
    if (selectedUser == null || fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final fromDateIso = fromDate!.toJalaliDateTime().substring(0, 10);
    final toDateIso = toDate!.toJalaliDateTime().substring(0, 10);


    VerifyToken? myVerify = await TokenManager.verifyAccess(context);
    if (myVerify == VerifyToken.verified) {
      String? myAccess = await TokenManager.getAccessToken();
      final response = await HttpClient.instance.post("api/manager/",
          options: Options(headers: {"Authorization": "JWT $myAccess"}),
          data: {
            'user': selectedUser!.id,
            'from_date': fromDateIso,
            'to_date': toDateIso
          });
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Supervisor assigned successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign supervisor')),
        );
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

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                FadePageRoute.navigateToNextPage(context, MainPage());
              },
              icon: const Icon(
                CupertinoIcons.back,
                size: 40,
                color: Color.fromARGB(255, 2, 16, 43),
              ),
            ),
            Text(
              'صفحه سرپرست',
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
                  } else if (snapshot.connectionState == ConnectionState.waiting) {
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              //color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/new4.jpg'),
                fit: BoxFit.cover, // This ensures the image covers the entire background
              ),
            ),
            child: FutureBuilder<List<User>>(
              future: futureUsers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No users found'));
                } else {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: screenHeight * 0.01,
                        ),
                        DropdownButtonFormField<User>(
                          decoration: InputDecoration(labelText: 'Select Supervisor'),
                          items: snapshot.data!.map((User user) {
                            return DropdownMenuItem<User>(
                              value: user,
                              child: Text(user.userName),
                            );
                          }).toList(),
                          onChanged: (User? newValue) {
                            setState(() {
                              selectedUser = newValue;
                            });
                          },
                          value: selectedUser,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(labelText: 'From Date'),
                                readOnly: true,
                                onTap: () => _selectDate(context, true),
                                controller: TextEditingController(
                                  text: fromDate != null ? fromDate!.formatCompactDate() : '',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.calendar_today),
                              onPressed: () => _selectDate(context, true),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(labelText: 'To Date'),
                                readOnly: true,
                                onTap: () => _selectDate(context, false),
                                controller: TextEditingController(
                                  text: toDate != null ? toDate!.formatCompactDate() : '',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.calendar_today),
                              onPressed: () => _selectDate(context, false),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Center(
                          child: ElevatedButton(
                            onPressed: _submit,
                            child: Text('Assign Supervisor'),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthUser? awsUser;
  String image = "";

  @override
  void initState() {
    super.initState();
    checkCurrentUser();
  }

  void checkCurrentUser() async {
    try {
      setState(() async {
        awsUser = await Amplify.Auth.getCurrentUser();
        try {
          final result = await Amplify.Auth.fetchUserAttributes();
          for (final element in result) {
            print('key: ${element.userAttributeKey}; value: ${element.value}');
            if (element.userAttributeKey == CognitoUserAttributeKey.picture){
              getImageUrl(element.value);
            }
          }
        } on AuthException catch (e) {
          print(e.message);
        }
      });

    } on AuthException catch (e) {

      print(e);
    }
  }

  Future<void> getImageUrl(String key) async{
    try {
      final result = await Amplify.Storage.getUrl(key: key);
      print('Storage successful');
      setState(() {
        image = result.url;
      });
      print(result.url);
    } on StorageException catch (storeError) {
      print('Storage failed - $storeError');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
      Center(
        child: CircleAvatar(
          radius: 60, // Image radius
          backgroundImage: image != "" ? NetworkImage(image) : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png')
        ),
      ),
    ],),);
  }
}

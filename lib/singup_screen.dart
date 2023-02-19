import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:profile/verify_code_screen.dart';

import 'amplifyconfiguration.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      final auth = AmplifyAuthCognito();
      final storage = AmplifyStorageS3();
      await Amplify.addPlugins([auth, storage]);

      // call Amplify.configure to use the initialized categories in your app
      await Amplify.configure(amplifyconfig);
    } on Exception catch (e) {
      safePrint('An error occurred configuring Amplify: $e');
    }
  }

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNoController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isSignUpComplete = false;


  // List of items in our dropdown menu
  var items = [
    'Male',
    'Female'
  ];

  // initial value
  String initialValue = 'Male';

  // date picker
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1947, 8),
        lastDate: DateTime(2024));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Image picker
  File? imageFile;

  /// Get from gallery
  _getFromGallery() async {
    PickedFile? pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });

    }
  }

  /// Get from camera
  _getFromCamera() async {
    PickedFile? pickedFile = await ImagePicker().getImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState((){
        imageFile = File(pickedFile.path);
      });
    }
  }

  // Show alert dialog
  Future<void> _showImagePickerDialog() async {
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog( // <-- SEE HERE
            title: const Text('Select image from'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  _getFromCamera();
                  Navigator.of(context).pop();
                },
                child: const Text('Camera'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  _getFromGallery();
                  Navigator.of(context).pop();
                },
                child: const Text('Gallery'),
              ),
            ],
          );
        });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up"),),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: isLoading ? const Center(child: CircularProgressIndicator(),) :Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Stack(
                  children: [
                  CircleAvatar(
                    radius: 60, // Image radius
                    backgroundImage: imageFile != null ? FileImage(imageFile!) as ImageProvider : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                  ),

                  Positioned(
                    left: 0,
                      right: 0,
                      bottom: 0,

                      child: Container(
                        height: 50,
                        decoration: const BoxDecoration(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60)), color: Colors.grey),
                        child: IconButton(onPressed: () async {
                          _showImagePickerDialog();
                        }, icon: const Icon(Icons.edit)),
                      )),
                ],),


                TextFormField(controller: nameController,
                  decoration: const InputDecoration(hintText: "name"),),
                TextFormField(controller: emailController,
                    decoration: const InputDecoration(hintText: "email")),
                TextFormField(controller: phoneNoController,
                    decoration: const InputDecoration(hintText: "phone")),
                TextFormField(controller: passwordController,
                    decoration: const InputDecoration(hintText: "password")),
                Row(
                  children: [
                    const Text("Gender: "),
                    const SizedBox(width: 10,),
                    Expanded(
                      child: DropdownButton(
                        // Initial Value
                          value: initialValue,

                          // Down Arrow Icon
                          icon: const Icon(Icons.keyboard_arrow_down),

                          // Array list of items
                          items: items.map((String items) {
                            return DropdownMenuItem(
                              value: items,
                              child: Text(items, textAlign: TextAlign.end,),
                            );
                          }).toList(),
                          // After selecting the desired option,it will
                          // change button value to selected value
                          onChanged: (value) {
                            setState(() {
                              initialValue = value!;
                            });
                          }
                      ),
                    ),
                  ],
                ),

                Row(

                  children: <Widget>[
                    const Text("Date of Birth: "),
                    const SizedBox(width: 10,),
                    Text("${selectedDate.toLocal()}".split(' ')[0]),
                    const SizedBox(width: 10.0,),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.date_range_sharp, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 20,),
                ElevatedButton(onPressed: () async {
                  uploadFilePublic();
                }, child: const Text("Sign Up"))
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> uploadFilePublic() async {
    setState(() {
      isLoading = true;
    });

    // Upload the file to S3
    if(imageFile != null ){
      try {
        final UploadFileResult result = await Amplify.Storage.uploadFile(
          local: imageFile!,
          key: phoneNoController.text.trim(),
          options: S3UploadFileOptions(
            accessLevel: StorageAccessLevel.guest,
          ),
        );
        print('Successfully uploaded file: ${result.key}');
        signUp();
      } on StorageException catch (e) {
        print('Error uploading file: $e');
      }
    }
  }

  /*Future<void> getImageUrl(String key) async{
    try {
      final result = await Amplify.Storage.getUrl(key: key);
      print('Storage successful');
      signUp(result.url);
      print(result.url);
    } on StorageException catch (storeError) {
      print('Storage failed - $storeError');
    }
  }*/


  Future<void> signUp() async{
    setState(() {
      isLoading = true;
    });

    try {

      SignUpResult res = await Amplify.Auth.signUp(
          username: emailController.text.trim(),
          password: passwordController.text,
          options: CognitoSignUpOptions(
              userAttributes: {CognitoUserAttributeKey.email : emailController.text.trim(),
                CognitoUserAttributeKey.phoneNumber : "+91${phoneNoController.text.trim()}",
                CognitoUserAttributeKey.name : nameController.text.trim(),
                CognitoUserAttributeKey.gender : initialValue,
                CognitoUserAttributeKey.birthdate : DateFormat('yyyy-MM-dd').format(selectedDate),
                CognitoUserAttributeKey.picture : phoneNoController.text.trim()
              })
      );
      setState(() {
        isSignUpComplete = res.isSignUpComplete;
        if (res.isSignUpComplete){
          isLoading = false;
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => VerifyCodeScreen(username: emailController.text.trim().toString(), password: passwordController.text.trim().toString(),)));
        }
      });
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
      _showToast(context, e.toString());
    }
  }


  void _showToast(BuildContext context, String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

}

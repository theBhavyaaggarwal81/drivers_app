import 'dart:io';

import 'package:drivers_app/pages/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget
{
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
{
  TextEditingController usernameTextEditingController = TextEditingController();
  TextEditingController userphoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  TextEditingController vehicleModelTextEditingController = TextEditingController();
  TextEditingController vehicleColorTextEditingController = TextEditingController();
  TextEditingController vehicleNumberTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();
  XFile? imageFile;
  String urlOfUploadedImage = "";

  checkIfNetworkIsAvailable(){
    cMethods.checkConnectivity(context);

    if(imageFile!=null){
      signUpFormValidation();
    }else{
      cMethods.displaySnackBar("Please choose image first!", context);
    }
  }

  signUpFormValidation(){
    if(usernameTextEditingController.text.trim().length <5){
      cMethods.displaySnackBar("Your username must be atleast 6 characters.", context);
    }
    else if(userphoneTextEditingController.text.trim().length == 11 ){
      cMethods.displaySnackBar("Your phone number must be 10 digits.", context);
    }
    else if(!emailTextEditingController.text.contains('@')){
      cMethods.displaySnackBar("Invalid email.", context);
    }
    else if(passwordTextEditingController.text.trim().length < 7){
      cMethods.displaySnackBar("Your password must be atleast 8 characters.", context);
    }
    else if(vehicleModelTextEditingController.text.trim().isEmpty){
      cMethods.displaySnackBar("Please write your car model.", context);
    }
    else if(vehicleColorTextEditingController.text.trim().isEmpty){
      cMethods.displaySnackBar("Please write your car color.", context);
    }
    else if(vehicleNumberTextEditingController.text.trim().isEmpty){
      cMethods.displaySnackBar("Please write your car number.", context);
    }
    else{
      //register
      uploadImageToStorage();
    }
  }

  uploadImageToStorage() async{
    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceImage = FirebaseStorage.instance.ref().child("Images").child(imageIDName);

    UploadTask uploadTask = referenceImage.putFile(File(imageFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    setState(() {
      urlOfUploadedImage;
    });

    registerNewDriver();
  }

  registerNewDriver() async
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Registering your account..."),
    );

    final User? userFirebase = (
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
    ).catchError((errorMsg)
    {
      Navigator.pop(context);
      cMethods.displaySnackBar(errorMsg.toString(), context);
    })
    ).user;

    if(!context.mounted)return;
    Navigator.pop(context);

    DatabaseReference userRef= FirebaseDatabase.instance.ref().child("drivers").child(userFirebase!.uid);
    Map driverCarInfo =
    {
      "carColor" : vehicleColorTextEditingController.text.trim(),
      "carModel" : vehicleModelTextEditingController.text.trim(),
      "carNumber" : vehicleNumberTextEditingController.text.trim(),
    };
    Map driverDataMap =
    {
      "photo": urlOfUploadedImage,
      "car_details" : driverCarInfo,
      "name": usernameTextEditingController.text.trim(),
      "email": emailTextEditingController.text.trim(),
      "phone": userphoneTextEditingController.text.trim(),
      "id": userFirebase.uid,
      "blockStatus": "no",
    };
    userRef.set(driverDataMap);

    Navigator.push(context, MaterialPageRoute(builder: (c)=> Dashboard()));

  }

  chooseImageFromGallery() async{
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(pickedFile!=null){
      setState(() {
        imageFile = pickedFile;
      });
    }
  }


  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding : const EdgeInsets.all(10),
          child: Column(
            children: [

              const SizedBox(
                height: 40,
              ),

              imageFile == null?

              const CircleAvatar(
                radius: 86,
                backgroundImage: AssetImage("assets/images/avatarman.png"),
              ) : Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                  image: DecorationImage(
                    fit: BoxFit.fitHeight,
                    image: FileImage(
                      File(
                        imageFile!.path,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              GestureDetector(
                onTap: (){
                  chooseImageFromGallery();
                },
                child: const Text(
                  "Choose Image",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              //text-fields + buttons
              Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      TextField(
                        controller: usernameTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Your Name",
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 22,),

                      TextField(
                        controller: userphoneTextEditingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Your Phone",
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 22,),

                      TextField(
                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Your Email",
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 22,),

                      TextField(
                        controller: passwordTextEditingController,
                        obscureText: true,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Your Password",
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 22,),

                      TextField(
                        controller: vehicleModelTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Your Car Model",
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 22,),

                      TextField(
                        controller: vehicleColorTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Your Car Color",
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 22,),

                      TextField(
                        controller: vehicleNumberTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Your Car Number",
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 22,),

                      ElevatedButton(
                          onPressed: ()
                          {
                            checkIfNetworkIsAvailable();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor : Colors.purple,
                            padding : const EdgeInsets.symmetric(horizontal: 80, vertical: 10)
                          ),
                        child: const Text(
                          "Sign Up"
                        ),
                      ),
                    ],
                  ),
              ),

              const SizedBox(height: 12,),

              //textbutton
              TextButton(onPressed: (){
                Navigator.push(context,MaterialPageRoute(builder: (c)=> LoginScreen()));
              },
                  child: const Text(
                    "Already have an account? Login Here",
                    style: TextStyle(
                      color: Colors.grey,
                    )
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
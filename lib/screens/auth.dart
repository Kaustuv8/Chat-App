import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance; 

class AuthScreen extends StatefulWidget{
  const AuthScreen ({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen>{

  final _Formkey = GlobalKey<FormState>();

  var isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  File? _selectedImage;
  var _isAuthenticating = false;
  var _enteredUsername = '';

  void _submit() async {
    final isValid = _Formkey.currentState!.validate();
    if(!isValid){
      return;
    }

    if(!isLogin && _selectedImage == null){
      return;
    }

    _Formkey.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if(isLogin){
        final userCredentials = await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail, password: _enteredPassword);
        
      }
      else{
          final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
          
          final storageRef = FirebaseStorage.instance.
            ref().
            child('user_images').
            child('${userCredentials.user!.uid}.jpg');
          await storageRef.putFile(_selectedImage!);
          final imageURL = await storageRef.getDownloadURL();
          
          await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredentials.user!.uid)
          .set({
            'username' : _enteredUsername,
            'email' : _enteredEmail,
            'image_url' : imageURL,
          }).onError((error, stackTrace) => print("Error happened tee hee XD"));
          print("AAAAAA");
      }
    }
    on FirebaseAuthException catch (error){
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            error.message ?? "Authentication Failed", 
            style: const TextStyle(fontSize:18),
          ),
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
              width: 200,
              child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _Formkey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if(!isLogin) UserImagePicker(
                            onPickImage: (pickedImage){
                              _selectedImage = pickedImage;
                            },
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Email Address",
                              
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if(value == null ||value.trim().isEmpty || !value.contains('@')){
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (value){
                              _enteredEmail = value!;
                            },
                          ),
                          if(!isLogin)
                          TextFormField(
                            decoration: const InputDecoration(label: Text('Username')),
                            enableSuggestions: false,
                            validator: (value){
                              if(value == null || value.trim().length < 4 || value.isEmpty){
                                return 'Please enter a username of at least 4 characters';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _enteredUsername = newValue!;
                            },
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Password",
                              
                            ),
                            obscureText: true,
                            validator: (value){
                              if(value == null || value.trim().length < 6 ){
                                return "Password must be 6 characters long";
                              }
                              return null;
                            },
                            onSaved: (value){
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(height : 12),
                          if(_isAuthenticating)
                            const CircularProgressIndicator(),
                          if(!_isAuthenticating)
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            ),
                            child: Text(isLogin? "Login" : "Sign up"),
                          ),
                          if(!_isAuthenticating)
                          TextButton(
                            onPressed: (){
                              setState(() {
                                isLogin = !isLogin;
                              });
                              
                            }, 
                            child: Text(isLogin ? 
                            'Create an account' : 
                            'I already have an account'
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
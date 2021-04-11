
import 'package:bhaithamen/utilities/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:bhaithamen/data/user.dart';

class LoginScreen extends StatelessWidget {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;


  initialiseData(auth.User user)async{

      DocumentSnapshot userDoc = await userCollection.doc(user.uid).get();

        if (!userDoc.exists){
            
              userCollection.doc(user.uid).set({
              'uid': user.uid,
              'username': '',
              'email':'',
              'profilepic': 'default',
              'phoneContact':[],
            
            });
  }
  }


  Future<bool> loginUser(String phone, BuildContext context) async{

    _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: Duration(seconds: 60),
        verificationCompleted: (auth.AuthCredential credential) async{
          Navigator.of(context).pop();

    try{
      auth.UserCredential result = await _auth.signInWithCredential(credential);
      auth.User user = result.user;
      print ('logged in and '+user.uid);
      await initialiseData(user);

      Navigator.pop(context);
      return user != null ? User(uid: user.uid) : null; 
    }catch(e){
      print (e.toString());

      return null;
    }

          //This callback would gets called when verification is done auto maticlly
        },
        verificationFailed: (auth.FirebaseAuthException exception){
          print(exception);
        },
        codeSent: (String verificationId, [int forceResendingToken]){
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: Text("Enter the code from SMS"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _codeController,
                    ),
                  ],
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text("Confirm"),
                    textColor: Colors.white,
                    color: Colors.blue,
                    onPressed: () async{
                      final code = _codeController.text.trim();
                      auth.AuthCredential credential = auth.PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);
                      try{
                        auth.UserCredential result = await _auth.signInWithCredential(credential);
                        auth.User user = result.user;
                        await initialiseData(user);
                        print ('logged in and '+user.uid);
                        Navigator.pop(context);
                        return user != null ? User(uid: user.uid) : null; 
                        
                      }catch(e){
                        print (e.toString());

                        return null;
                      }
                    },
                  )
                ],
              );
            }
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          verificationId = verificationId;
        });
    
  }

  //loginUser(phone, context);

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(32),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Login", style: TextStyle(color: Colors.lightBlue, fontSize: 36, fontWeight: FontWeight.w500),),

                  SizedBox(height: 16,),

                  TextFormField(
                    decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Colors.grey[200])
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Colors.grey[300])
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: "Mobile Number"

                    ),
                    controller: _phoneController,
                  ),

                  SizedBox(height: 16,),


                  Container(
                    width: double.infinity,
                    child: FlatButton(
                      child: Text("LOGIN"),
                      textColor: Colors.white,
                      padding: EdgeInsets.all(16),
                      onPressed: () {
                        final phone = _phoneController.text.trim();

                        loginUser(phone, context);

                      },
                      color: Colors.blue,
                    ),
                  )
                ],
              ),
            ),
          ),
        )
    );
  }
}
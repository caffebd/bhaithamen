import 'package:bhaithamen/data/user.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:international_phone_input/international_phone_input.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:url_launcher/url_launcher.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool termsAccepted = false;

  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  var emailController = TextEditingController();
  var passwordController = TextEditingController();

  final _codeController = TextEditingController();

  String phoneNumber = '01234567890';
  String phoneIsoCode = 'BD';
  bool visible = false;
  String confirmedNumber = '';
  bool validNumber = false;

  Future<bool> checkConnection() async {
//bool hasConnection=false;
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      // I am connected to a mobile network.
      //hasConnection=true;
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      // I am connected to a wifi network.
      //hasConnection=true;
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _needInternet(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            title: Text(languages[selectedLanguage[languageIndex]]
                ['needInternetTitle']),
            content: Container(
                height: 180,
                width: 320,
                child: Center(
                      child: Column(
                        children: [
                          Text(
                              languages[selectedLanguage[languageIndex]]
                                  ['needInternetDesc'],
                              style: myStyle(20, Colors.red, FontWeight.w400)),
                          SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Spacer(),
                              FlatButton(
                                child: Text(
                                    languages[selectedLanguage[languageIndex]]
                                        ['ok'],
                                    style: myStyle(14, Colors.white)),
                                textColor: Colors.white,
                                color: Colors.red,
                                onPressed: () async {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ) ??
                    false)));
  }

  _launchURL() async {
    const url = 'http://bhaithamen.com/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // login()async{
  //   await _auth.signInWithEmailAndPassword(emailController.text, passwordController.text);
  //   //FirebaseAuth.instance.signInWithEmailAndPassword(email: emailController.text, password: passwordController.text);
  // }

  void onPhoneNumberChange(
      String number, String internationalizedPhoneNumber, String isoCode) {
    validNumber = true;
    setState(() {
      phoneNumber = internationalizedPhoneNumber;
      phoneIsoCode = isoCode;
    });
  }

  onValidPhoneNumber(
      String number, String internationalizedPhoneNumber, String isoCode) {
    setState(() {
//      validNumber=true;
      visible = true;
      confirmedNumber = internationalizedPhoneNumber;
    });
  }

  initialiseData(auth.User user, String phone) async {
    DocumentSnapshot userDoc = await userCollection.doc(user.uid).get();

    if (!userDoc.exists) {
      userCollection.doc(user.uid).set({
        'uid': user.uid,
        'username': '',
        'email': '',
        'profilepic': 'default',
        'phoneContact': [],
        'userPhone': phone,
        'age': 0,
        'killed': false
      });
    } else {
      sendResearchReport('Sign_In');
      return user != null ? User(uid: user.uid) : null;
    }
  }

  Future<bool> loginUser(String phone, BuildContext context) async {
    _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: Duration(seconds: 60),
        verificationCompleted: (auth.AuthCredential credential) async {
          Navigator.of(context).pop();

          try {
            auth.UserCredential result =
                await _auth.signInWithCredential(credential);
            auth.User user = result.user;

            await initialiseData(user, phone);

            Navigator.pop(context);

            return user != null ? User(uid: user.uid) : null;
          } catch (e) {
            print(e.toString());

            return null;
          }

          //This callback would gets called when verification is done auto maticlly
        },
        verificationFailed: (auth.FirebaseAuthException exception) {
          print(exception);
          print('NO NO NO');
          flushLoginError();
        },
        codeSent: (String verificationId, [int forceResendingToken]) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                      languages[selectedLanguage[languageIndex]]['enterCode']),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        controller: _codeController,
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FlatButton(
                          child: Text(languages[selectedLanguage[languageIndex]]
                              ['cancel']),
                          textColor: Colors.white,
                          color: Colors.red,
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                        ),
                        SizedBox(width: 100),
                        FlatButton(
                          child: Text(languages[selectedLanguage[languageIndex]]
                              ['confirm']),
                          textColor: Colors.white,
                          color: Colors.green,
                          onPressed: () async {
                            final code = _codeController.text.trim();
                            auth.AuthCredential credential =
                                auth.PhoneAuthProvider.credential(
                                    verificationId: verificationId,
                                    smsCode: code);
                            try {
                              auth.UserCredential result =
                                  await _auth.signInWithCredential(credential);
                              auth.User user = result.user;
                              await initialiseData(user, phone);

                              Navigator.pop(context);

                              return user != null ? User(uid: user.uid) : null;
                            } catch (e) {
                              print(e.toString());

                              return null;
                            }
                          },
                        )
                      ],
                    ),
                  ],
                );
              });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          verificationId = verificationId;
        });
  }

  Future<bool> _terms(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) =>
            AlertDialog(
              contentPadding: EdgeInsets.only(left: 25, right: 25),
              title: Center(
                  child: Text(
                      languages[selectedLanguage[languageIndex]]['terms'])),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              content: Container(
                height: 400,
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                          languages[selectedLanguage[languageIndex]]['termsA']),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                          languages[selectedLanguage[languageIndex]]['termsB']),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                          languages[selectedLanguage[languageIndex]]['termsC']),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(),
                          RaisedButton(
                              onPressed: () {
                                termsAccepted = false;
                                Navigator.of(context).pop(false);
                              },
                              child: Text(
                                  languages[selectedLanguage[languageIndex]]
                                      ['cancel'])),
                          Spacer(),
                          RaisedButton(
                              onPressed: () {
                                termsAccepted = true;
                                Navigator.of(context).pop(false);
                                loginUser(phoneNumber, context);
                              },
                              child: Text(
                                  languages[selectedLanguage[languageIndex]]
                                      ['accept'])),
                          Spacer(),
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ) ??
            false);
  }

  @override
  Widget build(BuildContext context) {
    //final LocalAuthNotifier localAuthState = Provider.of<LocalAuthNotifier>(context);
    globalContext = context;

    return Scaffold(
        backgroundColor: Colors.lightBlue,
        body: SingleChildScrollView(
          child: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Text(languages[selectedLanguage[languageIndex]]['title'], style: myStyle(18, Colors.white, FontWeight.w600)),
                SizedBox(height: 50),
                Text(
                  languages[selectedLanguage[languageIndex]]['welcome'],
                  style: myStyle(24, Colors.white, FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),

                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Text(
                    languages[selectedLanguage[languageIndex]]['signInPrompt'],
                    maxLines: 2,
                    style: myStyle(20, Colors.white, FontWeight.w400),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 30),
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.only(left: 20, right: 20),
                  padding: EdgeInsets.only(left: 10, right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: InternationalPhoneInput(
                    // decoration: InputDecoration.collapsed(
                    //   //hintText: '*** *** ****',
                    //   //hintStyle: myStyle(18, Colors.black, FontWeight.w600),
                    //   ),
                    onPhoneNumberChange: onPhoneNumberChange,
                    initialPhoneNumber: '',
                    initialSelection: phoneIsoCode,
                    errorText: languages[selectedLanguage[languageIndex]]
                        ['invalidNumber'],
                    errorStyle: myStyle(14, Colors.red[300], FontWeight.w700),
                    labelText: languages[selectedLanguage[languageIndex]]
                        ['enterNumber'],
                    labelStyle: myStyle(20, Colors.blue[800]),
                    enabledCountries: ['+880'],
                    showCountryCodes: true,
                    showCountryFlags: true,
                  ),
                ),

                SizedBox(height: 20),
                Text(confirmedNumber),
                InkWell(
                  onTap: () async {
                    //check internet
                    bool hasInternet = await checkConnection();
                    if (hasInternet == false) {
                      _needInternet(context);
                    } else {
                      //await localAuthState.setLocalAuthVale(false);
                      if (validNumber == true) {
                        //_terms(context);
                        loginUser(phoneNumber, context);
                      } else {
                        print("no");
                        //loginUser(phoneNumber, context);
                      } // login();
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['loginBtn'],
                          style: myStyle(20, Colors.black, FontWeight.w700)),
                    ),
                  ),
                ),
                // SizedBox(height: 40),
                // Container(
                //   margin: EdgeInsets.only(
                //     left: MediaQuery.of(context).size.width / 6,
                //     right: MediaQuery.of(context).size.width / 6,
                //   ),
                //   child: FlatButton(
                //     onPressed: () async {
                //       //await localAuthState.setLocalAuthVale(false);
                //       await _authPage.signInWithGoogleAuth();
                //     },
                //     padding: EdgeInsets.all(0.0),
                //     child: Image.asset('assets/images/googleBtn.png'),
                //   ),
                // ),

                SizedBox(height: 80),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Text(
                            languages[selectedLanguage[languageIndex]]
                                ['whatIs'],
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: myStyle(20, Colors.white, FontWeight.w400))),
                  ],
                ),
                SizedBox(height: 10),
                InkWell(
                    onTap: () => _launchURL(),
                    child: Text('www.bhaithamen.com',
                        style: myStyle(20, Colors.white, FontWeight.w500))),
              ],
            ),
          ),
        ));
  }
}

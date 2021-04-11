import 'dart:io';

import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ProfilePage extends StatefulWidget {
  final UserData userData;
  ProfilePage(this.userData);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final analyticsHelper = AnalyticsService();
  String uid;
  Stream userStream;
  String userName;
  String email;
  bool profileChanged=false;
  String profilePic='default';
  bool hasData=false;
  bool isEditing=false;
  var userNameController = TextEditingController();
  var emailController = TextEditingController();
  var ageController = TextEditingController();
  List<TextEditingController>  phoneController = [TextEditingController(), TextEditingController(), TextEditingController(),TextEditingController()]; 
  //List<TextEditingController>();
  File imageFile;
  String pickedImagePath;
  List<String> phoneNumbers = List<String>();
  List<FocusNode> phoneFocusNodes = [FocusNode(),FocusNode(),FocusNode(),FocusNode()];
  
  final AuthService _auth = AuthService();

  dynamic pinProvider;

  FocusNode userNameFocus; 
  FocusNode emailFocus;
  FocusNode ageFocus;

  String emailHint;
  String userHint;
  String ageHint;
  bool killed;
 

  initState(){
    super.initState();
    getCurrentUserUID();

    userNameFocus = FocusNode();
    userFocusCheck();

    emailFocus = FocusNode();
    emailFocusCheck();

    phoneFocusCheck();
    ageFocus = FocusNode();
    ageFocusCheck();

    emailHint = languages[selectedLanguage[languageIndex]]['email'];
    userHint = languages[selectedLanguage[languageIndex]]['username'];
    ageHint = languages[selectedLanguage[languageIndex]]['age'];
    

    analyticsHelper.sendAnalyticsEvent('Profile_Page_Viewed');
    analyticsHelper.testSetCurrentScreen('profile_page');
    sendResearchReport('Profile_Page_Viewed');    

  }

  phoneFocusCheck(){
    for (var i=0; i<phoneFocusNodes.length; i++){
      phoneFocusNodes[i].addListener(() {

      if (!phoneFocusNodes[i].hasFocus) {
        print ('phone '+i.toString()+ 'lost focys');
        updateProfile();
      }
    });
  }
}

  userFocusCheck(){
      userNameFocus.addListener(() {
    // TextField lost focus
    if (!userNameFocus.hasFocus) {
      updateProfile();
      setState(() {
      userHint=languages[selectedLanguage[languageIndex]]['username'];
       });      
    }else{
      setState((){
        userHint='';
       });
    }
  });
  }

    emailFocusCheck(){
      emailFocus.addListener(() {
    // TextField lost focus
    if (!emailFocus.hasFocus) {
      updateProfile();
      setState(() {
      emailHint=languages[selectedLanguage[languageIndex]]['email'];
       });
       }else{
        setState((){
          emailHint='';
       });
      }
        //userNameEditing=false; 
  });
  }

  ageFocusCheck(){
      ageFocus.addListener(() {
    // TextField lost focus
    if (!ageFocus.hasFocus) {
      updateProfile();
      setState(() {
      ageHint=languages[selectedLanguage[languageIndex]]['age'];
       });
       }else{
        setState((){
          ageHint='';
       });
      }
        //userNameEditing=false; 
  });
  }



  getCurrentUserInfo()async{
    var firebaseuser = FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await userCollection.doc(firebaseuser.uid).get();
    setState(() {
      userName=userDoc['username'];
      userNameController.text=userDoc['username'];
      email=userDoc['email'];
      killed=userDoc['killed'];
      emailController.text=userDoc['email']; 
      ageController.text=userDoc['age'] != 0 ? userDoc['age'].toString() : '';    
      print (userDoc['phoneContact']);
      for (var i=0; i<userDoc['phoneContact'].length; i++){
        phoneController[i].text= userDoc['phoneContact'][i];
      }
      //phoneController.text=userDoc['phoneContact'];
      profilePic=userDoc['profilepic'];
      hasData=true;
    });
  }



  getCurrentUserUID()async{
    var firebaseuser = FirebaseAuth.instance.currentUser;
    setState(() {
      uid = firebaseuser.uid;
    });
    getCurrentUserInfo();
  }






  pickImage(ImageSource source)async{
    final image = await ImagePicker().getImage(source: source);
    setState(() {
      imageFile = File(image.path);
      pickedImagePath = image.path;
      profileChanged=true;
    });
    Navigator.pop(context);
    updateProfile();
    sendResearchReport('Profile_Image_Selected');
    //disablePin=false;
  }

uploadImage(String id)async{
    StorageUploadTask  storageUploadTask = userStorage.child(id).putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await storageUploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    
    return downloadUrl;
    
  }

  updateProfile()async{
    print ('uploading pefile');
    var firebaseUser =  FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await userCollection.doc(firebaseUser.uid).get();
    String imageurl = userDoc['profilepic'];
    String userPhone = userDoc['userPhone'] ?? '';
    //int userAgeInt = userDoc['age'] ?? '';
    //String userAge = userAgeInt.toString();

  if (profileChanged){
      imageurl = await uploadImage(firebaseUser.uid+'profile');
      profileChanged=false;
      profilePic = imageurl;
  }

phoneNumbers.clear();

  for (var i=0; i<phoneController.length; i++){
    if (phoneController[i].text.length>0){
      phoneNumbers.add(phoneController[i].text.replaceAll(' ', ''));
    }
  }

  int newAge = 0;

  String getAge = ageController.text.replaceAll(' ', '');

  if (getAge==''){
    newAge=0;
  }else{
    newAge = int.parse(ageController.text);
  }

   


        userCollection.doc(firebaseUser.uid).set({
        'username': userNameController.text,
        'profilepic': imageurl,
        'uid': firebaseUser.uid,
        'email': emailController.text,
        'killed':killed,
        'phoneContact': phoneNumbers,
        'userPhone': userPhone,
        'age': newAge,
      });
        
      
  needThePin=true;
  appHasStarted = true;

  //phone to shared prefs
  _localPhoneNumbers();
  }

  Future<void> _localPhoneNumbers() async {
    final SharedPreferences prefs = await _prefs;
    prefs.setStringList('contacts', phoneNumbers);
  }

  optionsDialog(){
    return showDialog(
      context: context,
      builder: (context){
        return SimpleDialog(
          children: [
            SimpleDialogOption(
              onPressed:() {
                
                needThePin=false;
                appHasStarted = false;
                pickImage(ImageSource.gallery);
              
              },
              child: Text(languages[selectedLanguage[languageIndex]]['galleryImage'], style: myStyle(18))
            ),
            SimpleDialogOption(
              onPressed:()=>pickImage(ImageSource.camera),
              child: Text(languages[selectedLanguage[languageIndex]]['cameraImage'], style: myStyle(18))
            ),
            SimpleDialogOption(
              onPressed:()=>Navigator.pop(context),
              child: Text(languages[selectedLanguage[languageIndex]]['cancel'], style: myStyle(18))
            ),
          ],
        );
      }
      );
  
  }



  @override
  Widget build(BuildContext context) {
  final AutoHomePageMapSelect homePageMap = Provider.of<AutoHomePageMapSelect>(context);
  final AutoHomePageAskSelect homePageAsk = Provider.of<AutoHomePageAskSelect>(context);
  final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);
  final PinRequired isPinNeeded = Provider.of<PinRequired>(context);
    pinProvider = isPinNeeded;
    return Scaffold(
      floatingActionButton: 
      isEditing ? 
      FloatingActionButton(
        onPressed: ()=> updateProfile(),
        child: Icon(Icons.add, size:32),
        ) : null,
        appBar: AppBar(
        title: testModeToggle ? Text(languages[selectedLanguage[languageIndex]]['testOn'], style: myStyle(18, Colors.white)): Text(languages[selectedLanguage[languageIndex]]['title'], style: myStyle(18, Colors.white)),   
        backgroundColor: testModeToggle ? Colors.red : Colors.blue,
        actions: <Widget>[
          //if (homePageMap.shouldGoMap) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){ setState(() {homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);Navigator.pop(context);});}),
          if (homePageAsk.shouldGoAsk) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){setState(() {homePageIndex = 2; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageAsk.setHomePageAsk(false);Navigator.pop(context);
          Navigator.pop(context);});}),
          if (homePageMap.shouldGoMap)
          FlatButton(
            child: Lottie.asset('assets/lottie/alert.json'),
            onPressed: (){ setState(() {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapWrapper(),
                    ),
                  );              
              //homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);
              });
              }) ,         
          IconButton(icon: Icon(Icons.settings, size:35), onPressed:(){
            Navigator.pop(context);

          }
          ), 
    
        ]          
        ),        
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
      child: 
      hasData == null ?  Center(child:CircularProgressIndicator()): 
      Center(
        child: Column(children:[
          SizedBox(height:5),

     
    Container(
        width: 400,
        height:220,
        child: Card(
              color: Colors.pink[300],
              clipBehavior: Clip.antiAlias,
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.all(5),
                    child: Row(children: [
                      Expanded(
                        flex: 5,
                        child: InkWell(
                            onTap:optionsDialog,
                            child: Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,  
                                image: DecorationImage(
                                  image:  imageFile != null ? FileImage(File(pickedImagePath)) : profilePic=='default' ? AssetImage('assets/images/defaultAvatar.png') : NetworkImage(widget.userData.profilePic),
                                    //image: widget.userData.profilePic=='default' ? AssetImage('assets/images/defaultAvatar.png'):
                                     // NetworkImage(
                                      //widget.userData.profilePic),
                                      fit: BoxFit.fill),
                                    ),
                          ),
                        ),
                      ),
                      Spacer(
                        flex: 1,
                      ),
                      Expanded(
                        flex: 12,
                        child: Container(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              SizedBox(height:12),
                            TextField( //USERNAME
                                  focusNode: userNameFocus,
                                  keyboardType: TextInputType.text,
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  enabled: true,//userNameEditing,
                                controller: userNameController,
                                style:myStyle(20, Colors.black, FontWeight.w500), 
                                decoration: InputDecoration(
                                hintText: userHint,
                                contentPadding: EdgeInsets.only(top:10),
                                filled: true,
                                fillColor: isEditing ? Colors.grey[100] : Colors.white,
                                //hintText: userName,
                                hintStyle: myStyle(20, Colors.grey, FontWeight.w400),
                                labelStyle: myStyle(10, Colors.black, FontWeight.w600),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)                            
                                  ),
                                  //prefixIcon:  Icon(Icons.person),
                                ),
                                ),                            
                              SizedBox(height:12),
                            TextField(//EMAIL
                                  focusNode: emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  enabled: true,//userNameEditing,
                                controller: emailController,
                                style:myStyle(14, Colors.black, FontWeight.w400), 
                                decoration: InputDecoration(
                                hintText: emailHint,
                                
                                contentPadding: EdgeInsets.only(top:10),
                                filled: true,
                                fillColor: isEditing ? Colors.grey[100] : Colors.white,
                                //hintText: userName,
                                hintStyle: myStyle(20, Colors.grey, FontWeight.w400),
                                labelStyle: myStyle(20, Colors.black, FontWeight.w600),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)                            
                                  ),
                                  //prefixIcon:  Icon(Icons.person),
                                ),
                                ),
                  SizedBox(height:12),
                            TextField(//    AGE
                                  focusNode: ageFocus,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  enabled: true,//userNameEditing,
                                controller: ageController,
                                style:myStyle(24, Colors.black, FontWeight.w400), 
                                decoration: InputDecoration(
                                hintText: ageHint,
                                
                                contentPadding: EdgeInsets.only(top:10),
                                filled: true,
                                fillColor: isEditing ? Colors.grey[100] : Colors.white,
                                //hintText: userName,
                                hintStyle: myStyle(20, Colors.grey, FontWeight.w400),
                                labelStyle: myStyle(20, Colors.black, FontWeight.w600),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)                            
                                  ),
                                  //prefixIcon:  Icon(Icons.person),
                                ),
                                ),                                
                             Spacer(
                        flex: 3,
                      ), 
                          
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
  ),
  SizedBox(height:8), 
Text(languages[selectedLanguage[languageIndex]]['trustedContacts'], style:myStyle(26, Colors.black, FontWeight.w600)),
SizedBox(height:18),
     Expanded(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
          child: ListView(
              children: <Widget>[
              for (var i=0; i<phoneFocusNodes.length;i++)
              Column(
              children:[
              
              Row(
              //mainAxisSize: MainAxisSize.max,
              children:[
              Icon(Icons.phone),
              SizedBox(width:10),  
              Flexible(
                child: TextField(
                focusNode: phoneFocusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                enabled: true,//userNameEditing,
            controller: phoneController[i],
            style:myStyle(24, Colors.black, FontWeight.w600), 
            decoration: InputDecoration(
            contentPadding: EdgeInsets.only(top:10),
            filled: true,
            fillColor: isEditing ? Colors.grey[100] : Colors.white,
            //hintText: userName,
            hintStyle: myStyle(30, Colors.black, FontWeight.w600),
            labelStyle: myStyle(20, Colors.black, FontWeight.w600),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20)                            
                ),
                //prefixIcon:  Icon(Icons.person),
            ),
            ),
              ),
              ],
              ),
              SizedBox(height:18),
              ],
              ),
                 
        ]
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
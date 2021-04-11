import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Expired extends StatefulWidget {
  @override
  _ExpiredState createState() => _ExpiredState();
}

class _ExpiredState extends State<Expired> {

  _launchURL() async {
  const url = 'http://bhaithamen.com/';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}



  @override
  Widget build(BuildContext context) {
    return
    WillPopScope(
        onWillPop: () async {
                return false;
              },
    child: Scaffold(
      
      body:
       
    Center(
      child: Column(
        children:[
          SizedBox(height:40),
          Text('APP EXPIRED | APP EXPIRED', style: myStyle(22),),
          SizedBox(height:20),
                Container(
                      margin: EdgeInsets.symmetric(horizontal:40),
                      height: 140,
                     
                      child:Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset('assets/images/handStop.png'),
                      ),                      
                      color: Colors.red,
                    ), 
           SizedBox(height:20),
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Text(languages[selectedLanguage[languageIndex]]['expiredTextEN'], style: myStyle(14),),
          ),
          Divider(height:3, color: Colors.black, indent: 10, endIndent: 10,),
                   Padding(
            padding: const EdgeInsets.all(22.0),
            child: Text(languages[selectedLanguage[languageIndex]]['expiredTextBN'], style: myStyle(14),),
          ),
              SizedBox(height:6),
              InkWell(
                onTap: ()=>_launchURL(),
                child: Text('www.bhaithamen.com', style: myStyle(20, Colors.blue[700], FontWeight.w500))
                ),           
        ],
      ),
    )
    )
    );
  }
}
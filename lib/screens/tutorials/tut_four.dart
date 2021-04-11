
import 'package:flutter/material.dart';

class TutFour extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children:[
        Container(
          height: MediaQuery.of(context).size.height*0.75,        
        child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Image(
                  image: 
                  AssetImage('assets/images/tut4.png'),
                  fit: BoxFit.cover, // use this
                ),
                  ),
        )
      ],      
    );
  }
}
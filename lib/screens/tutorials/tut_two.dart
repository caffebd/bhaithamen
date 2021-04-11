
import 'package:flutter/material.dart';

class TutTwo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children:[
        Container(
          height: MediaQuery.of(context).size.height*0.75,
          child: new AspectRatio(
              aspectRatio: 9 / 16,
              child: Image(
                image: 
                AssetImage('assets/images/tut2.png'),
                fit: BoxFit.cover, // use this
              ),
          ),
        ),
      ],      
    );
  }
}
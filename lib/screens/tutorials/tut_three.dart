
import 'package:flutter/material.dart';

class TutThree extends StatelessWidget {
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
                  AssetImage('assets/images/tut3.png'),
                  fit: BoxFit.cover, // use this
                ),
                  ),
        )
      ],      
    );
  }
}
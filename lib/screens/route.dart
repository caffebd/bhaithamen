
import 'package:bhaithamen/screens/settings.dart';
import 'package:flutter/material.dart';

class RouteScreen extends StatefulWidget {
  @override
  _RouteScreenState createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(child:
      RaisedButton(
        child: Text('PUSH'),
        onPressed:(){
        Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Settings(),
                    ),
                  ); 
      } )
    );
  }
}
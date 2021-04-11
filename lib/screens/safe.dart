import 'package:bhaithamen/screens/countdown_screen.dart';
import 'package:bhaithamen/screens/welcome.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Safe extends StatefulWidget {
  @override
  _SafeState createState() => _SafeState();
}

class _SafeState extends State<Safe> {
  SafePageIndex safePageIndex;

  List<bool> isSelected = [false, false];
//int page = 0;
  @override
  void initState() {
    super.initState();

    globalContext = context;
  }

  List pageOptions = [
    //RouteScreen(),
    Welcome(),
    //CountPlug(),
    CountDown(),
    //AskMe()
  ];

  @override
  Widget build(BuildContext context) {
    safePageIndex = Provider.of<SafePageIndex>(context);
    if (safePageIndex != null) {
      isSelected = [false, false];
      isSelected[safePageIndex.getSafeIndex] = true;
      if (safePageIndex.getSafeIndex == 0) mapIsShowing = true;
    }
    return safePageIndex == null
        ? Container(child: CircularProgressIndicator())
        : new Column(
            children: <Widget>[
              SizedBox(height: 5),
              Container(child: pageOptions[safePageIndex.getSafeIndex])
            ],
          );
  }
}

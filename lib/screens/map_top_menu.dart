import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

var allIcons = [
  'toilet',
  'pharmacy',
  'shop',
  'doctor',
  'food',
  'beauty',
  'club',
  'gym'
];

class MapTopMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      height: MediaQuery.of(context).size.height * .3,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (var i = 0; i < 4; i++)
                  Column(
                    children: [
                      SizedBox(
                          height: 50,
                          width: 50,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2, right: 2),
                            child: OutlineButton(
                              padding: const EdgeInsets.all(3),
                              child: SvgPicture.asset(
                                  'assets/icons/' + allIcons[i] + '.svg',
                                  color: Colors.white,
                                  semanticsLabel: 'Acme Logo'),
                              splashColor: Colors.white,
                              highlightedBorderColor: Colors.teal,
                              onPressed: () {
                                Navigator.of(context).pop(allIcons[i]);
                              },
                            ),
                          )),
                      Text(
                          languages[selectedLanguage[languageIndex]]
                              [allIcons[i]],
                          style: myStyle(14, Colors.white)),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (var i = 4; i < 8; i++)
                  Column(
                    children: [
                      SizedBox(
                          height: 50,
                          width: 50,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2, right: 2),
                            child: OutlineButton(
                              padding: const EdgeInsets.all(3),
                              child: SvgPicture.asset(
                                  'assets/icons/' + allIcons[i] + '.svg',
                                  color: Colors.white,
                                  semanticsLabel: 'Acme Logo'),
                              splashColor: Colors.white,
                              highlightedBorderColor: Colors.teal,
                              onPressed: () {
                                Navigator.of(context).pop(allIcons[i]);
                              },
                            ),
                          )),
                      Text(
                          languages[selectedLanguage[languageIndex]]
                              [allIcons[i]],
                          style: myStyle(14, Colors.white)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final IconData theIcon;
  final StatefulWidget navigateTo;
  final bool ignoreLink;
  final bool isSettingsPage;

  CustomListTile(this.title, this.theIcon, this.navigateTo, this.ignoreLink,
      this.isSettingsPage);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[400])),
        ),
        child: InkWell(
            splashColor: Colors.blueAccent,
            onTap: () {
              Navigator.of(context).pop();
              if (!isSettingsPage) {
                if (!ignoreLink) Navigator.of(context).pop();
              }

              if (!ignoreLink) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => navigateTo,
                  ),
                );
              }
            },
            child: Container(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(theIcon),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(title, style: myStyle(18)),
                      )
                    ],
                  ),
                  Icon(Icons.arrow_right),
                ],
              ),
            )),
      ),
    );
  }
}

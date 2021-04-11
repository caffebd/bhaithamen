import 'dart:io';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class Secrecy extends StatefulWidget {
  @override
  _SecrecyState createState() => _SecrecyState();
}

class _SecrecyState extends State<Secrecy> {
  final analyticsHelper = AnalyticsService();

  File imageFile;
  String pickedImagePath;

  @override
  void initState() {
    super.initState();

    checkIfImage();
  }

  checkIfImage() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/screen/bhaithamen/';
    final Directory mainOne = new Directory(dirPath);
    print('Checking secret cover');
    mainOne
        .list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) async {
      bool hasIt = await File(entity.path).exists();

      if (hasIt) {
        setState(() {
          imageFile = File(entity.path);
          pickedImagePath = entity.path;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final PinRequired isPinNeeded = Provider.of<PinRequired>(context);
    return WillPopScope(
      onWillPop: () async {
        //await isPinNeeded.setPinRequired(true);
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        body: Container(
          child: new OverflowBox(
            minWidth: 0.0,
            minHeight: 0.0,
            maxHeight: double.infinity,
            child: InkWell(
              onLongPress: () async {
                //await isPinNeeded.setPinRequired(true);
                Navigator.pop(context);
              },
              child: new AspectRatio(
                aspectRatio: 9 / 16,
                child: Image(
                  image: imageFile != null
                      ? FileImage(File(pickedImagePath))
                      : AssetImage('assets/images/defaultSecret.jpg'),
                  fit: BoxFit.cover, // use this
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

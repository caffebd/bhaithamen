import 'dart:io';

import 'package:flutter/material.dart';
import 'package:images_picker/images_picker.dart';

class MyIp extends StatefulWidget {
  @override
  _MyIpState createState() => _MyIpState();
}

class _MyIpState extends State<MyIp> {
  String _platformVersion = 'Unknown';
  String path;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            Text('Running on: $_platformVersion\n'),
            RaisedButton(
              child: Text('pick'),
              onPressed: () async {
                List<Media> res = await ImagesPicker.pick(
                  count: 4,
                  // pickType: PickType.video,
                  cropOpt: CropOption(aspectRatio: CropAspectRatio.wh16x9),
                );
                if (res != null) {
                  setState(() {
                    path = res[0]?.thumbPath;
                  });
                }
              },
            ),
            RaisedButton(
              child: Text('openCamera'),
              onPressed: () async {
                List<Media> res = await ImagesPicker.openCamera();
                if (res != null) {
                  setState(() {
                    path = res[0]?.path;
                  });
                }
              },
            ),
            path != null
                ? Container(
                    height: 200,
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

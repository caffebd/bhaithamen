import 'dart:io';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SelectSecret extends StatefulWidget {
  @override
  _SelectSecretState createState() => _SelectSecretState();
}

class _SelectSecretState extends State<SelectSecret> {
  final analyticsHelper = AnalyticsService();

  String imagePath;
  String feedbackUid;

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
    mainOne
        .list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) async {
      print(entity.path);

      bool hasIt = await File(entity.path).exists();

      if (hasIt) {
        setState(() {
          imageFile = File(entity.path);
          pickedImagePath = entity.path;
        });
      }
    });
  }

  backToDefault() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/screen/bhaithamen/';
    final Directory mainOne = new Directory(dirPath);
    print('Checking secret cover');
    mainOne
        .list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) async {
      print(entity.path);

      bool hasIt = await File(entity.path).exists();

      if (hasIt) {
        File needFile = new File(entity.path);

        needFile.delete();

        // String madeDate = basename(needFile.parent.toString());
        //String id = basename(needFile.path);

        setState(() {
          imageFile = null;
          pickedImagePath = null;
        });
      }
    });
  }

  pickImage(ImageSource source) async {
    appHasStarted = false;

    final ImagePicker _picker = ImagePicker();

    // 2. Use the new method.
    //
    // getImage now returns a PickedFile instead of a File (form dart:io)
    final PickedFile pickedImage = await _picker.getImage(source: source);

    // 3. Check if an image has been picked or take with the camera.
    if (pickedImage == null) {
      //Navigator.pop(context);
      appHasStarted = true;
      needThePin = true;
      return;
    }

    // 4. Create a File from PickedFile so you can save the file locally
    // This is a new/additional step.
    File tmpFile = File(pickedImage.path);

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/screen/bhaithamen/';
    await Directory(dirPath).create(recursive: true);

    // 5. Get the path to the apps directory so we can save the file to it.
    final String fileName =
        basename(pickedImage.path); // Filename without extension
    final String fileExtension = extension(pickedImage.path); // e.g. '.jpg'

    tmpFile = await tmpFile.copy('$dirPath/$fileName$fileExtension');

    setState(() {
      imageFile = File(tmpFile.path);
      pickedImagePath = tmpFile.path;
    });
    //Navigator.pop(context);

    needThePin = true;
    appHasStarted = true;
    analyticsHelper.sendAnalyticsEvent('Custom_Secret_Screen');
    sendResearchReport('Custom_Secret_Screen');
  }

  @override
  Widget build(BuildContext context) {
    final AutoHomePageMapSelect homePageMap =
        Provider.of<AutoHomePageMapSelect>(context);
    final AutoHomePageAskSelect homePageAsk =
        Provider.of<AutoHomePageAskSelect>(context);
    final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    return Scaffold(
      appBar: AppBar(
          title: testModeToggle
              ? Text(languages[selectedLanguage[languageIndex]]['testOn'],
                  style: myStyle(18, Colors.white))
              : Text(languages[selectedLanguage[languageIndex]]['title'],
                  style: myStyle(18, Colors.white)),
          backgroundColor: testModeToggle ? Colors.red : Colors.blue,
          actions: <Widget>[
            //if (homePageMap.shouldGoMap) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){ setState(() {homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);});}),
            if (homePageAsk.shouldGoAsk)
              FlatButton(
                  child: Lottie.asset('assets/lottie/alert.json'),
                  onPressed: () {
                    setState(() {
                      homePageIndex = 2;
                      safePageIndex.setSafePageIndex(0);
                      savedSafeIndex = 0;
                      homePageAsk.setHomePageAsk(false);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    });
                  }),
            if (homePageMap.shouldGoMap)
              FlatButton(
                  child: Lottie.asset('assets/lottie/alert.json'),
                  onPressed: () {
                    setState(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapWrapper(),
                        ),
                      );
                      //homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);
                    });
                  }),
            IconButton(
                icon: Icon(Icons.settings, size: 35),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ]),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    languages[selectedLanguage[languageIndex]]
                        ['secretInstructions'],
                    style: myStyle(20),
                    textAlign: TextAlign.center),
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () {
                  needThePin = false;
                  appHasStarted = false;
                  pickImage(ImageSource.gallery);
                },
                child: Card(
                  color: Colors.blue[300],
                  elevation: 5.0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 300,
                      child: AspectRatio(
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
              SizedBox(height: 15),
              RaisedButton(
                onPressed: backToDefault,
                color: Colors.purple[300],
                child: Text(
                  languages[selectedLanguage[languageIndex]]['useDefault'],
                  style: myStyle(18, Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

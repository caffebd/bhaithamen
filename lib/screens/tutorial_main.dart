import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:dots_indicator/dots_indicator.dart';

class Tutorial extends StatefulWidget {
  @override
  _TutorialState createState() => _TutorialState();
}

class _TutorialState extends State<Tutorial> {
  final controller = PageController(
    initialPage: 0,
  );

  final analyticsHelper = AnalyticsService();

  double currentIndexPage = 0;
  int dots = 3;

  List<bool> isSelected = [true, false, false, false];

  int pageSelect = 0;

  int indexPage1 = 0;
  int indexPage2 = 0;
  int indexPage3 = 0;
  int indexPage4 = 0;

  bool didChange = false;

  List<List<String>> thePages = [
    ['tut1.png', 'tut2.png', 'tut3.png'],
    ['tut1.png', 'tut2.png'],
    ['tut1.png', 'tut2.png', 'tut1.png'],
    ['tut1.png', 'tut3.png'],
  ];

  List<double> keptIndex = [0, 0, 0, 0];

  List<List<Widget>> pages = List<List<Widget>>();

  Widget showTut(String item, BuildContext myContext) {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(myContext).size.height * 0.75,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Image(
              image: AssetImage('assets/images/' + item),
              fit: BoxFit.cover, // use this
            ),
          ),
        )
      ],
    );
  }

  @override
  void didChangeDependencies() {
    pages = [
      //SOS
      [
        showTut('sos/challenge/challenge1.png', context),
        showTut('sos/challenge/challenge2.png', context),
        showTut('sos/challenge/challenge3.png', context),
        showTut('sos/report/report1.png', context),
        showTut('sos/report/report1a.png', context),
        showTut('sos/report/report2.png', context),
        showTut('sos/report/report2a.png', context),
        showTut('sos/report/report2b.png', context),
        showTut('sos/report/report3.png', context),
        showTut('sos/report/report4.png', context),
        showTut('sos/report/report5.png', context),
        showTut('sos/report/report6.png', context),
        showTut('sos/secret/secret1.png', context),
        showTut('sos/secret/secret2.png', context),
        showTut('sos/secret/secret3.png', context),
      ],
      //Home
      [
        showTut('home/tut1.png', context),
        showTut('home/tut2.png', context),
      ],
      //Reminder
      [
        showTut('timer/timer1.png', context),
        showTut('timer/timer2.png', context),
        showTut('timer/timer3.png', context),
        showTut('timer/timer4.png', context),
      ],
      //Settings
      [
        showTut('settings/delete/delete_account.jpg', context),
        showTut('settings/feedback/feedback1.png', context),
        showTut('settings/feedback/feedback2.png', context),
        showTut('settings/feedback/feedback3.png', context),
        showTut('settings/test_lang.png', context),
        showTut('settings/secret_screen.png', context),
        showTut('settings/trusted_contacts.png', context),
        showTut('settings/sign_out.png', context),
      ],
    ];
    dots = pages[0].length;
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    analyticsHelper.testSetCurrentScreen('tutorial_screen');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
              : Text(languages[selectedLanguage[languageIndex]]['instructions'],
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
                    });
                  }),
            IconButton(
                icon: Icon(Icons.arrow_left_sharp, size: 50),
                onPressed: () {
                  controller.animateToPage(
                      currentIndexPage > 0
                          ? currentIndexPage.toInt() - 1
                          : currentIndexPage.toInt(),
                      duration: Duration(milliseconds: 250),
                      curve: Curves.easeIn);
                  keptIndex[pageSelect] = currentIndexPage;
                }),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                  icon: Icon(Icons.arrow_right_sharp, size: 50),
                  onPressed: () {
                    controller.animateToPage(
                        currentIndexPage < pages[pageSelect].length
                            ? currentIndexPage.toInt() + 1
                            : currentIndexPage.toInt(),
                        duration: Duration(milliseconds: 250),
                        curve: Curves.easeIn);
                    keptIndex[pageSelect] = currentIndexPage;
                  }),
            ),
          ]),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.76,
                child: PageView(
                    onPageChanged: (thePage) {
                      if (didChange == false) {
                        setState(() {
                          switch (pageSelect) {
                            case 0:
                              indexPage1 = thePage;
                              break;
                            case 1:
                              indexPage2 = thePage;
                              break;
                            case 2:
                              indexPage3 = thePage;
                              break;
                            case 3:
                              indexPage4 = thePage;
                              break;
                            default:
                          }

                          currentIndexPage = thePage.toDouble();

             
                        });
                      } else {
  
                        setState(() {
                          didChange = true;
                        });
                      }
                    },
                    controller: controller,
                    children: pages[pageSelect]),
              ),
              new DotsIndicator(
                dotsCount: dots,
                position: currentIndexPage,
                decorator: DotsDecorator(
                  color: Colors.black87, // Inactive color
                  activeColor: Colors.redAccent,
                ),
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //buttons across top of screen
                    ToggleButtons(
                      color: Colors.white,
                      selectedColor: Colors.black,
                      fillColor: Colors.blue[600],
                      borderColor: Colors.white,
                      children: <Widget>[
                        isSelected[0]
                            ? Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        4,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.warning_amber_outlined,
                                      size: 16.0,
                                      color: Colors.white,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                      languages[selectedLanguage[languageIndex]]
                                          ['sos'],
                                      style: TextStyle(color: Colors.white),
                                    )
                                  ],
                                ))
                            : Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        4,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.warning_amber_outlined,
                                      size: 16.0,
                                      color: Colors.black,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                      languages[selectedLanguage[languageIndex]]
                                          ['sos'],
                                      style: TextStyle(color: Colors.black),
                                    )
                                  ],
                                )),
                        isSelected[1]
                            ? Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        4,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.home_outlined,
                                      size: 16.0,
                                      color: Colors.white,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['home'],
                                        style: TextStyle(color: Colors.white))
                                  ],
                                ))
                            : Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        4,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.home_outlined,
                                      size: 16.0,
                                      color: Colors.black,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['home'],
                                        style: TextStyle(color: Colors.black))
                                  ],
                                )),
                        isSelected[2]
                            ? Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        4,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.timer,
                                      size: 16.0,
                                      color: Colors.white,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['reminder'],
                                        style: TextStyle(color: Colors.white))
                                  ],
                                ))
                            : Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        4,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.timer,
                                      size: 16.0,
                                      color: Colors.black,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['reminder'],
                                        style: TextStyle(color: Colors.black))
                                  ],
                                )),
                        isSelected[3]
                            ? Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        4,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.settings_outlined,
                                      size: 16.0,
                                      color: Colors.white,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['settings'],
                                        style: TextStyle(color: Colors.white))
                                  ],
                                ))
                            : Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        4,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.settings_outlined,
                                      size: 16.0,
                                      color: Colors.black,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['settings'],
                                        style: TextStyle(color: Colors.black))
                                  ],
                                )),
                      ],
                      onPressed: (int index) {
                        setState(() {
                          //keptIndex[pageSelect] = currentIndexPage;
                          print('curent index pre ' +
                              currentIndexPage.toString());

                          for (int buttonIndex = 0;
                              buttonIndex < isSelected.length;
                              buttonIndex++) {
                            if (buttonIndex == index) {
                              isSelected[buttonIndex] = true;
                            } else {
                              isSelected[buttonIndex] = false;
                            }
                          }

                          pageSelect = index;
                          dots = pages[pageSelect].length;

                          switch (pageSelect) {
                            case 0:
                              currentIndexPage = indexPage1.toDouble();
                              break;
                            case 1:
                              currentIndexPage = indexPage2.toDouble();
                              break;
                            case 2:
                              currentIndexPage = indexPage3.toDouble();
                              break;
                            case 3:
                              currentIndexPage = indexPage4.toDouble();
                              break;
                            default:
                          }

                          controller.jumpToPage(currentIndexPage.toInt());
                        });
                      },
                      isSelected: isSelected,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

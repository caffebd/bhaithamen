import 'dart:io';
import 'package:bhaithamen/data/event.dart';
import 'package:bhaithamen/data/event_date.dart';
import 'package:bhaithamen/data/incident_report.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class ReadReport extends StatefulWidget {
  final IncidentReport reportData;
  final List<EventDay> theEventsList;
  ReadReport(this.reportData, this.theEventsList);
  @override
  _ReadReportState createState() => _ReadReportState();
}

class _ReadReportState extends State<ReadReport> {
  final analyticsHelper = AnalyticsService();
  String uid;
  Stream userStream;
  String userName;
  String email;
  bool profileChanged = false;
  String profilePic = 'default';
  bool hasData = false;
  bool isEditing = false;
  var userNameController = TextEditingController();
  var emailController = TextEditingController();
  List<TextEditingController> phoneController = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];
  //List<TextEditingController>();
  File imageFile;
  String pickedImagePath;
  List<String> phoneNumbers = List<String>();
  List<FocusNode> phoneFocusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode()
  ];

  final AuthService _auth = AuthService();

  dynamic pinProvider;

  List<dynamic> selectedEvents = List<dynamic>();
  List<Event> foundEvents = List<Event>();

  FocusNode userNameFocus;
  FocusNode emailFocus;

  initState() {
    super.initState();
    setUpEventsList();
    analyticsHelper.sendAnalyticsEvent('Read_Report_Viewed');
    analyticsHelper.testSetCurrentScreen('read_report');
    sendResearchReport('Read_Report_Viewed');
  }

  setUpEventsList() {
    print(widget.reportData.incidentDate);

    //formatDate(DateTime.parse(report.eventDate), [d, ' ', MM, ' ', yyyy])

    selectedEvents = widget.theEventsList
        .where((report) =>
            formatDate(
                DateTime.parse(report.eventDate), [d, ' ', MM, ' ', yyyy]) ==
            widget.reportData.incidentDate)
        .toList();

    print(selectedEvents.length.toString());

    //foundEvents = selectedEvents[0].allEvents;

    if (selectedEvents.length > 0) {
      for (var i = 0; i < selectedEvents[0].allEvents.length; i++) {
        if (widget.reportData.attachedEvents
            .contains(selectedEvents[0].allEvents[i].eventId)) {
          foundEvents.add(selectedEvents[0].allEvents[i]);
        }
      }
    }
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
                : Text('Bhai Thamen', style: myStyle(18, Colors.white)),
            backgroundColor: testModeToggle ? Colors.red : Colors.blue,
            actions: <Widget>[
              //if (homePageMap.shouldGoMap) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){ setState(() {homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);Navigator.pop(context);});}),
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
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }),
            ]),
        body: Container(
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Container(
                  width: 400,
                  height: 150,
                  child: Card(
                    color: Colors.blue[600],
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.all(5),
                      child: Row(children: [
                        Expanded(
                          flex: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                  image: AssetImage('assets/images/' +
                                      widget.reportData.type
                                          .replaceAll(' ', '')
                                          .toLowerCase() +
                                      'Icon.png'),
                                  fit: BoxFit.fitWidth),
                            ),
                          ),
                        ),
                        Spacer(
                          flex: 1,
                        ),
                        Expanded(
                          flex: 12,
                          child: Container(
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                SizedBox(height: 2),
                                Text(
                                    languages[selectedLanguage[languageIndex]]
                                        [widget.reportData.type],
                                    style: myStyle(18)),
                                SizedBox(height: 8),
                                Text(
                                    languages[selectedLanguage[languageIndex]]
                                        [widget.reportData.target],
                                    style: myStyle(18)),
                                SizedBox(height: 8),
                                Text(widget.reportData.incidentDate,
                                    style: myStyle(16)),
                                SizedBox(height: 8),
                                Text(
                                    languages[selectedLanguage[languageIndex]]
                                            ['reportId'] +
                                        widget.reportData.reportUid,
                                    style: myStyle(16)),
                                Spacer(
                                  flex: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                          languages[selectedLanguage[languageIndex]]
                              ['incidentLocation'],
                          style: myStyle(20, Colors.black, FontWeight.w600)),
                      SizedBox(height: 8),
                      Text(widget.reportData.location, style: myStyle(20)),
                      SizedBox(height: 14),
                      Divider(
                          thickness: 1,
                          color: Colors.black54,
                          indent: 5,
                          endIndent: 5),
                      Text(
                          languages[selectedLanguage[languageIndex]]
                              ['incidentDescription'],
                          style: myStyle(20, Colors.black, FontWeight.w600)),
                      SizedBox(height: 8),
                      Text(widget.reportData.description, style: myStyle(18)),
                      SizedBox(height: 4),
                      Divider(
                          thickness: 1,
                          color: Colors.black54,
                          indent: 5,
                          endIndent: 5),
                      SizedBox(height: 4),
                      foundEvents.length > 0
                          ? Text(
                              languages[selectedLanguage[languageIndex]]
                                  ['associatedEvents'],
                              style: myStyle(20, Colors.black, FontWeight.w600),
                              textAlign: TextAlign.center)
                          : Text(
                              languages[selectedLanguage[languageIndex]]
                                  ['noAssociatedEvents'],
                              style: myStyle(20, Colors.black, FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                      SizedBox(height: 8),
                    ]),
                SizedBox(height: 8),
                for (var i = 0; i < foundEvents.length; i++)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 1.0, horizontal: 4.0),
                    child: Card(
                      child: ListTile(
                        onTap: () {},
                        tileColor: Colors.grey[300],
                        isThreeLine: true,
                        leading: Image.asset('assets/images/' +
                            foundEvents[i].type +
                            'Icon.png'),
                        title: Text(
                            languages[selectedLanguage[languageIndex]]
                                [foundEvents[i].type],
                            style: myStyle(18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatDate(foundEvents[i].time,
                                [d, ' ', MM, ' ', yy, ' at ', HH, ':', nn])),
                            Text('LAT: ' +
                                foundEvents[i].location.latitude.toString() +
                                ' LONG: ' +
                                foundEvents[i].location.longitude.toString()),
                          ],
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 18),
              ],
            ),
          ),
        ));
  }
}

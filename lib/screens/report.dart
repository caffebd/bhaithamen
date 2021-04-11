import 'dart:math';

import 'package:bhaithamen/data/event.dart';
import 'package:bhaithamen/data/event_date.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:checkdigit/checkdigit.dart';
import 'package:auto_size_text/auto_size_text.dart';

class MakeReport extends StatefulWidget {
  @override
  _MakeReportState createState() => _MakeReportState();
}

class _MakeReportState extends State<MakeReport> {
  final analyticsHelper = AnalyticsService();

  String q1Value;
  String q2Value;
  TextEditingController report = TextEditingController();
  TextEditingController location = TextEditingController();
  DateTime selectedDate;
  String displayDate;
  List<EventDay> allEvents = List<EventDay>();
  List<EventDay> filterEvents;
  List<Event> eventsList = List<Event>();
  UserData userData;
  String searchDate;
  List<String> attachedEvents = List<String>();

  EventDay foundDay;

  String getDate() {
    int year = int.parse(formatDate(selectedDate, [yyyy]));
    int month = int.parse(formatDate(selectedDate, [mm]));
    String fullMonth = formatDate(selectedDate, [MM]);
    int day = int.parse(formatDate(selectedDate, [dd]));

    String gotDate = day.toString() + ' ' + fullMonth + ' ' + year.toString();

    print('today is ' + today.toString());

    searchDate = DateTime(year, month, day).toString();

    return gotDate;
  }

  String getSearchDate() {
    int year = int.parse(formatDate(selectedDate, [yyyy]));
    int month = int.parse(formatDate(selectedDate, [mm]));
    int day = int.parse(formatDate(selectedDate, [dd]));

    searchDate = DateTime(year, month, day).toString();

    return searchDate;
  }

  @override
  void initState() {
    super.initState();
    analyticsHelper.testSetCurrentScreen('write_report_screen');
    globalContext = context;
    if (showMapPopup) {
      mapFlushBar();
    }
    if (showAskPopup) {
      askFlushBar();
    }
    selectedDate = DateTime.now();
    displayDate = getDate();
  }

  String _reportUid() {
    var random = new Random();
    var code = random.nextInt(88888) + 11111;

    int checkDigit = damm.checkDigit(code.toString());
    String reportUid = code.toString() + checkDigit.toString();
    return reportUid;
  }

  _sendTheReport() {
    sendReport(q2Value, location.text, q1Value, displayDate, report.text,
        _reportUid(), attachedEvents, clearForm, userData);
  }

  clearForm() {
    setState(() {
      q1Value = null;
      q2Value = null;
      location.text = '';
      report.text = '';
      displayDate = getDate();
      attachedEvents.clear();
      FocusManager.instance.primaryFocus.unfocus();
    });
  }

  _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // Refer step 1
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
        displayDate = getDate();
        searchDate = getSearchDate();
        filterEvents.clear();
      });
  }

  _buildEventList(String uid) {
    if (!attachedEvents.contains(uid)) {
      attachedEvents.add(uid);
    } else {
      attachedEvents.remove(uid);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    globalContext = context;

    userData = Provider.of<UserData>(context);
    allEvents = Provider.of<List<EventDay>>(context);
    if (allEvents != null) {
      filterEvents =
          allEvents.where((event) => event.eventDate == searchDate).toList();
      foundDay = null;
      filterEvents.forEach((element) {
        foundDay = element;
      });
    }

    return allEvents == null
        ? CircularProgressIndicator()
        : Container(
            height: MediaQuery.of(context).size.height - 210,
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        SizedBox(height: 20),
                        Card(
                          color: Colors.red[400],
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              RaisedButton(
                                elevation: 12,
                                onPressed: () =>
                                    _selectDate(context), // Refer step 3
                                child: AutoSizeText(
                                  languages[selectedLanguage[languageIndex]]
                                      ['incidentDate'],
                                  maxLines: 1,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                color: Colors.white,
                              ),
                              Text(displayDate,
                                  style: myStyle(
                                      18, Colors.black, FontWeight.w600)),
                            ],
                          ),
                        ),
                        Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              //   Text('Type of incident?',style:myStyle(20), textAlign: TextAlign.center,),
                              // SizedBox(height:10),
                              Card(
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                child: InputDecorator(
                                  textAlign: TextAlign.center,
                                  isHovering: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width /
                                                9), // .only(left:50),
                                    //labelStyle: textStyle,
                                    errorStyle: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 16.0),

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                  ),
                                  isEmpty: q2Value == '',
                                  child: DropdownButton(
                                      value: q2Value,
                                      items: [
                                        DropdownMenuItem(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 25,
                                                child: Image.asset(
                                                    'assets/images/harassmentIcon.png'), // Icon(Icons.warning, color: Colors.green,),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                languages[selectedLanguage[
                                                        languageIndex]]
                                                    ['Harassment'],
                                                style: myStyle(18),
                                              ),
                                            ],
                                          ),
                                          value: 'Harassment',
                                        ),
                                        DropdownMenuItem(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 25,
                                                child: Image.asset(
                                                    'assets/images/violenceIcon.png'), // Icon(Icons.warning, color: Colors.green,),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                languages[selectedLanguage[
                                                    languageIndex]]['Violence'],
                                                style: myStyle(18),
                                              ),
                                            ],
                                          ),
                                          value: 'Violence',
                                        ),
                                        DropdownMenuItem(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 25,
                                                child: Image.asset(
                                                    'assets/images/sexualviolenceIcon.png'), // Icon(Icons.warning, color: Colors.green,),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                languages[selectedLanguage[
                                                        languageIndex]]
                                                    ['Sexual Violence'],
                                                style: myStyle(18),
                                              ),
                                            ],
                                          ),
                                          value: 'Sexual Violence',
                                        ),
                                      ],
                                      hint: AutoSizeText(
                                          languages[selectedLanguage[
                                              languageIndex]]['typeOfIncident'],
                                          maxLines: 1,
                                          style: myStyle(20, Colors.black,
                                              FontWeight.w400)),
                                      onChanged: (value1) {
                                        setState(() {
                                          q2Value = value1;
                                        });
                                      }),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(thickness: 3),
                        SizedBox(height: 16),
                        Container(
                          height: 60,
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Card(
                                margin: EdgeInsets.symmetric(horizontal: 12),
                                child: InputDecorator(
                                  textAlign: TextAlign.center,
                                  isHovering: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8), // .only(left:50),
                                    //labelStyle: textStyle,
                                    errorStyle: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 16.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                  ),
                                  isEmpty: q1Value == '',
                                  child: DropdownButton(
                                      value: q1Value,
                                      items: [
                                        DropdownMenuItem(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                color: Colors.black,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                languages[selectedLanguage[
                                                    languageIndex]]['Me'],
                                                style: myStyle(18),
                                              ),
                                            ],
                                          ),
                                          value: 'Me',
                                        ),
                                        DropdownMenuItem(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.people,
                                                color: Colors.black,
                                              ),
                                              SizedBox(width: 6),
                                              AutoSizeText(
                                                languages[selectedLanguage[
                                                        languageIndex]]
                                                    ['Someone else'],
                                                maxLines: 1,
                                                style: myStyle(16),
                                              ),
                                            ],
                                          ),
                                          value: 'Someone else',
                                        ),
                                      ],
                                      hint: AutoSizeText(
                                          languages[selectedLanguage[
                                              languageIndex]]['whoReporting'],
                                          maxLines: 1,
                                          style: myStyle(18, Colors.black,
                                              FontWeight.w400)),
                                      onChanged: (value) {
                                        setState(() {
                                          q1Value = value;
                                        });
                                      }),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Divider(thickness: 3),
                        SizedBox(height: 4),
                        AutoSizeText(
                            languages[selectedLanguage[languageIndex]]['where'],
                            maxLines: 1,
                            style: myStyle(20)),
                        SizedBox(height: 15),
                        Card(
                          child: TextField(
                            controller: location,
                            minLines: 1,
                            maxLines: 2,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText:
                                  languages[selectedLanguage[languageIndex]]
                                      ['location'],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Divider(thickness: 3),
                        SizedBox(height: 4),
                        AutoSizeText(
                            languages[selectedLanguage[languageIndex]]
                                ['describe'],
                            maxLines: 1,
                            style: myStyle(20)),
                        SizedBox(height: 15),
                        Card(
                          child: TextField(
                            controller: report,
                            minLines: 1,
                            maxLines: 8,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText:
                                  languages[selectedLanguage[languageIndex]]
                                      ['description'],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Divider(thickness: 3),
                        SizedBox(height: 8),
                        foundDay != null
                            ? Column(
                                children: [
                                  Card(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    child: AutoSizeText(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['selectActions'],
                                        maxLines: 1,
                                        style: myStyle(20)),
                                  ),
                                  SizedBox(height: 15),
                                  for (var i = 0;
                                      i < foundDay.allEvents.length;
                                      i++)
                                    //for (var i=0; i<eventsList.length; i++)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 3.0, horizontal: 6.0),
                                      child: Card(
                                        child: ListTile(
                                          onTap: () {
                                            _buildEventList(
                                                foundDay.allEvents[i].eventId);
                                          },
                                          tileColor: attachedEvents.contains(
                                                  foundDay.allEvents[i].eventId)
                                              ? Colors.lightGreen
                                              : Colors.grey[300],
                                          //isThreeLine: true,
                                          leading: Image.asset(
                                              'assets/images/' +
                                                  foundDay.allEvents[i].type +
                                                  'Icon.png'),
                                          title: Text(
                                              languages[selectedLanguage[
                                                      languageIndex]]
                                                  [foundDay.allEvents[i].type],
                                              style: myStyle(18, Colors.black,
                                                  FontWeight.w500)),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 7),
                                              Text(
                                                formatDate(
                                                    foundDay.allEvents[i].time,
                                                    [
                                                      d,
                                                      ' ',
                                                      MM,
                                                      ' ',
                                                      yy,
                                                      ' at ',
                                                      HH,
                                                      ':',
                                                      nn
                                                    ]),
                                                style: myStyle(16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                ],
                              )
                            : Card(
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                child: AutoSizeText(
                                  languages[selectedLanguage[languageIndex]]
                                      ['noActions'],
                                  maxLines: 1,
                                  style: myStyle(20, Colors.red[600]),
                                  textAlign: TextAlign.center,
                                )),
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height / 1.7,
                      left: MediaQuery.of(context).size.width - 140),
                  child: FloatingActionButton.extended(
                    onPressed: _sendTheReport,
                    label: Text(languages[selectedLanguage[languageIndex]]
                        ['submitBtn']),
                    icon: Icon(Icons.upload_file),
                  ),
                ),
              ],
            ));
  }
}

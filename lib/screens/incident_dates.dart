import 'package:bhaithamen/data/event_date.dart';
import 'package:bhaithamen/data/incident_date.dart';
import 'package:bhaithamen/screens/incidents_list.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class IncidentDates extends StatefulWidget {
  @override
  _IncidentDatesState createState() => _IncidentDatesState();
}

class _IncidentDatesState extends State<IncidentDates> {

  dynamic gotIncidents;
  dynamic allIncidents;
  dynamic allEvents;

  @override
  Widget build(BuildContext context) {

  final AutoHomePageMapSelect homePageMap = Provider.of<AutoHomePageMapSelect>(context);
  final AutoHomePageAskSelect homePageAsk = Provider.of<AutoHomePageAskSelect>(context); 
  final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    allIncidents = Provider.of<List<IncidentDay>>(context);
    allEvents = Provider.of<List<EventDay>>(context);

    if (allIncidents!=null){
      (allIncidents as List<dynamic>).sort((a, b) => b.incidentDate.compareTo(a.incidentDate));
    }



  return  
 Scaffold(
      appBar: AppBar(
        title: testModeToggle ? Text(languages[selectedLanguage[languageIndex]]['testOn'], style: myStyle(18, Colors.white)): Text(languages[selectedLanguage[languageIndex]]['title'], style: myStyle(18, Colors.white)),  
        backgroundColor: testModeToggle ? Colors.red : Colors.blue,
               actions: <Widget>[
          //if (homePageMap.shouldGoMap) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){ setState(() {homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);});}),
          if (homePageAsk.shouldGoAsk) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){setState(() {homePageIndex = 2; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageAsk.setHomePageAsk(false);});
          Navigator.pop(context);Navigator.pop(context);}),
          if (homePageMap.shouldGoMap)
          FlatButton(
            child: Lottie.asset('assets/lottie/alert.json'),
            onPressed: (){ setState(() {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapWrapper(),
                    ),
                  );              
              //homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);
              });
              }),          
          IconButton(icon: Icon(Icons.settings, size:35), onPressed:(){
          Navigator.pop(context);            
          }
          ),           
 
        ]        
      ),

      body: allIncidents!=null ? 
      ListView.builder(
      itemCount: allIncidents.length,
      itemBuilder: (context, index){
        return Padding(
          padding: EdgeInsets.symmetric(vertical:1.0, horizontal:4.0),
          child: Card(
            child: ListTile(
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IncidentsList(theIncidentsList: allIncidents[index].allIncidents, theEventsList: allEvents,),
                  ),
                );
              },
              title: Text(formatDate(DateTime.parse(allIncidents[index].incidentDate), [d, ' ', MM, ' ', yyyy])),
              //DateTime dateTime = DateTime.parse(dateWithT);
              ),
            ),
          );
      },
      
      ) 
      :Center(child:CircularProgressIndicator())
 );

  }
}
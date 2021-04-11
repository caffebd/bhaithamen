
import 'package:bhaithamen/data/event_date.dart';
import 'package:bhaithamen/data/incident_report.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/screens/read_report.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:checkdigit/checkdigit.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
class IncidentsList extends StatefulWidget {
   final List<EventDay> theEventsList;
  final List<IncidentReport> theIncidentsList;

    const IncidentsList({
    Key key,
    @required this.theIncidentsList,
    @required this.theEventsList,

 })  : super(key: key);
  @override
  _IncidentsListState createState() => _IncidentsListState();
}

class _IncidentsListState extends State<IncidentsList> {

bool checkUid(String uid){
return damm.validate(uid);
 }

  @override
  Widget build(BuildContext context) {
    
  final AutoHomePageMapSelect homePageMap = Provider.of<AutoHomePageMapSelect>(context);
  final AutoHomePageAskSelect homePageAsk = Provider.of<AutoHomePageAskSelect>(context); 
  final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

 
  return Scaffold(
      appBar: AppBar(
        title: testModeToggle ? Text(languages[selectedLanguage[languageIndex]]['testOn'], style: myStyle(18, Colors.white)): Text(languages[selectedLanguage[languageIndex]]['title'], style: myStyle(18, Colors.white)),  
        backgroundColor: testModeToggle ? Colors.red : Colors.blue,
               actions: <Widget>[
         // if (homePageMap.shouldGoMap) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){ setState(() {homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);});}),
          if (homePageAsk.shouldGoAsk) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){setState(() {homePageIndex = 2; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageAsk.setHomePageAsk(false);
          Navigator.pop(context);Navigator.pop(context);Navigator.pop(context);});}),
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
           Navigator.pop(context);            
          }
          ),           
 
        ]          
      ),

      body: widget.theIncidentsList!=null ? 
      ListView.builder(
      itemCount: widget.theIncidentsList.length,
      itemBuilder: (context, index){
        return Padding(
          padding: EdgeInsets.symmetric(vertical:1.0, horizontal:4.0),
          child: Card(      
            child: ListTile(              
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadReport(widget.theIncidentsList[index], widget.theEventsList),
                  ),
                );
              },
              isThreeLine: true,
              leading: checkUid(widget.theIncidentsList[index].reportUid) ? Image.asset('assets/images/'+widget.theIncidentsList[index].type.replaceAll(' ', '').toLowerCase() + 'Icon.png') : Image.asset('assets/images/cross.png'),
              title: Text(languages[selectedLanguage[languageIndex]][widget.theIncidentsList[index].type]
                , style: myStyle(18)),
              subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
              Text('Report ID: '+widget.theIncidentsList[index].reportUid, style: myStyle(14),),  
              SizedBox(height:2),
              Text(widget.theIncidentsList[index].incidentDate),
              
              ],
              ),
           
              ),
            ),
          );
      },
      
      ) 
      :Center(child:CircularProgressIndicator())
 );
}
}

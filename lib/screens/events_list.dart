import 'package:bhaithamen/data/event.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class EventsList extends StatefulWidget {
   final List<Event> theEventsList;
    const EventsList({
    Key key,
    @required this.theEventsList,

 })  : super(key: key);
  @override
  _EventsListState createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {

final analyticsHelper = AnalyticsService();

 @override
  void initState() {
    super.initState();
    analyticsHelper.sendAnalyticsEvent('App_Events_List_Viewed');
    sendResearchReport('App_Events_List_Viewed');
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
          //if (homePageMap.shouldGoMap) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){ setState(() {homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);});}),
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

      body: widget.theEventsList!=null ? 
      ListView.builder(
      itemCount: widget.theEventsList.length,
      itemBuilder: (context, index){
        return Padding(
          padding: EdgeInsets.symmetric(vertical:1.0, horizontal:4.0),
          child: Card(      
            child: ListTile(              
              onTap: (){},
              //isThreeLine: true,    
              leading: Image.asset('assets/images/'+widget.theEventsList[index].type+'Icon.png'),
              title: Text(languages[selectedLanguage[languageIndex]][widget.theEventsList[index].type], style: myStyle(18)),
              subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(formatDate(widget.theEventsList[index].time, [d, ' ', MM, ' ', yy, ' at ', HH, ':', nn]), style: myStyle(16),),

//              Text('LAT: '+theEventsList[index].location.latitude.toString()+' LONG: '+theEventsList[index].location.longitude.toString()),
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

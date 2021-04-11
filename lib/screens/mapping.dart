import 'dart:math';

import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/send_sms.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:bhaithamen/utilities/geofence_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:bhaithamen/utilities/dialog.dart' as util;
import 'package:ocarina/ocarina.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class Mapping extends StatefulWidget {
  @override
  _MappingState createState() => _MappingState();
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

class _MappingState extends State<Mapping> with WidgetsBindingObserver {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool _isMoving;
  //bool _enabled = false;
  String _motionActivity;
  //final player = AudioPlayer();
  final analyticsHelper = AnalyticsService();

  bool showPopup = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController controller;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Map<CircleId, Circle> circles = Map<CircleId, Circle>();
  //Map<CircleId, double> circleSizes = <CircleId, double>{};
  //Map<CircleId, Circle> userCircles = <CircleId, Circle>();
  int _circleIdCounter = 1;
  CircleId selectedCircle;
  LatLng _lastLongPress;
  Circle userPosition;
  double smallCircle = 100; //100.0;
  double largeCircle = 100.0;
  double rad = 100.0;

  Circle highlighter;

  dynamic theUserData;

  bool clickCurrentPos = true;

  AutoHomePageMapSelect homePageMapInstance;

  int timer = 10;

  CircleId selectedId;
  CircleId lastSelectedId;

  //Uint8List imageData;
  Marker highlightMarker;

  bool centreReady = false;

  LatLng startingPosition;
  LatLng trackingPosition;

  double count = 0;
  String geoEvent = 'none';

  bool showCircleControls = false;

  BitmapDescriptor customIcon;

// make sure to initialize before map loading
  OcarinaPlayer player;

  loadLocal() async {
    if (mapPlayer != null) {
      if (mapPlayer.isLoaded()) {
        await mapPlayer.dispose();
      }
    }

    mapPlayer = OcarinaPlayer(
      asset: 'assets/audio/alarm.mp3',
      loop: true,
      volume: 1,
    );

    await mapPlayer.load();
    mapPlayer.play();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    //stateNotification = state;

    switch (state) {
      case AppLifecycleState.paused:
        if (locEnable == false) {
          _onClickEnable(false);
        }
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    analyticsHelper.testSetCurrentScreen('mapping');
    _configureBackgroundGeolocation();
    startingPosition = savedStartLocation;
    mapIsShowing = true;
    globalContext = context;
    rad = largeCircle;
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(12, 12)),
            'assets/images/circleMarker.png')
        .then((d) {
      customIcon = d;
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (locEnable == false) {
      _onClickEnable(false);
    }
    super.dispose();
  }

  void _configureBackgroundGeolocation() async {
    // 1.  Listen to events (See docs for all 13 available events).
    bg.BackgroundGeolocation.onLocation(_onLocation, _onLocationError);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
    bg.BackgroundGeolocation.onActivityChange(_onActivityChange);

    bg.BackgroundGeolocation.onGeofence(_onGeofence);

    bg.BackgroundGeolocation.ready(bg.Config(
            reset:
                true, // <-- lets the Settings screen drive the config rather than re-applying each boot.
            // Convenience option to automatically configure the SDK to post to Transistor Demo server.
            // Logging & Debug
            debug: false,
            logLevel: bg.Config.LOG_LEVEL_VERBOSE,
            // Geolocation options
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 2.0,
            // Activity recognition options
            stopTimeout: 8,
            backgroundPermissionRationale: bg.PermissionRationale(
                title:
                    "Allow {applicationName} to access this device's location even when the app is closed or not in use.",
                message:
                    "This app collects location data to enable recording your trips to work and calculate distance-travelled.",
                positiveAction: 'Change to "{backgroundPermissionOptionLabel}"',
                negativeAction: 'Cancel'),
            // HTTP & Persistence

            // Application options
            stopOnTerminate: false,
            locationAuthorizationRequest: 'Always',
            startOnBoot: true,
            enableHeadless: true,
            heartbeatInterval: 60))
        .then((bg.State state) async {
      print('[ready] ${state.toMap()}');
    }).catchError((error) {
      print('[ready] ERROR: $error');
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    this.controller = controller;
    moveToCurrentLocation();
  }

  moveToCurrentLocation() async {
    // imageData = await getMarker();

    bg.BackgroundGeolocation.getCurrentPosition(
            persist: false, // <-- do not persist this location
            desiredAccuracy: 1, // <-- desire best possible accuracy
            timeout: 30000, // <-- wait 30s before giving up.
            samples: 3 // <-- sample 3 location before selecting best.
            )
        .then((bg.Location location) async {
      print('[getCurrentPosition in fnc] - $location');
      centreReady = true;

      placeExistingCircles();

      setState(() {
        startingPosition =
            LatLng(location.coords.latitude, location.coords.longitude);
        geoEvent = 'Started';
      });
    }).catchError((error) {
      print('[getCurrentPosition in fnc] ERROR: $error');
    });
  }

  void _onLocation(bg.Location location) {
    _positionMarker(location);
  }

  void _onLocationError(bg.LocationError error) {
    print('[${bg.Event.LOCATION}] ERROR - $error');
  }

  checkLocationPermissions() async {
    var locStatus = await Permission.location.status;
    if (locStatus.isUndetermined) {
      // We didn't ask for permission yet.
      if (await Permission.location.request().isGranted) {
        print('cam just granted in cam');
        return true;
        // Either the permission was already granted before or the user just granted it.
      } else {
        return false;
      }
    } else {
      print('was det ret true');
      return true;
    }
  }

  Future<bool> awaitStarted() async {
    return new Future.delayed(const Duration(seconds: 4), () => true);
  }

  void _onClickEnable(enabled) async {
    print('in func ' + enabled.toString());
    appHasStarted = false;
    //prevent pin lock appearing

    //  Duration lockOut = Duration(seconds:6);
    //     Timer(lockOut, () {
    //   appHasStarted=true;
    // });

    bool hasPermission = await checkLocationPermissions();
    if (hasPermission) {
      bg.BackgroundGeolocation.playSound(
          util.Dialog.getSoundId("BUTTON_CLICK"));
      if (enabled) {
        analyticsHelper.sendAnalyticsEvent('Geofence_Start');
        sendResearchReport('Geofence_Start');
        dynamic callback = (bg.State state) async {
          print('[start] success: $state');
          setState(() {
            locEnable = state.enabled;
            _isMoving = state.isMoving;
            geoEvent = state.toString();
          });
          beginPeriodicTimer();
        };
        bg.State state = await bg.BackgroundGeolocation.state;
        if (state.trackingMode == 1) {
          bg.BackgroundGeolocation.start().then(callback);
          appHasStarted = await awaitStarted();
          //showInSnackBar('Tracking is ON');
          setState(() {
            geoEvent = 'bg state ' + state.trackingMode.toString();
            // appHasStarted=true;
          });
        } else {
          //bg.BackgroundGeolocation.startGeofences().then(callback);
        }
      } else {
        dynamic callback = (bg.State state) {
          print('[stop] success: $state');
          setState(() {
            locEnable = state.enabled;
            _isMoving = state.isMoving;
            geoEvent = state.toString();
          });
          cancelPeriodicCheck();
          if (alertTimer != null) {
            if (alertTimer.isActive) alertTimer.cancel();
          }
        };
        bg.BackgroundGeolocation.stop().then(callback);
        analyticsHelper.sendAnalyticsEvent('Geofence_Stop');
        sendResearchReport('Geofence_Stop');
        appHasStarted = await awaitStarted();
        //appHasStarted=true;
        //showInSnackBar('Tracking is off');
        //bg.BackgroundGeolocation.stop().then(callback);
      }
    } else {
      //showInSnackBar('Location permission needed');
    }
  }

  void _onMotionChange(bg.Location location) {
    print('[${bg.Event.MOTIONCHANGE}] - $location');
    setState(() {
      _isMoving = location.isMoving;
      geoEvent = 'motion ' + _isMoving.toString();
    });
  }

  void _onActivityChange(bg.ActivityChangeEvent event) {
    print('[${bg.Event.ACTIVITYCHANGE}] - $event');
    setState(() {
      _motionActivity = event.activity;
    });
  }

  void _onGeofence(bg.GeofenceEvent event) async {
    bg.Logger.info('[onGeofence] Flutter received onGeofence event $event');
    print('GEOFENCE *********' + event.action);

    if (event.action == 'EXIT') {
      lastGeoEvent = 'EXIT';
      beginPeriodicTimer();
    }
    if (event.action == 'ENTER') {
      lastGeoEvent = 'ENTER';
    }

    setState(() {});

    //showInSnackBar('GEO is'+event.action);
  }

  void _remove(CircleId toRemove, bool removeMarker, bool playSound) {
    removeACircle(toRemove.value, playSound);
    print('to remove circle' + toRemove.value);
    setState(() {
      if (circles.containsKey(toRemove)) {
        circles.remove(toRemove);
        //removeACircle(toRemove.toString(), playSound);
        analyticsHelper.sendAnalyticsEvent('Geofence_remove_circle');
        sendResearchReport('Geofence_remove_circle');
      }
      //selectedCircle = null;
    });

    if (removeMarker) {
      if (lastSelectedId != null) {
        print('del marker in all');
        lastSelectedId = CircleId('none');
        setState(() {
          showCircleControls = false;
          markers.remove(MarkerId("RANDOM_ID"));
        });
        return;
      }
    }
  }

  placeExistingCircles() async {
    List<bg.Geofence> geofences = await bg.BackgroundGeolocation.geofences;
    print('this many fences ' + geofences.length.toString());

    for (var fence in geofences) {
      print('fence lat ' + fence.latitude.toString());
      print('fence lat ' + fence.longitude.toString());

      _add(LatLng(fence.latitude, fence.longitude), true, fence.identifier,
          fence.radius);
    }
  }

  void _removeAll() {
    removeAllCircles();
    setState(() {
      circles.clear();
    });
    if (lastSelectedId != null) {
      print('del marker in all');
      lastSelectedId = CircleId('none');
      setState(() {
        circles.remove(CircleId('highlighter'));
        showCircleControls = false;
        markers.remove(MarkerId("RANDOM_ID"));
      });
      return;
    }

    //removeAllGeofences();
  }

  _positionMarker(bg.Location newPos) {
    LatLng currentPosition =
        LatLng(newPos.coords.latitude, newPos.coords.longitude);

    savedStartLocation = currentPosition;

    //     if (mapIsShowing){
    //       controller.moveCamera(
    //         CameraUpdate.newCameraPosition(
    //           CameraPosition(
    //             bearing: 270.0,
    //             target: LatLng(newPos.coords.latitude, newPos.coords.longitude),
    //             tilt: 0.0,
    //             zoom: 16.0,
    //           ),
    //         ),
    //   );
    // }

    // this.setState(() {
    //   marker = Marker(
    //       markerId: MarkerId("home"),
    //       position: currentPosition,
    //       rotation: newPos.coords.heading,
    //       draggable: false,
    //       zIndex: 2,
    //       flat: true,
    //       anchor: Offset(0.5, 0.5),
    //       icon: BitmapDescriptor.fromBytes(imageData));

    //       count = newPos.coords.heading;
    //       geoEvent = 'pos move';
    // });
  }

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  void _add(LatLng placeHere, bool auto, String origId, double setRadius) {
    CircleId circleId;

    if (!auto) {
      final int circleCount = circles.length;
      print('adding circle');
      if (circleCount >= 300) {
        geoLimitFlushBarShow();
        return;
      }

      String randomId = getRandomString(8);
      while (circles.containsKey(randomId)) {
        randomId = getRandomString(8);
      }

      print('circles  id' + randomId);
      circleId = CircleId(randomId);
    } else {
      circleId = CircleId(origId);
    }

    Circle circle = Circle(
      circleId: circleId,
      consumeTapEvents: true,
      strokeColor: Colors.blue,
      fillColor: Colors.green,
      strokeWidth: 5,
      center: placeHere,
      radius: setRadius,
      onTap: () {
        //selectedId = circleId;
        highlightCircle(circleId);
        //_onCircleTapped(circleId);
      },
    );

    print('add new ' + selectedId.toString() + '  ' + circleId.toString());

    print('circle made with ' + circleId.toString());
    //print ('circle '+_createCenter().latitude.toString()+'  '+_createCenter().longitude.toString()+'  '+rad.toString());

    setState(() {
      circles[circleId] = circle;
    });

    print('got main part? ' + circleId.value);

    if (!auto) {
      addGeofenceMarker(_createCenter(), circleId.value, setRadius);
      analyticsHelper.sendAnalyticsEvent('Geofence_add_circle');
      sendResearchReport('Geofence_add_circle');
    }
  }

  highlightCircle(CircleId myId) {
    selectedId = myId;
    if (myId.value == 'void') {
      print('in void');
      selectedId = lastSelectedId;
    }
    print('in highlgith -' + selectedId.toString());

    //if (highlighter!=null)highlighter=null;
    if (lastSelectedId != null) {
      if (lastSelectedId == selectedId) {
        print('in high last sel match');
        lastSelectedId = CircleId('none');

        setState(() {
          markers.remove(MarkerId("RANDOM_ID"));
        });
        return;
      }
    }

    LatLng placeHere;
    double setRadius;

    print(
        'in high ' + lastSelectedId.toString() + '  ' + selectedId.toString());

    lastSelectedId = selectedId;

    circles.entries.forEach((element) {
      if (element.key == selectedId) {
        placeHere = element.value.center;
        setRadius = element.value.radius;
      }
    });

    setState(() {
      final MarkerId markerId = MarkerId("RANDOM_ID");
      Marker marker = Marker(
        anchor: Offset(0.5, 0.5),
        zIndex: 2,
        flat: true,
        //consumeTapEvents: true,
        markerId: markerId,
        draggable: false,
        //onTap: highlightCircle(CircleId('void')),
        position:
            placeHere, //With this parameter you automatically obtain latitude and longitude
        icon: customIcon,
      );

      markers[markerId] = marker;
      showCircleControls = true;
    });
  }

  resizeCircle(bool increase) {
    print(selectedId);
    LatLng placeHere;
    double setRadius;

    circles.entries.forEach((element) {
      if (element.key == selectedId) {
        placeHere = element.value.center;
        setRadius = element.value.radius;
      }
    });

    if (increase) {
      if (setRadius >= 1000) return;
      setRadius += 50;
    } else {
      if (setRadius <= 100) return;
      setRadius -= 50;
    }

    sendResearchReport('Geofence_circle_size_$setRadius');

    CircleId reAdd = selectedId;
    _remove(selectedId, false, false);

    Circle circle = Circle(
      circleId: reAdd,
      consumeTapEvents: true,
      strokeColor: Colors.blue,
      fillColor: Colors.green,
      strokeWidth: 5,
      center: placeHere,
      radius: setRadius,
      onTap: () {
        // selectedId = reAdd;
        highlightCircle(reAdd);
      },
    );
    setState(() {
      circles[reAdd] = circle;
    });

    addGeofenceMarker(placeHere, reAdd.value, setRadius);
  }
  //selectedCircle = circles[selectedId].circle;
  // print (selectedCircle.value);

  LatLng _createCenter() {
    return _createLatLng(_lastLongPress.latitude, _lastLongPress.longitude);
  }

  LatLng _createLatLng(double lat, double lng) {
    return LatLng(lat, lng);
  }

  void _toggleVisible() {
    final Circle circle = circles[selectedCircle];
    setState(() {
      circles[selectedCircle] = circle.copyWith(
        visibleParam: !circle.visible,
      );
    });
  }

  void resetTimer() {
    print('in reset timer');
    if (alertTimer != null) {
      if (alertTimer.isActive) alertTimer.cancel();
      print('EM timer reset');
    }

    //mapAlarm?.stop();
    if (mapPlayer != null) {
      mapPlayer.stop();
      mapPlayer.dispose();
    }
    Vibration.cancel();
  }

  cancelTimerEvent() {
    print('in cancel map timer');

    if (alertTimer != null) {
      if (alertTimer.isActive) alertTimer.cancel();
    }

    showMapPopup = false;
    homePageMapInstance.setHomePageMap(false);
    savedShouldGoMap = false;

    if (mapPlayer != null) {
      mapPlayer.stop();
      mapPlayer.dispose();
    }
    Vibration.cancel();

    setState(() {});
  }

  cancelTimer() {
    print('in cancel map timer');
    //setState(() {geoEvent='TIMER CANCEL';});
    if (alertTimer != null) {
      if (alertTimer.isActive) alertTimer.cancel();
    }

    if (mapPlayer != null) {
      mapPlayer.stop();
      mapPlayer.dispose();
    }
    Vibration.cancel();

    showMapPopup = false;
    homePageMapInstance.setHomePageMap(false);
    savedShouldGoMap = false;

    _onClickEnable(false);
  }

  void startAlertTimer(int time) async {
    if (alertTimer != null) {
      if (alertTimer.isActive) alertTimer.cancel();
    }

    Duration timeOut = Duration(seconds: time);
    alertTimer = Timer(timeOut, () async {
      print(' SMS EMERGENCY SMS EMERGENCY ***************');
      analyticsHelper.sendAnalyticsEvent('Mapping_SMS_Sent');
      sendResearchReport('Mapping_SMS_Sent');

      if (theUserData != null && !testModeToggle) {
        sendEvent('zone', 'zone');
        if (theUserData.phoneContact.length == 0) {
          _getNumbers();
        } else {
          for (var i = 0; i < theUserData.phoneContact.length; i++) {
            bool done = await sendNewSms(
                theUserData.phoneContact[i], theUserData.userName, i, 'zone');
            print('done $i' + done.toString());
          }
          smsBtnSending();
          sendEvent('sms', 'zones-sms');
        }
      }

      // if (theUserData!=null && !testModeToggle){
      // for (var i=0; i<theUserData.phoneContact.length; i++){
      //   bool done = await sendNewSms (theUserData.phoneContact[i], theUserData.userName, i);
      // print ('done $i'+done.toString());
      // }
      // }
      geoEvent = 'SEND SMS';
      setState(() {});
      beginPeriodicTimer();
    });
  }

  void startNotificationTimer() async {
    print('LOOK HERE ' + stateNotification.index.toString());

    //await player.setAsset('assets/audio/alarm.mp3');
    //player.setLoopMode(LoopMode.one);
    loadLocal();
    Vibration.vibrate(
      pattern: [
        500,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        200,
        500,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        200,
        200,
        200,
        200,
        500,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        200,
        500,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        200,
        200,
        200,
        200,
      ],
    );
    print('FIRE ALERT TIMER');
    startAlertTimer(120);

    // if (stateNotification.index == 2){
    //   //showNotification(resetTimer, 1);
    //   startAlertTimer(45);
    // }else{
    //   //timerDialog();
    //   startAlertTimer(45);
    //   mapFlushBar();
    // }
    homePageMapInstance.setHomePageMap(true);
    savedShouldGoMap = true;

    showMapPopup = true;
    setState(() {
      homePageMapInstance.setHomePageMap(true);
      showMapPopup = true;
    });
  }

  timerDialog() {
    showDialog(
      context: globalContext,
      builder: (context) => AlertDialog(
        content: Text("Notification in active"),
        actions: [
          FlatButton(
            child: Text('Ok'),
            onPressed: () {
              resetTimer();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  beginTimer() {
    //mapAlarm?.stop();
    setState(() {
      geoEvent = 'LEAVE TIMER START';
    });
    if (mapPlayer != null) {
      mapPlayer.stop();
      mapPlayer.dispose();
    }
    if (alertTimer != null) {
      if (alertTimer.isActive) alertTimer.cancel();
    }
  }

  beginPeriodicTimer() {
    setState(() {});

    if (mapPeriodicCheck != null) {
      if (mapPeriodicCheck.isActive) mapPeriodicCheck.cancel();
    }

    if (mapPlayer != null) {
      mapPlayer.stop();
      mapPlayer.dispose();
    }
    if (alertTimer != null) {
      if (alertTimer.isActive) alertTimer.cancel();
    }

    Duration periodicTimeOut = Duration(minutes: 5);
    mapPeriodicCheck = new Timer.periodic(periodicTimeOut, (Timer t) {
      if (lastGeoEvent == 'EXIT') {
        startNotificationTimer();
        mapPeriodicCheck.cancel();
        print('FIRE NOTIF TIMER');
      }
    });
  }

  cancelPeriodicCheck() {
    lastGeoEvent = 'end timer';

    if (mapPeriodicCheck != null) {
      if (mapPeriodicCheck.isActive) mapPeriodicCheck.cancel();
    }

    if (mapPlayer != null) {
      mapPlayer.stop();
      mapPlayer.dispose();
    }
    if (alertTimer != null) {
      if (alertTimer.isActive) alertTimer.cancel();
    }

    setState(() {});

    if (mapPeriodicCheck != null) {
      if (mapPeriodicCheck.isActive) mapPeriodicCheck.cancel();
    }
  }

  void _onClickGetCurrentPosition(BuildContext context) async {
    //beginPeriodicTimer();

    if (clickCurrentPos == true) {
      clickCurrentPos = false;

      print('clicky get pos');

      bg.BackgroundGeolocation.playSound(
          util.Dialog.getSoundId("BUTTON_CLICK"));

      bg.BackgroundGeolocation.getCurrentPosition(
          //persist: true,       // <-- do not persist this location
          desiredAccuracy: 10, // <-- desire an accuracy of 40 meters or less
          maximumAge: 10000, // <-- Up to 10s old is fine.
          timeout: 30, // <-- wait 30s before giving up.
          samples: 3, // <-- sample just 1 location
          extras: {"getCurrentPosition": true}).then((bg.Location location) {
        print('[getCurrentPosition] - $location');
        _positionMarker(location);

        if (mapIsShowing)
          controller.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                bearing: 270.0,
                target:
                    LatLng(location.coords.latitude, location.coords.longitude),
                tilt: 0.0,
                zoom: 16.0,
              ),
            ),
          );
        clickCurrentPos = true;
      }).catchError((error) {
        clickCurrentPos = true;
        print('[getCurrentPosition] ERROR: $error');
      });
    }
  }

  List<String> localNumbers;

  Future<void> _getNumbers() async {
    final SharedPreferences prefs = await _prefs;
    localNumbers = prefs.getStringList('contacts');

    if (localNumbers.length > 0 && !testModeToggle) {
      for (var i = 0; i < localNumbers.length; i++) {
        bool done = await sendNewSms(localNumbers[i], '', i, 'zone');
        print('done $i' + done.toString());
      }

      smsBtnSending();
      sendEvent('sms', 'zones-sms');
    } else {
      smsNoContacts();
    }
  }

  Size screenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  double screenHeight(BuildContext context,
      {double dividedBy = 1, double reducedBy = 0.0}) {
    return (screenSize(context).height - reducedBy) / dividedBy;
  }

  double screenHeightExcludingToolbar(BuildContext context,
      {double dividedBy = 1}) {
    return screenHeight(context,
        dividedBy: dividedBy, reducedBy: kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    globalContext = context;
    homePageMapInstance = Provider.of<AutoHomePageMapSelect>(context);
    final userData = Provider.of<UserData>(context);
    if (userData != null) {
      theUserData = userData;
    }
    return Stack(
      // fit: StackFit.expand,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          //crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Center(
            Container(
              height: screenHeightExcludingToolbar(context, dividedBy: 1.08),
              child: GoogleMap(
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomGesturesEnabled: true,
                initialCameraPosition: CameraPosition(
                  target: startingPosition, //LatLng(24.9094295, 91.8671223),
                  zoom: 15.0,
                ),
                circles: Set<Circle>.of(circles.values),
                markers: Set<Marker>.of(markers.values),
                //markers: Set.of((marker != null) ? [marker] : []),
                onMapCreated: _onMapCreated,
                onLongPress: (LatLng pos) {
                  setState(() {
                    _lastLongPress = pos;
                    _add(pos, false, '', 100);
                  });
                },
              ),
            ),
            // ),
          ],
        ),

        Visibility(
          visible: showCircleControls,
          child: Container(
            margin: EdgeInsets.only(
                top: 10, left: MediaQuery.of(context).size.width - 180),
            width: 65,
            height: 65,
            child: FlatButton(
                onPressed: () => _remove(selectedId, true, true),
                highlightColor: Colors.white,
                child: Image.asset('assets/images/cross.png')),
          ),
        ),
        Visibility(
          visible: showCircleControls,
          child: Container(
            margin: EdgeInsets.only(
                top: 10, left: MediaQuery.of(context).size.width - 120),
            width: 65,
            height: 65,
            child: FlatButton(
                onPressed: () {
                  resizeCircle(false);
                },
                highlightColor: Colors.white,
                child: Image.asset('assets/images/decreaseCircle.png')),
          ),
        ),
        Visibility(
          visible: showCircleControls,
          child: Container(
            margin: EdgeInsets.only(
                top: 10, left: MediaQuery.of(context).size.width - 70),
            width: 65,
            height: 65,
            child: FlatButton(
                onPressed: () {
                  resizeCircle(true);
                },
                highlightColor: Colors.white,
                child: Image.asset('assets/images/increaseCircle.png')),
          ),
        ),

        Container(
          //margin: EdgeInsets.only(top:MediaQuery.of(context).size.height/3, left: 10),
          margin: EdgeInsets.only(top: 50, left: 20),
          width: 65,
          height: 65,
          child: FlatButton(
            onPressed: () {
              setState(() {
                if (locEnable) lastGeoEvent = 'ENTER';
              });
            },
            highlightColor: Colors.white,
            child: lastGeoEvent == 'ENTER'
                ? Icon(Icons.check_box, size: 40, color: Colors.green)
                : lastGeoEvent == 'EXIT'
                    ? Icon(Icons.warning, size: 40, color: Colors.red)
                    : Icon(Icons.timer, size: 40, color: Colors.grey),
          ),
        ),

        Container(
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height / 1.35, left: 10),
          width: 65,
          height: 65,
          child: FlatButton(
              onPressed: () {
                if (centreReady) {
                  _onClickGetCurrentPosition(context);
                }
              },
              highlightColor: Colors.white,
              child: Image.asset('assets/images/mapCentre.png')),
        ),

        Container(
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height / 1.35,
              left: MediaQuery.of(context).size.width / 2 - 38),
          width: 80,
          child: circles.length > 0
              ? FlatButton(
                  onPressed: _removeAll,
                  highlightColor: Colors.white,
                  child: Image.asset('assets/images/deleteAll.png'))
              : null,
        ),

        Container(
          margin: EdgeInsets.only(top: 20, left: 20),
          width: 70,
          height: 30,
          decoration: BoxDecoration(
            color: locEnable ? Colors.white : Colors.white54,
            border: Border.all(
              color: Colors.black87,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Switch(
              activeColor: Colors.green[500],
              inactiveThumbColor: Colors.black54,
              value: locEnable,
              onChanged: _onClickEnable),
        ),

        //for testing

        //        Container(
        //     margin: EdgeInsets.only(top:80, left: 200),
        //     width:220,
        //     height: 120,
        //     decoration: BoxDecoration(
        //       color: Colors.lightGreen,
        //       border: Border.all(
        //     color: Colors.green,
        //     width: 1,
        //   ),
        //   borderRadius: BorderRadius.circular(10),
        // ),

        //     child:
        //     lastGeoEvent==null?Text('null'):
        //     Text(lastGeoEvent),
        //     ),
        //   Container(
        //     margin: EdgeInsets.only(top:20, left: 100),
        //     width:40,
        //     height: 40,
        //     decoration: BoxDecoration(
        //       color: alertTimer==null ?Colors.black : alertTimer.isActive ? Colors.lightGreen : Colors.red,
        //       border: Border.all(
        //     color: Colors.green,
        //     width: 1,
        //   ),
        //   borderRadius: BorderRadius.circular(10),
        // ),

        //     child:
        //     Text(geoEvent),
        //     ),

        Visibility(
          visible: showMapPopup,
          child: Container(
            width: 280,
            height: 240,
            margin: EdgeInsets.only(left: 50, top: 100),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
              color: Colors.white,
              shape: BoxShape.rectangle,
            ),
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 15),
                  Container(
                      margin: EdgeInsets.only(left: 5, right: 5),
                      child: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['leftZone'],
                          style: myStyle(20, Colors.black, FontWeight.w600),
                          textAlign: TextAlign.center)),
                  SizedBox(height: 25),
                  Text(
                      languages[selectedLanguage[languageIndex]]['snoozeAlarm'],
                      style: myStyle(20),
                      textAlign: TextAlign.center),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FlatButton(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: Colors.green,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(20)),
                          onPressed: () {
                            setState(() {
                              showMapPopup = false;
                              homePageMapInstance.setHomePageMap(false);
                              savedShouldGoMap = false;
                            });
                            _onClickEnable(false);
                          },
                          child: Text(
                              languages[selectedLanguage[languageIndex]]
                                  ['stop'],
                              style: myStyle(16))),
                      FlatButton(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: Colors.red,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(20)),
                          onPressed: () {
                            setState(() {
                              showMapPopup = false;
                              homePageMapInstance.setHomePageMap(false);
                              savedShouldGoMap = false;
                            });
                            beginPeriodicTimer();
                          },
                          child: Text(
                              languages[selectedLanguage[languageIndex]]
                                  ['snooze'],
                              style: myStyle(16))),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

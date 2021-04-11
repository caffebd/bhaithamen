import 'package:flutter_background_geolocation/flutter_background_geolocation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:bhaithamen/utilities/dialog.dart' as util;

double _radius = 10.0;
bool _notifyOnEntry = true;
bool _notifyOnExit = true;
bool _notifyOnDwell = true;

int _loiteringDelay = 3000;

void addGeofenceMarker(LatLng center, String id, double rad) {
  bg.BackgroundGeolocation.addGeofence(bg.Geofence(
      identifier: id,
      radius: rad,
      latitude: center.latitude,
      longitude: center.longitude,
      notifyOnEntry: _notifyOnEntry,
      notifyOnExit: _notifyOnExit,
      notifyOnDwell: _notifyOnDwell,
      loiteringDelay: _loiteringDelay,
      extras: {
        'radius': _radius,
        'center': {'latitude': center.latitude, 'longitude': center.longitude}
      } // meta-data for tracker.transistorsoft.com
      )).then((bool success) {
    bg.BackgroundGeolocation.playSound(util.Dialog.getSoundId('ADD_GEOFENCE'));
    print('fence ' +
        center.latitude.toString() +
        '    ' +
        center.longitude.toString() +
        '  ' +
        rad.toString());
  }).catchError((error) {
    print('[addGeofence] ERROR: $error');
  });
}

removeAllGeofences() async {
  List<Geofence> geofences = await BackgroundGeolocation.geofences;
  for (var fence in geofences) {
    bg.BackgroundGeolocation.removeGeofence(fence.identifier)
        .then((bool success) {
      print('[removeGeofence] success');
      bg.BackgroundGeolocation.playSound(util.Dialog.getSoundId('CLOSE'));
    });
  }
}

removeACircle(String id, bool sound) {
  bg.BackgroundGeolocation.removeGeofence(id).then((bool success) {
    print('to remove GEO success ' + id);
    if (sound)
      bg.BackgroundGeolocation.playSound(util.Dialog.getSoundId('CLOSE'));
  });
}

removeAllCircles() {
  bg.BackgroundGeolocation.removeGeofences().then((bool success) {
    print('[removeGeofences] all geofences have been destroyed');
    bg.BackgroundGeolocation.playSound(util.Dialog.getSoundId('CLOSE'));
  });
}

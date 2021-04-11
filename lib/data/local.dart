import 'package:flutter/material.dart';

class LocalAuthNotifier extends ChangeNotifier {

  LocalAuthNotifier(this._localAuth);

  bool _localAuth = false;

  bool get localAuth => _localAuth;

  set localAuth (bool val){
    _localAuth = val;
    notifyListeners();
  }

  setLocalAuthVale(bool val)async{
    _localAuth = val;
    notifyListeners();
  }

}



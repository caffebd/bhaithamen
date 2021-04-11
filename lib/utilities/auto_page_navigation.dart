import 'package:flutter/material.dart';

class AutoHomePageMapSelect extends ChangeNotifier {
  AutoHomePageMapSelect(this._gotoMap);

  bool _gotoMap = false;

  bool get shouldGoMap => _gotoMap;

  set homePageMapSet(bool val) {
    _gotoMap = val;
    notifyListeners();
  }

  setHomePageMap(bool val) async {
    _gotoMap = val;
    notifyListeners();
  }
}

class AutoHomePageAskSelect extends ChangeNotifier {
  AutoHomePageAskSelect(this._gotoAsk);

  bool _gotoAsk = false;

  bool get shouldGoAsk => _gotoAsk;

  set goToAsk(bool val) {
    _gotoAsk = val;
    notifyListeners();
  }

  setHomePageAsk(bool val) async {
    _gotoAsk = val;
    notifyListeners();
  }
}

class AutoHomePageWelfareSelect extends ChangeNotifier {
  AutoHomePageWelfareSelect(this._gotoWelfare);

  bool _gotoWelfare = false;

  bool get shouldGoWelfare => _gotoWelfare;

  set goToWelfare(bool val) {
    _gotoWelfare = val;
    notifyListeners();
  }

  setHomePageWelfare(bool val) async {
    _gotoWelfare = val;
    notifyListeners();
  }
}

class AutoPlaceCategorySelect extends ChangeNotifier {
  AutoPlaceCategorySelect(this._gotoCategory);

  String _gotoCategory = '';

  String get shouldGoCategory => _gotoCategory;

  set goToCategory(String val) {
    _gotoCategory = val;
    notifyListeners();
  }

  setCategory(String val) async {
    _gotoCategory = val;
    notifyListeners();
  }
}

class AutoRating extends ChangeNotifier {
  AutoRating(this._gotoRating);

  double _gotoRating = 0;

  double get shouldGoRating => _gotoRating;

  set goToRating(double val) {
    _gotoRating = val;
    notifyListeners();
  }

  setRating(double val) async {
    _gotoRating = val;
    notifyListeners();
  }
}

class PinRequired extends ChangeNotifier {
  PinRequired(this._gotoChange);

  bool _gotoChange = false;

  bool get getPinRequired => _gotoChange;

  set goToChange(bool val) {
    _gotoChange = val;
    notifyListeners();
  }

  setPinRequired(bool val) async {
    _gotoChange = val;
    notifyListeners();
  }
}

class SafePageIndex extends ChangeNotifier {
  SafePageIndex(this._safeIndex);

  int _safeIndex = 0;

  int get getSafeIndex => _safeIndex;

  set setSafeIndex(int val) {
    _safeIndex = val;
    notifyListeners();
  }

  setSafePageIndex(int val) async {
    _safeIndex = val;
    notifyListeners();
  }
}

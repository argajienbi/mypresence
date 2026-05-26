import 'package:flutter/foundation.dart';

import '../models/app_session.dart';

class AppSessionController extends ChangeNotifier {
  static final AppSessionController instance = AppSessionController._internal();

  AppSessionController._internal();
  factory AppSessionController() => instance;

  AppSession? _session;

  AppSession? get session => _session;
  bool get hasSession => _session != null;

  void setSession(AppSession session) {
    _session = session;
    notifyListeners();
  }

  void clear() {
    _session = null;
    notifyListeners();
  }
}

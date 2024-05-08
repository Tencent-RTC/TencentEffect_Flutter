
import 'package:flutter/foundation.dart';

class TXLog{
  TXLog._instance();

  static void printlog(String log){
    if (kDebugMode) {
      print("${DateTime.now()}   $log");
    }
  }

}
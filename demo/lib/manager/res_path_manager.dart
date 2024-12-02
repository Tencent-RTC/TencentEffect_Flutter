import 'dart:io';

import 'package:tencent_effect_flutter_demo/manager/res_path_manager_android.dart';
import 'package:tencent_effect_flutter_demo/manager/res_path_manager_ios.dart';



abstract class ResPathManager {
  static const String TE_RES_DIR_NAME = "xmagic";


  static const String JSON_RES_MARK_LUT = "light_material/lut/";
  static const String JSON_RES_MARK_MAKEUP = "MotionRes/makeupRes/";
  static const String JSON_RES_MARK_MOTION_2D = "MotionRes/2dMotionRes/";
  static const String JSON_RES_MARK_MOTION_3D = "MotionRes/3dMotionRes/";
  static const String JSON_RES_MARK_MOTION_GESTURE = "MotionRes/handMotionRes/";
  static const String JSON_RES_MARK_MOTION_GAN = "MotionRes/ganMotionRes/";
  static const String JSON_RES_MARK_SEG = "MotionRes/segmentMotionRes/";
  static const String JSON_RES_MARK_LIGHT_MAKEUP = "MotionRes/light_makeup/";

  ///Get the storage path of the resource, which is called when the Beauty SDK is initialized
  Future<String> getResPath();


  ///Get filter resource path
  Future<String> getLutDir();


  ///Get the 2D resource path in the animation
  Future<String> getMotion2dDir();


  ///Get the 3D resource path in the animation
  Future<String> getMotion3dDir();


  ///Get the gesture resource path in the animation
  Future<String> getMotionGestureDir();


  ///Get interesting resource paths in motion effects
  Future<String> getMotionGanDir();


  ///Get the Makeup resource path
  Future<String> getMakeUpDir();

  Future<String> getLightMakeupDir();


  ///Get split resource path
  Future<String> getSegDir();


  static ResPathManager getResManager() {
    if (resPathManager == null) {
      if (Platform.isAndroid) {
        resPathManager = ResPathManagerAndroid();
      } else if (Platform.isIOS) {
        resPathManager = ResPathManagerIos();
      } else {}
      return resPathManager!;
    }else{
      return resPathManager!;
    }
  }

  static ResPathManager? resPathManager;

  ResPathManager._internal();
}

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tencent_effect_flutter_demo/manager/res_path_manager.dart';

class ResPathManagerAndroid implements ResPathManager {
  @override
  Future<String> getLutDir() async {
    return "${await getResPath()}${Platform.pathSeparator}light_material${Platform.pathSeparator}lut${Platform.pathSeparator}";
  }

  @override
  Future<String> getMakeUpDir() async {
    return "${await getResPath()}${Platform.pathSeparator}MotionRes${Platform.pathSeparator}makeupRes${Platform.pathSeparator}";
  }

  @override
  Future<String> getMotion2dDir() async {
    return "${await getResPath()}${Platform.pathSeparator}MotionRes${Platform.pathSeparator}2dMotionRes${Platform.pathSeparator}";
  }

  @override
  Future<String> getMotion3dDir() async {
    return "${await getResPath()}${Platform.pathSeparator}MotionRes${Platform.pathSeparator}3dMotionRes${Platform.pathSeparator}";
  }

  @override
  Future<String> getMotionGanDir() async {
    return "${await getResPath()}${Platform.pathSeparator}MotionRes${Platform.pathSeparator}ganMotionRes${Platform.pathSeparator}";
  }

  @override
  Future<String> getMotionGestureDir() async {
    return "${await getResPath()}${Platform.pathSeparator}MotionRes${Platform.pathSeparator}handMotionRes${Platform.pathSeparator}";
  }

  @override
  Future<String> getLightMakeupDir() async {
    return "${await getResPath()}${Platform.pathSeparator}MotionRes${Platform.pathSeparator}light_makeup${Platform.pathSeparator}";
  }

  @override
  Future<String> getResPath() async {
    Directory directory = await getApplicationSupportDirectory();
    return directory.path +
        Platform.pathSeparator +
        ResPathManager.TE_RES_DIR_NAME;
  }

  @override
  Future<String> getSegDir() async {
    return "${await getResPath()}${Platform.pathSeparator}MotionRes${Platform.pathSeparator}segmentMotionRes${Platform.pathSeparator}";
  }
}

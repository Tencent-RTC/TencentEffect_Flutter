import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tencent_effect_flutter_demo/manager/res_path_manager.dart';

class ResPathManagerIos implements ResPathManager {
  @override
  Future<String> getLutDir() async {
    return "${await getResPath()}${Platform.pathSeparator}lut.bundle${Platform.pathSeparator}";
  }

  @override
  Future<String> getMakeUpDir() async {
    return "${await getResPath()}${Platform.pathSeparator}makeupMotionRes.bundle${Platform.pathSeparator}";
  }

  @override
  Future<String> getMotion2dDir() async {
    return "${await getResPath()}${Platform.pathSeparator}2dMotionRes.bundle${Platform.pathSeparator}";
  }

  @override
  Future<String> getMotion3dDir() async {
    return "${await getResPath()}${Platform.pathSeparator}3dMotionRes.bundle${Platform.pathSeparator}";
  }

  @override
  Future<String> getMotionGanDir() async {
    return "${await getResPath()}${Platform.pathSeparator}ganMotionRes.bundle${Platform.pathSeparator}";
  }

  @override
  Future<String> getMotionGestureDir() async {
    return "${await getResPath()}${Platform.pathSeparator}handMotionRes.bundle${Platform.pathSeparator}";
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
    return "${await getResPath()}${Platform.pathSeparator}segmentMotionRes.bundle${Platform.pathSeparator}";
  }
}

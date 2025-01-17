import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

class TEDeviceOrientation {
  StreamSubscription? _streamSubscription;

  void stop() {
    if (_streamSubscription != null) {
      _streamSubscription!.cancel();
      _streamSubscription = null;
    }
  }

  void start(DeviceOrientationCallBack callBack) {
    if (_streamSubscription != null) {
      return;
    }
    _streamSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        TEDeviceDirection deviceDirection = TEDeviceDirection.portraitUp;
        if (event.x.abs() < 1 && event.y.abs() < 1 && event.z.abs() > 9) {
          deviceDirection = TEDeviceDirection.horizontalUp;
        } else if (event.x.abs() < 1 &&
            event.y.abs() < 1 &&
            event.z.abs() < -9) {
          deviceDirection = TEDeviceDirection.horizontalDown;
        } else if (event.x.abs() > event.y.abs()) {
          deviceDirection = event.x > 0
              ? TEDeviceDirection.landscapeLeft
              : TEDeviceDirection.landscapeRight;
        } else {
          deviceDirection = event.y > 0
              ? TEDeviceDirection.portraitUp
              : TEDeviceDirection.portraitDown;
        }
        callBack.call(deviceDirection);
      },
      onError: (error) {},
      cancelOnError: true,
    );
  }
}

typedef DeviceOrientationCallBack = void Function(TEDeviceDirection direction);


enum TEDeviceDirection {
  portraitUp,
  landscapeRight,
  portraitDown,
  landscapeLeft,
  horizontalUp,
  horizontalDown
}
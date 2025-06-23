import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter/model/xmagic_property.dart';
import 'package:tencent_effect_flutter/utils/Logs.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_video_view.dart';
import 'package:tencent_trtc_cloud/trtc_cloud.dart';
import 'package:tencent_trtc_cloud/tx_device_manager.dart';
import 'package:tencent_trtc_cloud/tx_audio_effect_manager.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_def.dart';
import '../../utils/tool.dart';
import '../config/te_app_config.dart';
import '../config/te_res_config.dart';
import '../manager/beauty_param_manager.dart';
import '../model/te_ui_property.dart';
import '../producer/te_general_data_producer.dart';
import '../producer/te_panel_data_producer.dart';
import '../utils/TEDeviceOrientation.dart';
import '../view/beauty_panel_view.dart';
import 'default_panel_view_callback.dart';

/// Meeting Page
class TRTCPage extends StatefulWidget {
  const TRTCPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TRTCPageState();
}

class TRTCPageState extends State<TRTCPage> with WidgetsBindingObserver {
  static const String TAG = "TrtcCameraPreviewPageState";
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  var userInfo = {}; //Multiplayer video user list

  bool isOpenMic = true; //whether turn on the microphone
  bool isOpenCamera = true; //whether turn on the video
  bool isFrontCamera = true; //front camera
  bool isDoubleTap = false;
  bool isShowingWindow = false;
  int? localViewId;
  String doubleUserId = "";
  String doubleUserIdType = "";

  late TRTCCloud trtcCloud;

  List userList = [];
  List userListLast = [];
  List screenUserList = [];
  int quality = TRTCCloudDef.TRTC_AUDIO_QUALITY_DEFAULT;

  bool _isOpenBeauty = true;
  late TEDeviceOrientation _deviceOrientation;

  final DefaultPanelViewCallBack beautyPanelViewCallBack = DefaultPanelViewCallBack();

  late TEPanelDataProducer panelDataProducer;

  @override
  initState() {
    super.initState();
    _initBeautyParams();
    WidgetsBinding.instance.addObserver(this);

    userInfo['userId'] = "userSetting";
    iniRoom();
    listenerOrientation();
  }


  Future<void> _initBeautyParams() async {
    panelDataProducer = TEGeneralDataProducer();
    panelDataProducer.setPanelDataList(TEResConfig.getConfig().defaultPanelDataList);
    List<TESDKParam>? sdkParams = await BeautyParamManager.getBeautyParam();
    if (sdkParams != null) {
      panelDataProducer.setUsedParams(sdkParams);
    }
  }

  iniRoom() async {
    // Create TRTCCloud singleton
    trtcCloud = (await TRTCCloud.sharedInstance())!;
    initData();
    enableBeauty(_isOpenBeauty);

  }

  TEImageOrientation getTEImageOrientationByDeviceDirection(
      TEDeviceDirection direction) {
    TEImageOrientation orientation = TEImageOrientation.ROTATION_0;
    if (Platform.isAndroid) {
      if (direction == TEDeviceDirection.portraitUp) {
        orientation = TEImageOrientation.ROTATION_0;
      } else if (direction == TEDeviceDirection.portraitDown) {
        orientation = TEImageOrientation.ROTATION_180;
      } else if (direction == TEDeviceDirection.landscapeLeft) {
        orientation = isFrontCamera
            ? TEImageOrientation.ROTATION_270
            : TEImageOrientation.ROTATION_90;
      } else if (direction == TEDeviceDirection.landscapeRight) {
        orientation = isFrontCamera
            ? TEImageOrientation.ROTATION_90
            : TEImageOrientation.ROTATION_270;
      }
    } else if (Platform.isIOS) {
      if (direction == TEDeviceDirection.portraitUp) {
        orientation = TEImageOrientation.ROTATION_0;
      } else if (direction == TEDeviceDirection.portraitDown) {
        orientation = TEImageOrientation.ROTATION_180;
      } else if (direction == TEDeviceDirection.landscapeLeft) {
        orientation = isFrontCamera
            ? TEImageOrientation.ROTATION_90
            : TEImageOrientation.ROTATION_270;
      } else if (direction == TEDeviceDirection.landscapeRight) {
        orientation = isFrontCamera
            ? TEImageOrientation.ROTATION_270
            : TEImageOrientation.ROTATION_90;
      }
    }
    return orientation;
  }

  void listenerOrientation() {
    _deviceOrientation = TEDeviceOrientation();
    _deviceOrientation.start((TEDeviceDirection direction) {
      if (!mounted) return;
      if (_isOpenBeauty) {
        TencentEffectApi.getApi()?.setImageOrientation(getTEImageOrientationByDeviceDirection(direction));
      }
    });
  }

  void _setBeautyListener() {
    TencentEffectApi.getApi()
        ?.setOnCreateXmagicApiErrorListener((errorMsg, code) {
      TXLog.printlog(
          "$TAG method is _setBeautyListener, errorMsg = $errorMsg , code = $code");
    });

    TencentEffectApi.getApi()?.setAIDataListener(XmagicAIDataListenerImp());
    TencentEffectApi.getApi()?.setYTDataListener((data) {
      TXLog.printlog("$TAG method is setYTDataListener ,result data: $data");
    });
    TencentEffectApi.getApi()?.setTipsListener(XmagicTipsListenerImp());
  }

  void _removeBeautyListener() {
    TencentEffectApi.getApi()?.onPause();
    TencentEffectApi.getApi()?.setOnCreateXmagicApiErrorListener(null);
    TencentEffectApi.getApi()?.setAIDataListener(null);
    TencentEffectApi.getApi()?.setYTDataListener(null);
    TencentEffectApi.getApi()?.setTipsListener(null);
  }


  ///true is turn on,false is turn off
  Future<int?> enableBeauty(bool open) async {
    if (!open) {
      BeautyParamManager.saveBeautyParam(
          beautyPanelViewCallBack.getUsedParams());
    } else {
      TencentEffectApi.getApi()!.setEffectMode(TeAppConfig.instance.effectMode);
      // enable gan skin retouch
      TencentEffectApi.getApi()!.setFeatureEnableDisable("ai.skin.retouch.enable", true);
    }
    int? result = await trtcCloud.enableCustomVideoProcess(open);
    beautyPanelViewCallBack.setEnableEffect(open);
    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState
          .resumed: //Switch from the background to the foreground, and the interface is visible
        TencentEffectApi.getApi()?.onResume();
        break;
      case AppLifecycleState.paused: // Interface invisible, background
        TencentEffectApi.getApi()?.onPause();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }



  initData() async {
    if (isOpenCamera) {
      userList.add({
        'userId': userInfo['userId'],
        'type': 'video',
        'visible': true,
        'size': {'width': 0, 'height': 0}
      });
    } else {
      userList.add({
        'userId': userInfo['userId'],
        'type': 'video',
        'visible': false,
        'size': {'width': 0, 'height': 0}
      });
    }
    if (isOpenMic) {
      if (foundation.kIsWeb) {
        Future.delayed(const Duration(seconds: 2), () {
          trtcCloud.startLocalAudio(quality);
        });
      } else {
        await trtcCloud.startLocalAudio(quality);
      }
    }

    screenUserList = MeetingTool.getScreenList(userList);
    setState(() {});
  }

  destroyRoom() {
    trtcCloud.stopLocalPreview();
    TRTCCloud.destroySharedInstance();
  }

  @override
  dispose() async {
    _deviceOrientation.stop();
    destroyRoom();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  Future<bool?> showErrorDialog(errorMsg) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tips"),
          content: Text(errorMsg),
          actions: <Widget>[
            TextButton(
              child: const Text("Confirm"),
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }

  Future<bool?> showExitMeetingConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tips"),
          content: const Text("Are you sure to exit the meeting?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Confirm"),
              onPressed: () async {
                Navigator.of(context).pop();
                await _onBackPress(true);
              },
            ),
          ],
        );
      },
    );
  }

  Widget renderView(item, valueKey, width, height) {
    return TRTCCloudVideoView(
        key: valueKey,
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        viewType: TRTCCloudDef.TRTC_VideoView_TextureView,
        viewMode: TRTCCloudDef.TRTC_VideoView_Model_Virtual,
        onViewCreated: (viewId) async {
          if (item['userId'] == userInfo['userId']) {
            await trtcCloud.startLocalPreview(isFrontCamera, viewId);
            setState(() {
              localViewId = viewId;
            });
          } else {
            trtcCloud.startRemoteView(
                item['userId'],
                item['type'] == 'video'
                    ? TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG
                    : TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SUB,
                viewId);
          }
          item['viewId'] = viewId;
        });
  }

  Widget topSetting() {
    return Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 50.0,
          color: const Color.fromRGBO(200, 200, 200, 0.4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              TextButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue)),
                onPressed: () async {
                  bool? delete = await showExitMeetingConfirmDialog();
                  if (delete != null) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  "Exit Meeting",
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Beauty Switch',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  Switch(
                    value: _isOpenBeauty,
                    onChanged: (value) {
                      setState(() {
                        _isOpenBeauty = value;
                      });
                      enableBeauty(value);
                    },
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  _getProperties(List<XmagicProperty> resultList,
      List<XmagicUIProperty>? uiPropertiesList) {
    if (uiPropertiesList == null) {
      return;
    }
    for (XmagicUIProperty uiProperty in uiPropertiesList) {
      if (uiProperty.xmagicUIPropertyList != null) {
        _getProperties(resultList, uiProperty.xmagicUIPropertyList);
      } else if (uiProperty.property != null && uiProperty.isUsed) {
        resultList.add(uiProperty.property!);
      }
    }
  }

  Widget buildPanelView() {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Flex(
          direction: Axis.horizontal,
          children: [
            Expanded(
              child: BeautyPanelView(beautyPanelViewCallBack, panelDataProducer,
                  key: beautyPanelViewCallBack.globalKey),
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TRTC Page'),
        leading: IconButton(
            onPressed: () => {_onBackPress(true)},
            icon: const Icon(Icons.arrow_back_ios)),
      ),
      key: _scaffoldKey,
      body: WillPopScope(
        onWillPop: () async {
          return await _onBackPress(false);
        },
        child: Stack(
          children: <Widget>[
            ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: screenUserList.length,
                cacheExtent: 0,
                itemBuilder: (BuildContext context, index) {
                  var item = screenUserList[index];
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: const Color.fromRGBO(19, 41, 75, 1),
                    child: Wrap(
                      children: List.generate(
                        item.length,
                        (index) => LayoutBuilder(
                          key: ValueKey(item[index]['userId'] +
                              item[index]['type'] +
                              item[index]['size']['width'].toString()),
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            Size size = MeetingTool.getViewSize(
                                MediaQuery.of(context).size,
                                userList.length,
                                index,
                                item.length);
                            double width = size.width;
                            double height = size.height;
                            if (isDoubleTap) {
                              //Set the width and height of other video rendering to 1, otherwise the video will not be streamed
                              if (item[index]['size']['width'] == 0) {
                                width = 1;
                                height = 1;
                              }
                            }
                            ValueKey valueKey = ValueKey(item[index]['userId'] +
                                item[index]['type'] +
                                (isDoubleTap ? "1" : "0"));
                            if (item[index]['size']['width'] > 0) {
                              width = double.parse(
                                  item[index]['size']['width'].toString());
                              height = double.parse(
                                  item[index]['size']['height'].toString());
                            }
                            return SizedBox(
                              key: valueKey,
                              height: height,
                              width: width,
                              child: renderView(
                                  item[index], valueKey, width, height),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
            topSetting(),
            buildPanelView()
          ],
        ),
      ),
    );
  }

  Future<bool> _onBackPress(bool isBackBtn) async {
    await enableBeauty(false);
    if (isBackBtn) {
      Navigator.pop(context);
    }
    return true;
  }
}

class XmagicAIDataListenerImp extends XmagicAIDataListener {
  @override
  void onBodyDataUpdated(String bodyDataList) {
    var result = json.decode(bodyDataList);
    if (result is List) {
      if (result.isNotEmpty) {
        var points = result[0]['points'];
        if (points is List && points.isNotEmpty) {
          TXLog.printlog("onBodyDataUpdated = ${points.length}");
        }
      }
    }
    TXLog.printlog("onBodyDataUpdated = $bodyDataList   ");
  }

  @override
  void onFaceDataUpdated(String faceDataList) {
    var result = json.decode(faceDataList);
    if (result is List) {
      if (result.isNotEmpty) {
        var points = result[0]['points'];
        if (points is List && points.isNotEmpty) {
          TXLog.printlog("onFaceDataUpdated = ${points.length}");
        }
      }
    }
    TXLog.printlog("onFaceDataUpdated = $faceDataList   ");
  }

  @override
  void onHandDataUpdated(String handDataList) {
    var result = json.decode(handDataList);
    if (result is List) {
      if (result.isNotEmpty) {
        var points = result[0]['points'];
        if (points is List && points.isNotEmpty) {
          TXLog.printlog("onHandDataUpdated = ${points.length}");
        }
      }
    }
    TXLog.printlog("onHandDataUpdated = $handDataList   ");
  }
}

class XmagicTipsListenerImp extends XmagicTipsListener {
  @override
  void tipsNeedHide(String tips, String tipsIcon, int type) {
    TXLog.printlog("tipsNeedHide = $tips   ");
  }

  @override
  void tipsNeedShow(String tips, String tipsIcon, int type, int duration) {
    Fluttertoast.showToast(msg: tips);
  }
}

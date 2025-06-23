import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:live_flutter_plugin/manager/tx_device_manager.dart';
import 'package:live_flutter_plugin/v2_tx_live_code.dart';
import 'package:live_flutter_plugin/v2_tx_live_def.dart';
import 'package:live_flutter_plugin/v2_tx_live_pusher.dart';
import 'package:live_flutter_plugin/widget/v2_tx_live_video_widget.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter/utils/Logs.dart';
import 'package:tencent_effect_flutter_demo/manager/res_path_manager.dart';
import '../../languages/AppLocalizations.dart';
import '../config/te_app_config.dart';
import '../view/beauty_panel_view.dart';
import 'default_panel_view_callback.dart';


/// Live-Camera page
class LivePage extends StatefulWidget {
  const LivePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LivePageState();
  }
}

class _LivePageState extends State<LivePage> with WidgetsBindingObserver {
  static const String TAG = "LiveCameraPushPage";


  /// Resolution
  V2TXLiveVideoResolution _resolution =
      V2TXLiveVideoResolution.v2TXLiveVideoResolution1280x720;


  /// Rotation angle
  V2TXLiveRotation _liveRotation = V2TXLiveRotation.v2TXLiveRotation0;


  /// Camera
  V2TXLiveMirrorType _liveMirrorType =
      V2TXLiveMirrorType.v2TXLiveMirrorTypeAuto;


  /// Audio settings
  TXDeviceManager? _txDeviceManager;


  /// Audio data
  int? _localViewId;
  V2TXLivePusher? _livePusher;

  bool _isOpenBeauty = true;
  bool? _isFrontCamera = true;
  bool _isMute = false;

  bool _isShowSettingView = false;

  final DefaultPanelViewCallBack beautyPanelViewCallBack =
      DefaultPanelViewCallBack();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    initLive();
  }

  @override
  void deactivate() {
    debugPrint("Live-Camera push deactivate");
    TencentEffectApi.getApi()?.onPause();
    enableBeauty(false);
    _livePusher?.stopMicrophone();
    _livePusher?.stopCamera();
    _livePusher?.destroy();
    super.deactivate();
  }

  @override
  dispose() {
    debugPrint("Live-Camera push dispose");
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  initLive() async {
    await initPlatformState();

    _txDeviceManager = _livePusher?.getDeviceManager();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    _livePusher = V2TXLivePusher(V2TXLiveMode.v2TXLiveModeRTMP);
    if (!mounted) return;
    setState(() {
      debugPrint("CreatePusher result is ${_livePusher?.status}");
    });
  }

  _startPreview() async {
    if (_livePusher == null) {
      return;
    }
    await _livePusher?.setRenderMirror(_liveMirrorType);
    var videoEncoderParam = V2TXLiveVideoEncoderParam();
    videoEncoderParam.videoResolution = _resolution;
    videoEncoderParam.videoResolutionMode =
        V2TXLiveVideoResolutionMode.v2TXLiveVideoResolutionModePortrait;
    await _livePusher?.setVideoQuality(videoEncoderParam);


    ///Set default sharpness
    await _livePusher
        ?.setAudioQuality(V2TXLiveAudioQuality.v2TXLiveAudioQualityDefault);

    if (_localViewId != null) {
      var code = await _livePusher?.setRenderViewID(_localViewId!);
      if (code != V2TXLIVE_OK) {
        showErrorDialog("StartPush error： please check remoteView load");
        return;
      }
    }
    var cameraCode = await _livePusher?.startCamera(_isFrontCamera!);
    if (cameraCode == null || cameraCode != V2TXLIVE_OK) {
      debugPrint("cameraCode: $cameraCode");
      showErrorDialog("Camera push error：please check Camera system auth.");
      return;
    }
    await _livePusher?.startMicrophone();

    // Future.delayed(const Duration(seconds: 3), () async {
    //   _isFrontCamera = await _txDeviceManager?.isFrontCamera();
    //   setState(() {});
    // });
    enableBeauty(_isOpenBeauty);
  }


  ///switch camera
  void _switchCamera() async {
    await _txDeviceManager?.switchCamera(_isFrontCamera!);
  }

  void _setBeautyListener() {
    TencentEffectApi.getApi()
        ?.setOnCreateXmagicApiErrorListener((errorMsg, code) {
      TXLog.printlog(
          "create xMagicApi is error:  errorMsg = $errorMsg , code = $code");
    });

    TencentEffectApi.getApi()?.setAIDataListener(XmagicAIDataListenerImp());
    TencentEffectApi.getApi()?.setYTDataListener((data) {
      TXLog.printlog("setYTDataListener  $data");
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
    if (open) {
      TencentEffectApi.getApi()!.setEffectMode(TeAppConfig.instance.effectMode);
      _setBeautyListener();
    } else {
      _removeBeautyListener();
    }


    ///Turn on /off
    int? result = await _livePusher?.enableCustomVideoProcess(open);
    beautyPanelViewCallBack.setEnableEffect(open);
    return result;
  }

  stopPush() async {
    await _livePusher?.stopMicrophone();
    await _livePusher?.stopCamera();
  }

  void setLiveMirrorType(V2TXLiveMirrorType type) async {
    await _livePusher?.setRenderMirror(type);
    setState(() {
      _liveMirrorType = type;
    });
  }

  void setLiveRotation(V2TXLiveRotation rotation) async {
    var code = await _livePusher?.setRenderRotation(rotation);
    debugPrint("setLiveRotation code: $code, rotation: $rotation ");
    if (code == V2TXLIVE_OK) {
      setState(() {
        _liveRotation = rotation;
      });
    } else {
      showErrorDialog("setLiveRotation error: code-$code");
    }
  }

  void setLiveVideoResolution(V2TXLiveVideoResolution resolution) async {
    var videoEncoderParam = V2TXLiveVideoEncoderParam();
    videoEncoderParam.videoResolution = resolution;
    await _livePusher?.setVideoQuality(videoEncoderParam);
    setState(() {
      _resolution = resolution;
    });
  }

  bool _isStartPreview = false;

  Widget renderView() {
    return V2TXLiveVideoWidget(
      onViewCreated: (viewId) async {
        _localViewId = viewId;
        if (_isStartPreview == false) {
          _isStartPreview = true;
          Future.delayed(const Duration(seconds: 1), () {
            _startPreview();
          });
        }
      },
    );
  }


  Future<bool?> showErrorDialog(errorMsg) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Alert"),
          content: Text(errorMsg),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  //create settings view
  Widget buildSettings(BuildContext context) {
    return Container(
      color: Colors.black38,
      child: Column(
        children: [
          TextButton(
              onPressed: () => {onGetDeviceAbilities()},
              child: Text(AppLocalizations.of(context)!.getDemoLiveLabel2!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ))),
          TextButton(
              onPressed: () => {onCheckSupportBeauty()},
              child: Text(AppLocalizations.of(context)!.getDemoLiveLabel3!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ))),
          TextButton(
              onPressed: () => {onCheckDeviceSupport()},
              child: Text(AppLocalizations.of(context)!.getDemoLiveLabel4!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ))),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Text(
                    'ON/OFF Beauty',
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
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  children: [
                    const Text(
                      'Camera',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    Switch(
                      value: _isFrontCamera!,
                      onChanged: (value) {
                        setState(() {
                          _isFrontCamera = value;
                        });
                        _switchCamera();
                      },
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  children: [
                    const Text(
                      'AudioMute',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    Switch(
                      value: _isMute,
                      onChanged: (value) {
                        setState(() {
                          _isMute = value;
                        });
                        TencentEffectApi.getApi()?.setAudioMute(value);
                      },
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LIVE Page'),
        leading: IconButton(
            onPressed: () => {Navigator.pop(context)},
            icon: const Icon(Icons.arrow_back_ios)),
      ),
      body: ConstrainedBox(
        // color: Colors.black12,
        constraints: const BoxConstraints.expand(),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              child: Center(
                child: renderView(),
              ),
              color: Colors.black,
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Column(
                children: [
                  const Text(
                    'Show Setting ',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  Switch(
                    value: _isShowSettingView,
                    onChanged: (value) {
                      setState(() {
                        _isShowSettingView = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Positioned(
                left: 10,
                top: 100,
                child:
                    _isShowSettingView ? buildSettings(context) : Container()),
            buildPanelView()
          ],
        ),
      ),
    );
  }

  ///create beauty panel view
  Widget buildPanelView() {
    return Align(
        child: Flex(
          direction: Axis.horizontal,
          children: [
            Expanded(
              child: BeautyPanelView(beautyPanelViewCallBack, null,
                  key: beautyPanelViewCallBack.globalKey),
            )
          ],
        ),
        alignment: Alignment.bottomCenter);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: //
        break;
      case AppLifecycleState.resumed: //
        TencentEffectApi.getApi()?.onResume();
        break;
      case AppLifecycleState.paused: // 
        TencentEffectApi.getApi()?.onPause();
        break;
      case AppLifecycleState.detached: // 
        break;
    }
  }



  void onGetDeviceAbilities() async {
    Map<String, bool>? deviceAbilities =
        await TencentEffectApi.getApi()?.getDeviceAbilities();
    deviceAbilities?.forEach((key, value) {
      TXLog.printlog(
          "$TAG method is onGetDeviceAbilities ,result data is:  key = $key  , value = $value");
    });
    showTipDialog(json.encode(deviceAbilities));
  }

  void onCheckSupportBeauty() async {
    bool? isSupport = await TencentEffectApi.getApi()?.isSupportBeauty();

    TXLog.printlog(
        "$TAG  method is  onCheckSupportBeauty,result is  $isSupport");
    showTipDialog(" this device is support beauty : $isSupport");
  }


  void onCheckDeviceSupport() async {

    String resPath = "${await ResPathManager.getResManager().getMotion2dDir()}video_diejia_dogmask";
    bool? isSupport= await TencentEffectApi.getApi()?.isDeviceSupportMotion(resPath);
    showTipDialog("resPath is ：$resPath, check result = $isSupport");
  }



  void showTipDialog(String resultMsg) {
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('result'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: Text(resultMsg),
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: resultMsg));
                      Fluttertoast.showToast(msg: 'copy success');
                    },
                  )
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('ok'),
                onPressed: () {
                  disDialog();
                },
              ),
            ],
          );
        });
  }

  void disDialog() {
    Navigator.of(context).pop();
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

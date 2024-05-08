import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter/utils/Logs.dart';
import 'package:tencent_effect_flutter_demo/languages/app_localization_delegate.dart';
import 'package:tencent_effect_flutter_demo/manager/res_path_manager.dart';
import 'package:tencent_effect_flutter_demo/page/live_page.dart';
import 'package:tencent_effect_flutter_demo/page/trtc_page.dart';
import 'package:tencent_effect_flutter_demo/view/progress_dialog.dart';
import 'config/te_res_config.dart';


const String licenseUrl =
    "Please replace it with your license URL.";
const String licenseKey = "Please replace it with your license key";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate, 
          GlobalMaterialLocalizations.delegate,  
          GlobalCupertinoLocalizations.delegate,  
          APPLocalizationDelegate.delegate
        ],
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'en'),
          Locale.fromSubtags(languageCode: 'zh')
        ],
        initialRoute: "/",
        routes: <String, WidgetBuilder>{
          '/homepage': (BuildContext context) => const HomePage(),
          '/page_Live': (BuildContext context) => const LivePage(),
          '/page_TRTC': (BuildContext context) => const TRTCPage(),
        },
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  static const String TAG = "_HomeState";

  @override
  void initState() {
    super.initState();
    initPanelViewConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tencent Effect demo'),
      ),
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextButton(
              onPressed: () => {_onClickLive(context)},
              child: const Text('Live',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ))),
          TextButton(
              onPressed: () => {_onClickTRTC(context)},
              child: const Text('TRTC',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ))),
          // TextButton(
          //     onPressed: () => {_onClickPlayer(context)},
          //     child: const Text('Player',
          //         style: TextStyle(
          //           fontWeight: FontWeight.bold,
          //         ))),
          // TextButton(
          //     onPressed: () => {_onTestPressed(context)},
          //     child: const Text('Test',
          //         style: TextStyle(
          //           fontWeight: FontWeight.bold,
          //         ))),
        ],
      )),
    );
  }

  void _initSettings(InitXmagicCallBack callBack) async {
    _setResourcePath();

    /// Copying the resource only needs to be done once. Once it has been successfully copied in the current version, there is no need to copy it again in future versions.
    if (await isCopiedRes()) {
      callBack.call(true);
      return;
    } else {
      _copyRes(callBack);
    }
  }

  void _setResourcePath() async {
    String resourceDir = await ResPathManager.getResManager().getResPath();
    TXLog.printlog(
        '$TAG method is _initResource ,xmagic resource dir is $resourceDir');
    TencentEffectApi.getApi()?.setResourcePath(resourceDir);
  }

  void _copyRes(InitXmagicCallBack callBack) {
    _showDialog(context);
    TencentEffectApi.getApi()?.initXmagic((result) {
      if (result) {
        saveResCopied();
      }
      _dismissDialog(context);
      callBack.call(result);
      if (!result) {
        Fluttertoast.showToast(msg: "initialization failed");
      }
    });
  }

  void _onClickLive(BuildContext context) {
    _initSettings((result) {
      if (result) {
        TencentEffectApi.getApi()?.setLicense(licenseKey, licenseUrl,
            (errorCode, msg) {
          TXLog.printlog(
              '$TAG  setLicense result : errorCode =$errorCode ,msg = $msg');
          if (errorCode == 0) {
            _requestPermission(context, "/page_Live");
          }
        });
      }
    });
  }



  void _onClickTRTC(BuildContext context) {
    _initSettings((result) {
      if (result) {
        TencentEffectApi.getApi()?.setLicense(licenseKey, licenseUrl,
            (errorCode, msg) {
          TXLog.printlog(
              '$TAG  setLicense result : errorCode =$errorCode ,msg = $msg');
          if (errorCode == 0) {
            _requestPermission(context, "/page_TRTC");
          }
        });
      }
    });
  }

  void _showDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return const ProgressDialog();
        });
  }


  ///dismiss dialog
  _dismissDialog(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  void _requestPermission(BuildContext context, String pageName) async {

    ///request permission
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    if (statuses[Permission.camera] != PermissionStatus.denied &&
        statuses[Permission.microphone] != PermissionStatus.denied) {
      Navigator.of(context).pushNamed(pageName);
    }
  }

  void initPanelViewConfig() {

    TEResConfig.getConfig()
      ..setBeautyRes("assets/beauty_panel/beauty.json")
      ..setBeautyBodyRes("assets/beauty_panel/beauty_body.json")
      ..setLutRes("assets/beauty_panel/lut.json")
      ..setMakeUpRes("assets/beauty_panel/makeup.json")
      ..setMotionRes("assets/beauty_panel/motions.json")
      ..setSegmentationRes("assets/beauty_panel/segmentation.json");
  }

  Future<bool> isCopiedRes() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentAppVersionName = packageInfo.version;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String? versionName = sharedPreferences.getString("app_version_name");
    TXLog.printlog(
        '$TAG method is isCopiedRes ,currentAppVersionName= $currentAppVersionName   versionName ${versionName}');
    return currentAppVersionName == versionName;
  }

  void saveResCopied() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentAppVersionName = packageInfo.version;
    await sharedPreferences.setString(
        "app_version_name", currentAppVersionName);
  }


  _onTestPressed(BuildContext context) async {
    ///Method for testing copied model bundles (Android only)
    // Directory directory = await getApplicationSupportDirectory();
    // String inputDir = directory.path + "${Platform.pathSeparator}temp_bundle";
    // List<String> input = [
    //   "$inputDir${Platform.pathSeparator}Light3DPlugin",
    //   "$inputDir${Platform.pathSeparator}LightCore",
    //   "$inputDir${Platform.pathSeparator}LightHandPlugin"
    // ];
    // String resPath = await BeautyPropertyProducerAndroid().getResPath();
    // TencentEffectApiAndroid apiAndroid = TencentEffectApiAndroid();
    // apiAndroid.addAiMode(input[0], resPath, (inputDir, code) {

    //   apiAndroid.addAiMode(input[1], resPath, (inputDir, code) {

    //     apiAndroid.addAiMode(input[2], resPath, (inputDir, code) {

    //     });
    //   });
    // });

    ///Method for testing dynamically loaded so (Android only)
    // String resPath = await BeautyPropertyProducerAndroid().getResPath();
    // TencentEffectApiAndroid apiAndroid = TencentEffectApiAndroid();
    // bool result =await apiAndroid.setLibPathAndLoad("$resPath${Platform.pathSeparator}templib");
    // TXLog.printlog("$TAG setLibPathAndLoad $result ");
  }
}

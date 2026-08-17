import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter/uikit/config/te_res_config.dart';
import 'package:tencent_effect_flutter/uikit/l10n/te_panel_localizations.dart';
import 'package:tencent_effect_flutter/uikit/manager/te_res_path_manager.dart';
import 'package:tencent_effect_flutter/utils/te_logs.dart';
import 'package:tencent_effect_flutter_demo/config/te_app_config.dart';
import 'package:tencent_effect_flutter_demo/languages/TEPanelLocalizationsZhTW.dart';
import 'package:tencent_effect_flutter_demo/languages/app_localization_delegate.dart';
import 'package:tencent_effect_flutter_demo/page/live_page.dart';
import 'package:tencent_effect_flutter_demo/page/trtc_page.dart';
import 'package:tencent_effect_flutter_demo/view/progress_dialog.dart';
import 'languages/AppLocalizations.dart';

const String licenseUrl =
    "please set your license url";
const String licenseKey = "please set your license key";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        localizationsDelegates: const [
          TEPanelLocalizationsZhTWDelegate(),
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          APPLocalizationDelegate.delegate,
          TEPanelLocalizations.delegate
        ],
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'en'),
          Locale.fromSubtags(languageCode: 'zh'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
          Locale.fromSubtags(languageCode: 'zh', countryCode: 'HK'),
          Locale.fromSubtags(languageCode: 'zh', countryCode: 'MO'),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MaterialButton(
              onPressed: () => {_onClickLive(context)},
              color: Colors.blue,
              textColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: const Text('Live',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ))),
          MaterialButton(
              onPressed: () => {_onClickTRTC(context)},
              color: Colors.blue,
              textColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: const Text('TRTC',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  "Effect Mode : ",
                ),
                Expanded(
                    child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Radio(
                        value: EffectMode.NORMAL,
                        onChanged: (value) {
                          setState(() {
                            TeAppConfig.instance.effectMode = value! as EffectMode;
                          });
                        },
                        groupValue: TeAppConfig.instance.effectMode,
                      ),
                      const Text("Normal"),
                      Radio(
                        value: EffectMode.PRO,
                        onChanged: (value) {
                          setState(() {
                            TeAppConfig.instance.effectMode = value! as EffectMode;
                          });
                        },
                        groupValue: TeAppConfig.instance.effectMode,
                      ),
                      const Text("Pro"),
                    ],
                  ),
                ))
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    Text(AppLocalizations.of(context)?.getEffectModeDes ?? "", style: const TextStyle(fontSize: 16.0)),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _initSettings(InitXmagicCallBack callBack) async {
    String resourceDir = await TEResPathManager.getResManager().getResPath();
    TXLog.printlog('$TAG method is _initResource ,xmagic resource dir is $resourceDir');
    TencentEffectApi.getApi()?.setResourcePath(resourceDir);

    /// Copying the resource only needs to be done once. Once it has been successfully copied in the current version, there is no need to copy it again in future versions.
    if (await isCopiedRes()) {
      callBack.call(true);
      return;
    } else {
      _copyRes(callBack);
    }
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
        TencentEffectApi.getApi()?.setLicense(licenseKey, licenseUrl, (errorCode, msg) {
          TXLog.printlog('$TAG  setLicense result : errorCode =$errorCode ,msg = $msg');
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
        TencentEffectApi.getApi()?.setLicense(licenseKey, licenseUrl, (errorCode, msg) {
          TXLog.printlog('$TAG  setLicense result : errorCode =$errorCode ,msg = $msg');
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
      TencentEffectApi.getApi()!.setEffectMode(TeAppConfig.instance.effectMode);
      Navigator.of(context).pushNamed(pageName);
    }
  }

  void initPanelViewConfig() {
    String panelDir = "assets/beauty_panel/";
    String jsonFileSuffix =".json";
    TEResConfig.getConfig().defaultPanelDataList.clear();

    //这里是多语言适配的示例代码，判断出当前语言环境，加载对应语言的json文件，面板中默认的json中只支持简体中文和英文，如果现在需要支持繁体中文，咱们就可以这样操作
    //在beauty_panel下创建一个zt_hant 的文件夹，然后复制现有的json文件到此目录，然后将disPlayName的值修改为繁体中文，在需要使用的时候加载这个json文件即可。
    // 注意：这里只是对面板json文件的多语言适配，还有库中使用的文字适配可以参考 demo/lib/languages/TEPanelLocalizationsZhTW.dart 文件
    // 多语言实现可参考：tencent-effect-flutter/docs/MULTI_LANGUAGE_GUIDE_.md


    // 判断当前设备语言环境是否为繁体中文
    Locale currentLocale = PlatformDispatcher.instance.locale;
    bool isTraditionalChinese = currentLocale.languageCode == 'zh' &&
        (currentLocale.countryCode == 'TW' ||
            currentLocale.countryCode == 'HK' ||
            currentLocale.countryCode == 'MO' ||
            currentLocale.scriptCode == 'Hant');
    if (isTraditionalChinese) {
      panelDir = "assets/beauty_panel/zh_hant/";
      jsonFileSuffix = "_zh_hant.json";
    }

    TEResConfig.getConfig()
      ..setBeautyTemplateRes("${panelDir}beauty_template${jsonFileSuffix}")
      ..setBeautyRes("${panelDir}beauty${jsonFileSuffix}")
      ..setBeautyRes("${panelDir}beauty_image${jsonFileSuffix}")
      ..setBeautyRes("${panelDir}beauty_makeup${jsonFileSuffix}")
      ..setBeautyRes("${panelDir}beauty_shape${jsonFileSuffix}")
      ..setBeautyBodyRes("${panelDir}beauty_body${jsonFileSuffix}")
      ..setLutRes("${panelDir}lut${jsonFileSuffix}")
      ..setLightMakeupRes("${panelDir}light_makeup${jsonFileSuffix}")
      ..setMakeUpRes("${panelDir}makeup${jsonFileSuffix}")
      ..setMotionRes("${panelDir}motion_2d${jsonFileSuffix}")
      ..setMotionRes("${panelDir}motion_3d${jsonFileSuffix}")
      ..setMotionRes("${panelDir}motion_gesture${jsonFileSuffix}")
      ..setSegmentationRes("${panelDir}segmentation${jsonFileSuffix}");
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
    await sharedPreferences.setString("app_version_name", currentAppVersionName);
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

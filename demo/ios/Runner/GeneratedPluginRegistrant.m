//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<fluttertoast/FluttertoastPlugin.h>)
#import <fluttertoast/FluttertoastPlugin.h>
#else
@import fluttertoast;
#endif

#if __has_include(<image_picker_ios/FLTImagePickerPlugin.h>)
#import <image_picker_ios/FLTImagePickerPlugin.h>
#else
@import image_picker_ios;
#endif

#if __has_include(<live_flutter_plugin/TencentLiveCloudPlugin.h>)
#import <live_flutter_plugin/TencentLiveCloudPlugin.h>
#else
@import live_flutter_plugin;
#endif

#if __has_include(<orientation/OrientationPlugin.h>)
#import <orientation/OrientationPlugin.h>
#else
@import orientation;
#endif

#if __has_include(<package_info_plus/FLTPackageInfoPlusPlugin.h>)
#import <package_info_plus/FLTPackageInfoPlusPlugin.h>
#else
@import package_info_plus;
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

#if __has_include(<tencent_effect_flutter/TencentEffectFlutterPlugin.h>)
#import <tencent_effect_flutter/TencentEffectFlutterPlugin.h>
#else
@import tencent_effect_flutter;
#endif

#if __has_include(<tencent_trtc_cloud/TencentTRTCCloud.h>)
#import <tencent_trtc_cloud/TencentTRTCCloud.h>
#else
@import tencent_trtc_cloud;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FluttertoastPlugin registerWithRegistrar:[registry registrarForPlugin:@"FluttertoastPlugin"]];
  [FLTImagePickerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTImagePickerPlugin"]];
  [TencentLiveCloudPlugin registerWithRegistrar:[registry registrarForPlugin:@"TencentLiveCloudPlugin"]];
  [OrientationPlugin registerWithRegistrar:[registry registrarForPlugin:@"OrientationPlugin"]];
  [FLTPackageInfoPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTPackageInfoPlusPlugin"]];
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  [TencentEffectFlutterPlugin registerWithRegistrar:[registry registrarForPlugin:@"TencentEffectFlutterPlugin"]];
  [TencentTRTCCloud registerWithRegistrar:[registry registrarForPlugin:@"TencentTRTCCloud"]];
}

@end

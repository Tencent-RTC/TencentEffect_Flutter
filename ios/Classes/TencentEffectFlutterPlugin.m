//
//  TencentEffectFlutterPlugin.m
//  tencent_effect_flutter
//
//  Created by tao yue on 2022/6/12.
//  Copyright (c) 2020 Tencent. All rights reserved.

#import "TencentEffectFlutterPlugin.h"
#import "XmagicApiManager.h"

@interface TencentEffectFlutterPlugin() <FlutterStreamHandler>
 
@property (nonatomic, strong) FlutterEventSink eventSink;
@property (nonatomic, assign) BOOL enableAIDataListener;
@property (nonatomic, assign) BOOL enableTipsListener;
@property (nonatomic, assign) BOOL enableYTDataListener;
 
@end

@implementation TencentEffectFlutterPlugin

static TencentEffectFlutterPlugin* _instance = nil;

+ (TencentEffectFlutterPlugin *)shareInstance {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init] ;
    }) ;
    return _instance ;
}
 
+(id) allocWithZone:(struct _NSZone *)zone {
    
    return [TencentEffectFlutterPlugin shareInstance] ;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"tencent_effect_methodChannel_call_native"
            binaryMessenger:[registrar messenger]];
  TencentEffectFlutterPlugin* instance = [[TencentEffectFlutterPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    
  FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:@"tencent_effect_methodChannel_call_flutter" binaryMessenger:[registrar messenger]];
  [eventChannel setStreamHandler:instance];

}


- (instancetype)init {
    self = [super init];
    if (self) {
        // 在构造函数初始化时，直接调用设置回调的方法
        [self setDataCallBack];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else if ([@"initXmagic" isEqualToString:call.method]) {
      result(nil);
      [self initXmagic];
  }else if ([@"isSupportBeauty" isEqualToString:call.method]) {
      result(@true);
  }else if ([@"setLicense" isEqualToString:call.method]) {
      result(nil);
      NSString *licenseKey = call.arguments[@"licenseKey"];
      NSString *licenseUrl = call.arguments[@"licenseUrl"];
      [self setLicense:licenseKey licenseUrl:licenseUrl];
  }else if ([@"setXmagicLogLevel" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] setXmagicLogLevel:[call.arguments intValue]];
      result(nil);
  }else if ([@"updateProperty" isEqualToString:call.method]) {
      result(nil);
      [[XmagicApiManager shareSingleton] updateProperty:call.arguments];
  }else if ([@"onPause" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] onPause];
      result(nil);
  }else if ([@"onResume" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] onResume];
      result(nil);
  }else if ([@"onDestroy" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] onDestroy];
      result(nil);
  }else if ([@"isBeautyAuthorized" isEqualToString:call.method]) {
      NSString *res = [[XmagicApiManager shareSingleton] isBeautyAuthorized:call.arguments];
      result(res);
  }else if ([@"isDeviceSupport" isEqualToString:call.method]) {
      NSString *res = [self isDeviceSupport:call.arguments];
      result(res);
  }else if ([@"getPropertyRequiredAbilities" isEqualToString:call.method]) {
      result(nil);
  }else if ([@"getDeviceAbilities" isEqualToString:call.method]) {
      result(nil);
  }else if ([@"enableEnhancedMode" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] enableEnhancedMode];
      result(nil);
  }else if ([@"setDowngradePerformance" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] setDowngradePerformance];
      result(nil);
  }else if ([@"enableHighPerformance" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] setDowngradePerformance];
      result(nil);
  }else if ([@"getDeviceLevel" isEqualToString:call.method]) {
      int level = [[XmagicApiManager shareSingleton] getDeviceLevel];
      result(@(level));
  }else if([@"setEffectMode" isEqualToString:call.method]) {
      if([call.arguments isKindOfClass:[NSString class]]) {
          NSString *modeType = (NSString *)call.arguments;
          [[XmagicApiManager shareSingleton] setTeEffectMode:modeType];
      }
      result(nil);
          
  }else if ([@"setAudioMute" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] setAudioMute:call.arguments];
      result(nil);
  }else if ([@"setFeatureEnableDisable" isEqualToString:call.method]) {
      if([call.arguments isKindOfClass:[NSDictionary class]]){
          [self setFeatureEnableDisable:(NSDictionary *)call.arguments];
      }
      result(nil);
  }else if ([@"setImageOrientation" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] setImageOrientation:[call.arguments intValue]];
      result(nil);
  }else if ([@"isDeviceSupportMotion" isEqualToString:call.method]) {
      result(@true);
  }else if ([@"setResourcePath" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] setResourcePath:call.arguments[@"pathDir"]];
      result(nil);
  }else if ([@"setEffect" isEqualToString:call.method]) {
      [[XmagicApiManager shareSingleton] setEffect:call.arguments];
      result(nil);
  }else if ([@"enableAIDataListener" isEqualToString:call.method]) {
      self.enableAIDataListener = [call.arguments boolValue];
      result(nil);
  }else if ([@"enableTipsListener" isEqualToString:call.method]) {
      self.enableTipsListener = [call.arguments boolValue];
      result(nil);
  }else if ([@"enableYTDataListener" isEqualToString:call.method]) {
      self.enableYTDataListener = [call.arguments boolValue];
      result(nil);
  }else if ([@"setSyncMode" isEqualToString:call.method]) {
      if ([call.arguments isKindOfClass:[NSDictionary class]]) {
          NSDictionary *params = (NSDictionary *)call.arguments;
          BOOL isSync = [params[@"isSync"] boolValue];
          int syncFrameCount = [params[@"syncFrameCount"] intValue];
          [[XmagicApiManager shareSingleton] setSyncMode:isSync syncFrameCount:syncFrameCount];
      }
      result(nil);
  }else if ([@"setBeautyProcessPaused" isEqualToString:call.method]) {
      if ([call.arguments isKindOfClass:[NSDictionary class]]) {
          NSDictionary *params = (NSDictionary *)call.arguments;
          BOOL beautyProcessPaused = [params[@"beautyProcessPaused"] boolValue];
          [[XmagicApiManager shareSingleton] setBeautyProcessPaused:beautyProcessPaused];
      }
      result(nil);
  }else if ([@"setOutputTextureKeepRatio" isEqualToString:call.method]) {
      if([call.arguments isKindOfClass:[NSNumber class]]) {
          float ratio = [call.arguments floatValue];
          [[XmagicApiManager shareSingleton] setOutputTextureKeepRatio:ratio];
      }
      result(nil);
  }else {
    result(FlutterMethodNotImplemented);
  }
}

-(void)setFeatureEnableDisable:(NSDictionary *)dic{
    NSArray *featureNames = [dic allKeys];
    for (NSString *featureName in featureNames) {
        BOOL enable = [[dic valueForKey:featureName] boolValue];
        [[XmagicApiManager shareSingleton] setFeatureEnableDisable:featureName enable:enable];
    }
}

-(void)setLicense:(NSString *)licenseKey licenseUrl:(NSString *)licenseUrl{
    [[XmagicApiManager shareSingleton] setLicense:licenseKey licenseUrl:licenseUrl completion:^(NSInteger authresult, NSString * _Nonnull errorMsg) {
        NSDictionary *data = @{@"code":@(authresult), @"msg":errorMsg};
        NSDictionary *result = @{@"methodName":@"onLicenseCheckFinish", @"data":data};
        [self eventSinkData:result];
    }];
}

-(void)initXmagic{
    [[XmagicApiManager shareSingleton] initXmagicRes:^(bool success) {
        NSDictionary *result;
        if (success) {
            result = @{@"methodName":@"initXmagic", @"data":@true};
        }else{
            result = @{@"methodName":@"initXmagic", @"data":@false};
        }
        [self eventSinkData:result];
    }];
}

-(void)eventSinkData:(NSDictionary *)result{
    if (self.eventSink){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.eventSink(result);
        });
    }
}

-(void)setDataCallBack{
    [XmagicApiManager shareSingleton].eventAICallBlock = ^(id  _Nonnull event) {
        if (!self.enableAIDataListener) {
            return;
        }
        NSDictionary *eventDict = (NSDictionary *)event;
        NSDictionary *result;
        if (eventDict != nil && [eventDict isKindOfClass:[NSDictionary class]]) {
            if (eventDict[@"face_info"] != nil) {
                result = @{@"methodName":@"aidata_onFaceDataUpdated", @"data":[self mapToString:eventDict[@"face_info"]]};
                [self eventSinkData:result];
            }
            if (eventDict[@"hand_info"] != nil && [eventDict[@"hand_info"] isKindOfClass:[NSDictionary class]]) {
                result = @{@"methodName":@"aidata_onHandDataUpdated", @"data":[self mapToString:eventDict[@"hand_info"]]};
                [self eventSinkData:result];
            }
            if (eventDict[@"body_info"] != nil) {
                result = @{@"methodName":@"aidata_onBodyDataUpdated", @"data":[self mapToString:eventDict[@"body_info"]]};
                [self eventSinkData:result];
            }
        }
    };
    [XmagicApiManager shareSingleton].eventTipsCallBlock = ^(id  _Nonnull event) {
        if (!self.enableTipsListener) {
            return;
        }
        NSDictionary *eventDict = (NSDictionary *)event;
        NSDictionary *result;
        int timeCount = eventDict[@"duration"]==nil?3:([eventDict[@"duration"] intValue]/1000);
        if ([eventDict[@"need_show"] boolValue] == YES){
            result = @{@"methodName":@"tipsNeedShow", @"tips":eventDict[@"tips"],@"tipsIcon":eventDict[@"tips_icon"],@"type":eventDict[@"tips_type"],@"duration":@(timeCount)};
        }else{
            result = @{@"methodName":@"tipsNeedHide", @"tips":eventDict[@"tips"],@"tipsIcon":eventDict[@"tips_icon"],@"type":eventDict[@"tips_type"],@"duration":@(timeCount)};
        }
        [self eventSinkData:result];
    };
    [XmagicApiManager shareSingleton].eventYTDataCallBlock = ^(id  _Nonnull event) {
        if (!self.enableYTDataListener) {
            return;
        }
        NSDictionary *eventDict = (NSDictionary *)event;
        if(eventDict !=nil && [eventDict isKindOfClass:[NSDictionary class]]){
            NSDictionary *result = @{@"methodName":@"onYTDataUpdate", @"data":[self mapToString:eventDict]};
            [self eventSinkData:result];
        }
    };
    
    [XmagicApiManager shareSingleton].xmagicApiCreatedListener = ^{
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        [result setValue:@"onXmagicApiCreated" forKey:@"methodName"];
        [result setValue:@"1" forKey:@"data"];
        [self eventSinkData:result];
    };
    
}

-(NSDictionary *)stringToMap:(NSString *)string{
    NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    return  dict;
}

-(NSString *)mapToString:(id)dict{
    if(dict != nil && ([dict isKindOfClass:[NSDictionary class]] || [dict isKindOfClass:[NSArray class]])){
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        NSString *string = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return  string == nil ? @"" : string;
    }
    return @"";
}

-(NSString *)isDeviceSupport:(NSString *)jsonString{
    NSString *result;
    NSDictionary *dictionary = [self stringToMap:jsonString];
    for(id dic in dictionary){
        dic[@"isSupport"] = @true;
    }
    result = [self mapToString:dictionary];
    return  result;
}

#pragma mark - FlutterStreamHandler
 
- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)eventSink {
    self.eventSink = eventSink;
    return nil;
}
 
- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.eventSink = nil;
    return nil;
}

@end

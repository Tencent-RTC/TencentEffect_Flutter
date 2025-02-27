//
//  XmagicApiManager.m
//  tencent_effect_flutter
//
//  Created by tao yue on 2022/6/12.
//  Copyright (c) 2020年 Tencent. All rights reserved.

#import "XmagicApiManager.h"
#import "XMagic.h"
#import "YTCommonXMagic/TELicenseCheck.h"

#define VERBOSE_LEVEL 2
#define DEBUG_LEVEL   3
#define INFO_LEVEL    4
#define WARN_LEVEL    5
#define ERROR_LEVEL   6
#define DEFAULT_LEVEL 7
#define UNKNOWN_LEVEL 8

#define CATEGORY_BEAUTY @"BEAUTY"
#define CATEGORY_LUT @"LUT"
#define CATEGORY_MOTION @"MOTION"
#define CATEGORY_SEGMENTATION @"SEGMENTATION"
#define CATEGORY_BODY_BEAUTY @"BODY_BEAUTY"
#define CATEGORY_MAKEUP @"MAKEUP"

static const int MAX_SEG_VIDEO_DURATION = 200 * 1000;

@interface XmagicApiManager()<YTSDKEventListener, YTSDKLogListener>

@property (nonatomic, strong) XMagic          *xMagicApi;
@property (assign, nonatomic) NSUInteger       heightF;
@property (assign, nonatomic) NSUInteger       widthF;
@property (nonatomic, strong) NSString        *xmagicResPath;//resource path
@property (nonatomic, strong) NSString                  *makeup;
@property (nonatomic, strong) NSArray *resNames;  //resource name
@property (nonatomic, strong) NSLock  *lock;
@property (nonatomic, assign) EffectMode effectMode ;
@property (nonatomic, strong) NSMutableArray<NSDictionary *>*saveEffectList;
@property (nonatomic, assign) BOOL xmagicInit;

@end

@implementation XmagicApiManager

static XmagicApiManager *shareSingleton = nil;
 
+ (instancetype)shareSingleton {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareSingleton = [[super allocWithZone:NULL] init];
    });
    return shareSingleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _effectMode = EFFECT_MODE_PRO; // 设置默认值
    }
    return self;
}

 
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [XmagicApiManager shareSingleton];
}
 
- (id)copyWithZone:(struct _NSZone *)zone {
    return [XmagicApiManager shareSingleton];
}

- (void)setResourcePath:(NSString *)pathDir{
    self.xmagicResPath = pathDir;
}

//init resource
-(void)initXmagicRes:(initXmagicResCallback)complete{
    if(self.xmagicResPath.length == 0){
        NSLog(@"error:resPath is invalid");
        return;
    }
    [self initResName];
    if (![[NSFileManager  defaultManager] fileExistsAtPath:self.xmagicResPath]){
        [[NSFileManager  defaultManager] createDirectoryAtPath:self.xmagicResPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    NSError *error = nil;
    for (int i = 0; i < _resNames.count; i++) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:_resNames[i] ofType:@"bundle"];
        if (bundlePath !=nil) {
            NSString *path = [NSString stringWithFormat:@"%@/%@.bundle",self.xmagicResPath,_resNames[i]];
            if([[NSFileManager  defaultManager] fileExistsAtPath:bundlePath]){
                if ([[NSFileManager  defaultManager] fileExistsAtPath:path]) {
                    NSError *error = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                }
                [[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:path error:&error];
                if (error != nil) {
                    NSLog(@"xmagic init resource error：%@",error.description);
                    break;
                }
            }else{
                [self copyItemsFromBundleToSandbox:bundlePath sandboxFolderPath:path];
            }
        }

    }
    if (complete != nil) {
        complete(error == nil);
    }
}

-(void)copyItemsFromBundleToSandbox:(NSString *)bundleFolderPath  sandboxFolderPath:(NSString *)sandboxFolderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *bundleFolderContents = [fileManager contentsOfDirectoryAtPath:bundleFolderPath error:nil];
    
    for (NSString *itemName in bundleFolderContents) {
        NSString *bundleItemFullPath = [bundleFolderPath stringByAppendingPathComponent:itemName];
        BOOL isDirectory;
        [fileManager fileExistsAtPath:bundleItemFullPath isDirectory:&isDirectory];
        
        NSString *sandboxItemFullPath = [sandboxFolderPath stringByAppendingPathComponent:itemName];
        if ([[NSFileManager  defaultManager] fileExistsAtPath:sandboxItemFullPath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:sandboxItemFullPath error:&error];
        }
        NSError *error;
        [fileManager copyItemAtPath:bundleItemFullPath toPath:sandboxItemFullPath error:&error];
        if (error) {
            NSLog(@"error: %@", error.localizedDescription);
        }
    }
}

-(void)initResName{
    _resNames = @[@"Light3DPlugin",@"LightBodyPlugin",@"LightCore",
    @"LightHandPlugin",@"LightSegmentPlugin",@"makeupMotionRes",@"lightMakeupRes",@"2dMotionRes",
    @"3dMotionRes",@"ganMotionRes",@"handMotionRes",@"lut",@"segmentMotionRes"];
}

//Authentication

-(void)setLicense:(NSString *)licenseKey licenseUrl:(NSString *)licenseUrl completion:(setLicenseCallback)completion{
    [TELicenseCheck setTELicense:licenseUrl key:licenseKey completion:^(NSInteger authresult, NSString * _Nonnull errorMsg) {
        if(completion != nil){
            completion(authresult,errorMsg);
        }
    }];
}

//Set sdk log level

-(void)setXmagicLogLevel:(int)logLevel{
    if (self.xMagicApi != nil) {
        if (logLevel == VERBOSE_LEVEL) {
            [self.xMagicApi registerLoggerListener:self withDefaultLevel:YT_SDK_VERBOSE_LEVEL];
        }else if(logLevel == DEBUG_LEVEL){
            [self.xMagicApi registerLoggerListener:self withDefaultLevel:YT_SDK_DEBUG_LEVEL];
        }else if (logLevel == INFO_LEVEL){
            [self.xMagicApi registerLoggerListener:self withDefaultLevel:YT_SDK_INFO_LEVEL];
        }else if (logLevel == WARN_LEVEL){
            [self.xMagicApi registerLoggerListener:self withDefaultLevel:YT_SDK_WARN_LEVEL];
        }else if (logLevel == ERROR_LEVEL){
            [self.xMagicApi registerLoggerListener:self withDefaultLevel:YT_SDK_ERROR_LEVEL];
        }else if (logLevel == DEFAULT_LEVEL){
            [self.xMagicApi registerLoggerListener:self withDefaultLevel:YT_SDK_DEFAULT_LEVEL];
        }else{
            [self.xMagicApi registerLoggerListener:self withDefaultLevel:YT_SDK_UNKNOWN_LEVEL];
        }
    }
}

-(void)onPause{
    if (self.xMagicApi != nil) {
        [self.xMagicApi onPause];
    }
}

-(void)onResume{
    if (self.xMagicApi != nil) {
        [self.xMagicApi onResume];
    }
}

-(NSLock *)lock{
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}

-(void)onDestroy{
    if (self.xMagicApi != nil) {
        [self.lock lock];
        [self.xMagicApi deinit];
        self.xMagicApi = nil;
        [self.lock unlock];
    }
}

//Determine which beauties (beauty and body) are supported by the current license authorization

-(NSString *)isBeautyAuthorized:(NSString *)jsonString{
    NSString *result;
    NSDictionary *dictionary = [self stringToMap:jsonString];
    for(id dic in dictionary){
        if ([XMagic isBeautyAuthorized:dic[@"effKey"]]) {
            dic[@"isAuth"] = @true;
        }else{
            dic[@"isAuth"] = @false;
        }
    }
    result = [self mapToString:dictionary];
    return  result;
}

- (void)enableEnhancedMode{
    if (self.xMagicApi != nil) {
        [self.xMagicApi enableEnhancedMode];
    }
}

- (void)setDowngradePerformance{
    _effectMode = EFFECT_MODE_NORMAL;
}

- (void)enableHighPerformance {
    _effectMode = EFFECT_MODE_NORMAL;
}

- (int)getDeviceLevel {
    DeviceLevel level = [XMagic getDeviceLevel];
    return (int)level;
}
-(void)setTeEffectMode:(NSString *)modeType {
    if(self.xMagicApi != nil) {
        NSLog(@"setEffectMode mothod , the xMagicApi is not nil)");
    }
    
    if([@"0" isEqualToString:modeType]) {
        self.effectMode = EFFECT_MODE_NORMAL;
    } else if([@"1" isEqualToString:modeType]) {
        self.effectMode = EFFECT_MODE_PRO;
    }
}

- (void)setFeatureEnableDisable:(NSString *)featureName enable:(BOOL)enable{
    if (self.xMagicApi != nil) {
        [self.xMagicApi setFeatureEnableDisable:featureName enable:enable];
    }
}

- (void)setAudioMute:(BOOL)mute{
    if (self.xMagicApi != nil) {
        [self.xMagicApi setAudioMute:mute];
    }
}

- (void)setImageOrientation:(int)orientation{
    if (self.xMagicApi != nil) {
        [self.xMagicApi setImageOrientation:(YtLightDeviceCameraOrientation)orientation];
    }
}

//build sdk

- (void)buildBeautySDK:(int)width and:(int)height{
    NSDictionary *assetsDict = @{@"core_name":@"LightCore.bundle",
                                 @"root_path":self.xmagicResPath,
                                 @"effect_mode":@(self.effectMode)
    };

    // Init beauty kit
   self.xMagicApi = [[XMagic alloc] initWithRenderSize:CGSizeMake(width,height) assetsDict:assetsDict];
   [self.xMagicApi registerSDKEventListener:self];
   [self.xMagicApi registerLoggerListener:self withDefaultLevel:YT_SDK_ERROR_LEVEL];
    _makeup = @"";
    if (!self.xmagicInit) {
        for (NSDictionary *dic in _saveEffectList) {
            [self setEffect:dic];
        }
        [_saveEffectList removeAllObjects];
    }
}


//Set beauty effects

-(void)updateProperty:(NSString *)json{
    if (self.xMagicApi == nil) {
        return;
    }
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* jsonDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString* category = jsonDic[@"category"];
    if ([category isEqual:CATEGORY_BEAUTY]) {
        _makeup = @"";
        [self.xMagicApi configPropertyWithType:@"beauty" withName:
         jsonDic[@"effKey"] withData:jsonDic[@"effValue"][@"currentDisplayValue"]
        withExtraInfo:[self stringToMap:[self getString:jsonDic[@"id"]]]];
    }else if([category isEqual:CATEGORY_LUT]){
        _makeup = @"";
        if ([jsonDic[@"id"] isEqual:@"ID_NONE"]) {
            [self.xMagicApi configPropertyWithType:@"lut" withName:jsonDic[@"id"] withData:@"0" withExtraInfo:nil];
        }else{
            [self.xMagicApi configPropertyWithType:@"lut" withName:jsonDic[@"resPath"] withData:jsonDic[@"effValue"][@"currentDisplayValue"] withExtraInfo:nil];
        }
    }else if([category isEqual:CATEGORY_MOTION]){
        _makeup = @"";
        [self.xMagicApi configPropertyWithType:@"motion" withName:jsonDic[@"id"] withData:[self getString:jsonDic[@"resPath"]] withExtraInfo:nil];
    }else if ([category isEqual:CATEGORY_SEGMENTATION]){
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy-MM-dd-HH.mm.ss"];
        NSURL *newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", [formater stringFromDate:[NSDate date]]]];
        _makeup = @"";
        if ([jsonDic[@"id"] isEqual:@"video_empty_segmentation"]) {
            if ([jsonDic[@"effKey"] isEqual:[NSNull null]]) {
                return;
            }
            AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:jsonDic[@"effKey"]]];
            NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if(tracks.count == 0){ //图片
                NSDictionary *dic = @{@"bgName":jsonDic[@"effKey"], @"bgType":@0, @"timeOffset": @0};
                [self.xMagicApi configPropertyWithType:@"motion" withName:@"video_empty_segmentation" withData:jsonDic[@"resPath"] withExtraInfo:dic];
            }else{
                [self convertVideoQuailtyWithInputAVURLAsset:asset outputURL:newVideoUrl resPath:jsonDic[@"resPath"] setEffect:NO paramDic:nil];
            }
        }else{
            [self.xMagicApi configPropertyWithType:@"motion" withName:[self getString:
            jsonDic[@"id"]] withData:[self getString:jsonDic[@"resPath"]]
            withExtraInfo:@{@"bgName":@"BgSegmentation.bg.png", @"bgType":@0, @"timeOffset": @0}];
        }
    }else if([category isEqual:CATEGORY_BODY_BEAUTY]){
        _makeup = @"";
        [self.xMagicApi configPropertyWithType:@"body" withName:jsonDic[@"effKey"] withData:jsonDic[@"effValue"][@"currentDisplayValue"] withExtraInfo:nil];
    }else if ([category isEqual:CATEGORY_MAKEUP]){
        if(![_makeup isEqual:jsonDic[@"id"]]){
            _makeup = jsonDic[@"id"];
            [self.xMagicApi configPropertyWithType:@"motion" withName:jsonDic[@"id"] withData:[self getString:jsonDic[@"resPath"]] withExtraInfo:nil];
            _makeup = jsonDic[@"id"];
        }
        if ([jsonDic[@"id"] isEqual:@"ID_NONE"]) {
            [self.xMagicApi configPropertyWithType:@"custom" withName:@"makeup.strength" withData:@"0" withExtraInfo:nil];
        }else{
            [self.xMagicApi configPropertyWithType:@"custom" withName:@"makeup.strength" withData:jsonDic[@"effValue"][@"currentDisplayValue"] withExtraInfo:nil];
        }
    }
}

- (void)setEffect:(NSDictionary *)dic{
    if (self.xMagicApi == nil) {
        _xmagicInit = NO;
        if (!_saveEffectList) {
            _saveEffectList = [NSMutableArray array];
        }
        [_saveEffectList addObject:dic];
        return;
    }
    _xmagicInit = YES;
    NSString *effectName = dic[@"effectName"];
    int effectValue = [dic[@"effectValue"] intValue];
    NSString *resourcePath = dic[@"resourcePath"];
    NSDictionary *extraInfoDic = dic[@"extraInfo"];
    NSMutableDictionary *extraInfo = extraInfoDic.mutableCopy;
    if([extraInfo[@"bgType"] isEqualToString:@"0"] && ![extraInfo[@"bgPath"] hasSuffix:@".pag"]){
        UIImage *image = [UIImage imageWithContentsOfFile:extraInfo[@"bgPath"]];
        image = [self fixOrientation:image];
        NSData *data = UIImagePNGRepresentation(image);
        NSString *imagePath = [self createImagePath:@"image.png"];
        [[NSFileManager defaultManager] createFileAtPath:imagePath contents:data attributes:nil];
        extraInfo[@"bgPath"] = imagePath;
    }else if ([extraInfo[@"bgType"] isEqualToString:@"1"]){
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy-MM-dd-HH.mm.ss"];
        NSURL *newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", [formater stringFromDate:[NSDate date]]]];
        AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:extraInfo[@"bgPath"]]];
        [self convertVideoQuailtyWithInputAVURLAsset:asset outputURL:newVideoUrl resPath:extraInfo[@"bgPath"] setEffect:YES paramDic:dic];
        return;
    }
    [self.xMagicApi setEffect:effectName effectValue:effectValue resourcePath:resourcePath extraInfo:extraInfo];
}

-(NSString *)createImagePath:(NSString *)fileName{
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [path objectAtIndex:0];
    NSString *imageDocPath = [documentPath stringByAppendingPathComponent:@"TencentEffect_MediaFile"];
    [[NSFileManager defaultManager] createDirectoryAtPath:imageDocPath withIntermediateDirectories:YES attributes:nil error:nil];
    return [imageDocPath stringByAppendingPathComponent:fileName];
}

- (UIImage *)fixOrientation:(UIImage*)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
    }
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
    }
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

// Video compression and transcoding
-(void)convertVideoQuailtyWithInputAVURLAsset:(AVURLAsset*)avAsset
                              outputURL:(NSURL*)outputURL
                                resPath:(NSString *)resPath
                              setEffect:(BOOL)setEffect
                               paramDic:(NSDictionary *)paramDic{
    CMTime videoTime = [avAsset duration];
    int timeOffset = ceil(1000 * videoTime.value / videoTime.timescale) - 10;
    if (timeOffset > MAX_SEG_VIDEO_DURATION) {
        NSLog(@"TencentEffectFlutter:background video too long(limit %i)",
              MAX_SEG_VIDEO_DURATION);
        return;
    }
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
    initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"AVAssetExportSessionStatusCancelled");
                break;
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"AVAssetExportSessionStatusUnknown");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"AVAssetExportSessionStatusWaiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"AVAssetExportSessionStatusExporting");
                break;
            case AVAssetExportSessionStatusCompleted:{
                NSLog(@"AVAssetExportSessionStatusCompleted");
                if(setEffect){
                    NSDictionary *extraInfoDic = paramDic[@"extraInfo"];
                    NSMutableDictionary *extraInfo = extraInfoDic.mutableCopy;
                    extraInfo[@"bgPath"] = outputURL.path;
                    [self.xMagicApi setEffect:paramDic[@"effectName"] effectValue:paramDic[@"effectValue"] resourcePath:paramDic[@"resourcePath"] extraInfo:extraInfo];
                }else{
                    NSDictionary *dic = @{@"bgName":outputURL.path, @"bgType":@1, @"timeOffset": [NSNumber numberWithInt:timeOffset]};
                    [self.xMagicApi configPropertyWithType:@"motion"
                    withName:@"video_empty_segmentation" withData:resPath withExtraInfo:dic];
                }
            }
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"AVAssetExportSessionStatusFailed");
                break;
        }
    }];
    if (exportSession.status == AVAssetExportSessionStatusFailed) {
        NSLog(@"TencentEffectFlutter:background video export failed");
    }
}


//return TextureId
-(int)getTextureId:(ITXCustomBeautyVideoFrame * _Nonnull)srcFrame{
    [self.lock lock];
    if (self.xMagicApi == nil) {
        [self buildBeautySDK:srcFrame.width and:srcFrame.height];
        self.heightF = srcFrame.height;
        self.widthF = srcFrame.width;
    }
    if(self.xMagicApi!=nil && (self.heightF != srcFrame.height || self.widthF != srcFrame.width)){
        [self.xMagicApi setRenderSize:CGSizeMake(srcFrame.width, srcFrame.height)];
        self.heightF = srcFrame.height;
        self.widthF = srcFrame.width;
    }
    YTProcessInput *input = [[YTProcessInput alloc] init];
    input.textureData = [[YTTextureData alloc] init];
    input.textureData.texture = srcFrame.textureId;
    input.textureData.textureWidth = srcFrame.width;
    input.textureData.textureHeight = srcFrame.height;
    input.dataType = kYTTextureData;
    YTProcessOutput *output = [self.xMagicApi process:input withOrigin:YtLightImageOriginTopLeft withOrientation:YtLightCameraRotation0];
    [self.lock unlock];
    return output.textureData.texture;
}

-(NSDictionary *)stringToMap:(NSString *)string{
    NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    return  dict;
}

-(NSString *)mapToString:(NSDictionary *)dict{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *string = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return  string;
}

-(NSString *)getString:(NSString *)string{
    if ([string isEqual:[NSNull null]]) {
        return @"";
    }
    return string;
}

#pragma mark - YTSDKEventListener

- (void)onAIEvent:(id _Nonnull)event {
    if(_eventAICallBlock != nil){
        _eventAICallBlock(event);
    }
}

- (void)onAssetEvent:(id _Nonnull)event {
    
}

- (void)onTipsEvent:(id _Nonnull)event {
    if(_eventTipsCallBlock != nil){
        _eventTipsCallBlock(event);
    }
}

- (void)onYTDataEvent:(id _Nonnull)event {
    if(_eventYTDataCallBlock != nil){
        _eventYTDataCallBlock(event);
    }
}

#pragma mark - YTSDKLogListener

- (void)onLog:(YtSDKLoggerLevel)loggerLevel withInfo:(NSString * _Nonnull)logInfo {
    NSLog(@"[%ld]-%@", (long)loggerLevel, logInfo);
}
@end

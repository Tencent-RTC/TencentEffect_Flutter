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
@property (nonatomic, strong) NSDictionary *pendingSyncMode; // 缓存的syncMode数据
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *processedMediaCache; // 媒体处理结果缓存：原始bgPath -> 处理后的路径（图片和视频共用）
@property (nonatomic, strong) AVAssetExportSession *currentExportSession; // 当前正在执行的视频转码会话，用于快速调用时取消前一次转码

/**
 * 美颜处理暂停标志位。
 * 当为 YES 时，getTextureId: 方法会跳过美颜处理，直接返回原始纹理，用于展示未经美颜处理的原始画面。
 * 通过 setBeautyProcessPaused: 方法控制：按下对比按钮时设为 YES（暂停美颜），松开时设为 NO（恢复美颜）。
 */
@property (nonatomic, assign) BOOL isBeautyProcessPaused;

/**
 * 恢复美颜时需要刷新一帧的标志位。
 * 当暂停模式结束（isBeautyProcessPaused 从 YES 变为 NO）后，需要额外执行一次 process 调用来刷新美颜渲染结果，
 * 避免从原始画面切换回美颜画面时出现画面闪烁或延迟。
 */
@property (nonatomic, assign) BOOL needRefreshOnResume;

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
        if (complete != nil) {
            complete(NO);
        }
        return;
    }
    [self initResName];
    // 在子线程执行资源复制操作，避免阻塞主线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 创建目标目录（如果不存在）
        if (![fileManager fileExistsAtPath:self.xmagicResPath]) {
            [fileManager createDirectoryAtPath:self.xmagicResPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        BOOL success = YES;
        for (int i = 0; i < self.resNames.count; i++) {
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource:self.resNames[i] ofType:@"bundle"];
            if (bundlePath == nil) {
                NSLog(@"xmagic init resource warning: bundle path is nil for %@", self.resNames[i]);
                continue;
            }
            NSString *destPath = [NSString stringWithFormat:@"%@/%@.bundle", self.xmagicResPath, self.resNames[i]];
            // 检查源文件是否存在
            if (![fileManager fileExistsAtPath:bundlePath]) {
                NSLog(@"xmagic init resource warning: bundle not found at path %@", bundlePath);
                continue;
            }
            // 如果目标路径已存在，先删除
            if ([fileManager fileExistsAtPath:destPath]) {
                NSError *removeError = nil;
                [fileManager removeItemAtPath:destPath error:&removeError];
                if (removeError != nil) {
                    NSLog(@"xmagic init resource warning: failed to remove existing file at %@, error: %@", destPath, removeError.localizedDescription);
                }
            }
            // 复制 bundle（copyItemAtPath 可以复制目录）
            NSError *copyError = nil;
            [fileManager copyItemAtPath:bundlePath toPath:destPath error:&copyError];
            if (copyError != nil) {
                NSLog(@"xmagic init resource error: failed to copy %@ to %@, error: %@", bundlePath, destPath, copyError.localizedDescription);
                success = NO;
                break;
            }
        }
        // 回到主线程执行回调
        if (complete != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(success);
            });
        }
    });
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
    [_processedMediaCache removeAllObjects];
    _currentExportSession = nil;
    _isBeautyProcessPaused = NO;
    _needRefreshOnResume = NO;
}

// 清空所有缓存的待处理数据（包括effect、syncMode等）
-(void)cleanPendingData{
    [_saveEffectList removeAllObjects];
    _pendingSyncMode = nil;
    [_processedMediaCache removeAllObjects];
    if (_currentExportSession && _currentExportSession.status == AVAssetExportSessionStatusExporting) {
        [_currentExportSession cancelExport];
    }
    _currentExportSession = nil;
    _isBeautyProcessPaused = NO;
    _needRefreshOnResume = NO;
    NSLog(@"cleanPendingData: all pending data cleared");
}

// 应用所有缓存的待处理数据（包括effect、syncMode等）
-(void)applyPendingData{
    if (_saveEffectList.count > 0) {
        for (NSDictionary *dic in _saveEffectList) {
            [self setEffect:dic];
        }
        [_saveEffectList removeAllObjects];
    }
    if (_pendingSyncMode != nil) {
        BOOL isSync = [_pendingSyncMode[@"isSync"] boolValue];
        int syncFrameCount = [_pendingSyncMode[@"syncFrameCount"] intValue];
        [self.xMagicApi setSyncMode:isSync syncFrameCount:syncFrameCount];
        _pendingSyncMode = nil;
        NSLog(@"applyPendingData: applied syncMode, isSync=%d, syncFrameCount=%d", isSync, syncFrameCount);
    }
}

// 设置同步模式（参照Android端实现，支持API未创建时缓存）
-(void)setSyncMode:(BOOL)isSync syncFrameCount:(int)syncFrameCount{
    if (self.xMagicApi == nil) {
        NSLog(@"setSyncMode: xMagicApi is nil, caching syncMode data");
        _pendingSyncMode = @{@"isSync": @(isSync), @"syncFrameCount": @(syncFrameCount)};
        return;
    }
    [self.xMagicApi setSyncMode:isSync syncFrameCount:syncFrameCount];
}

// 设置美颜处理暂停状态：paused为YES时暂停美颜处理（展示原始画面），为NO时恢复美颜处理
-(void)setBeautyProcessPaused:(BOOL)paused{
    _isBeautyProcessPaused = paused;
}

-(void)setOutputTextureKeepRatio:(float)ratio{
    if (self.xMagicApi != nil) {
        [self.xMagicApi setOutputTextureKeepRatio:ratio];
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
    
    if(self.xmagicResPath ==nil){
        NSLog(@"self.xmagicResPath please set resPath");
    }
    NSDictionary *assetsDict = @{@"core_name":@"LightCore.bundle",
                                 @"root_path":self.xmagicResPath,
                                 @"effect_mode":@(self.effectMode)
    };

    // Init beauty kit
   self.xMagicApi = [[XMagic alloc] initWithRenderSize:CGSizeMake(width,height) assetsDict:assetsDict];
   [self.xMagicApi registerSDKEventListener:self];
   [self.xMagicApi registerLoggerListener:self withDefaultLevel:YT_SDK_ERROR_LEVEL];
    _makeup = @"";
    // API创建后，应用所有缓存的待处理数据
    [self applyPendingData];
    if(_xmagicApiCreatedListener != nil) {
        _xmagicApiCreatedListener();
    }
    NSLog(@"buildBeautySDK ,  xMagicApi create success");
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
        if (!_saveEffectList) {
            _saveEffectList = [NSMutableArray array];
        }
        [_saveEffectList addObject:dic];
        return;
    }
    NSString *effectName = dic[@"effectName"];
    int effectValue = [dic[@"effectValue"] intValue];
    NSString *resourcePath = dic[@"resourcePath"];
    NSDictionary *extraInfoDic = dic[@"extraInfo"];
    NSMutableDictionary *extraInfo = extraInfoDic.mutableCopy;
    if([extraInfo[@"bgType"] isEqualToString:@"0"] && ![extraInfo[@"bgPath"] hasSuffix:@".pag"]){
        NSString *originalPath = extraInfo[@"bgPath"];
        NSString *cachedPath = self.processedMediaCache[originalPath];
        if (cachedPath && [[NSFileManager defaultManager] fileExistsAtPath:cachedPath]) {
            // 命中缓存，直接使用已处理过的图片路径，跳过耗时的图片处理操作
            extraInfo[@"bgPath"] = cachedPath;
        } else {
            // 未命中缓存，执行完整的图片处理流程
            UIImage *image = [UIImage imageWithContentsOfFile:originalPath];
            image = [self fixOrientation:image];
            NSData *data = UIImagePNGRepresentation(image);
            // 使用原始路径的 hash 生成唯一文件名，避免文件竞态覆盖
            NSString *imagePath = [self createImagePath:
                [NSString stringWithFormat:@"image_%lu.png", (unsigned long)originalPath.hash]];
            [[NSFileManager defaultManager] createFileAtPath:imagePath contents:data attributes:nil];
            extraInfo[@"bgPath"] = imagePath;
            // 存入缓存
            if (!self.processedMediaCache) {
                self.processedMediaCache = [NSMutableDictionary dictionary];
            }
            self.processedMediaCache[originalPath] = imagePath;
        }
    }else if ([extraInfo[@"bgType"] isEqualToString:@"1"]){
        NSString *originalVideoPath = extraInfo[@"bgPath"];
        NSString *cachedVideoPath = self.processedMediaCache[originalVideoPath];
        if (cachedVideoPath && [[NSFileManager defaultManager] fileExistsAtPath:cachedVideoPath]) {
            // 命中缓存，直接使用已转码过的视频路径，跳过耗时的视频转码操作
            extraInfo[@"bgPath"] = cachedVideoPath;
        } else {
            // 未命中缓存，取消前一次未完成的转码任务，启动新的转码
            if (self.currentExportSession && self.currentExportSession.status == AVAssetExportSessionStatusExporting) {
                [self.currentExportSession cancelExport];
            }
            NSDateFormatter *formater = [[NSDateFormatter alloc] init];
            [formater setDateFormat:@"yyyy-MM-dd-HH.mm.ss.SSS"];
            NSURL *newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", [formater stringFromDate:[NSDate date]]]];
            AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:originalVideoPath]];
            [self convertVideoQuailtyWithInputAVURLAsset:asset outputURL:newVideoUrl resPath:originalVideoPath setEffect:YES paramDic:dic];
            return;
        }
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
    self.currentExportSession = exportSession;
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
                    // 将转码结果存入缓存
                    NSString *originalVideoPath = extraInfo[@"bgPath"];
                    if (!self.processedMediaCache) {
                        self.processedMediaCache = [NSMutableDictionary dictionary];
                    }
                    self.processedMediaCache[originalVideoPath] = outputURL.path;
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


// 处理 CVPixelBuffer 路径（无 GL 上下文场景使用，例如 iOS TRTC Metal 渲染管线）
// 返回值：retain 过的 CVPixelBufferRef，**调用方负责 CFRelease**；失败返回 NULL
-(CVPixelBufferRef _Nullable)processPixelBuffer:(CVPixelBufferRef _Nonnull)pixelBuffer
                                          width:(int)width
                                         height:(int)height{
    if (pixelBuffer == NULL) {
        return NULL;
    }
    [self.lock lock];
    // 首帧懒初始化（与 getTextureId: 一致）
    if (self.xMagicApi == nil) {
        [self buildBeautySDK:width and:height];
        self.heightF = height;
        self.widthF = width;
    }
    // 美颜暂停（按下对比按钮）：返回 NULL，调用方用原始 pixelBuffer
    if (self.isBeautyProcessPaused) {
        self.needRefreshOnResume = YES;
        [self.lock unlock];
        return NULL;
    }
    // 分辨率变化时同步刷新 render size
    if (self.xMagicApi != nil && (self.heightF != (NSUInteger)height || self.widthF != (NSUInteger)width)) {
        [self.xMagicApi setRenderSize:CGSizeMake(width, height)];
        self.heightF = height;
        self.widthF = width;
    }
    YTProcessInput *input = [[YTProcessInput alloc] init];
    input.pixelData = [[YTImagePixelData alloc] init];
    input.pixelData.data = pixelBuffer;
    input.pixelData.rotation = 0;
    input.dataType = kYTImagePixelData;
    // 暂停模式刚结束时多走一次 process，避免画面闪烁（与 getTextureId 行为一致）
    if (self.needRefreshOnResume) {
        self.needRefreshOnResume = NO;
        [self.xMagicApi process:input withOrigin:YtLightImageOriginTopLeft withOrientation:YtLightCameraRotation0];
    }
    YTProcessOutput *output = [self.xMagicApi process:input withOrigin:YtLightImageOriginTopLeft withOrientation:YtLightCameraRotation0];
    CVPixelBufferRef outBuffer = (output != nil && output.pixelData != nil) ? output.pixelData.data : NULL;
    if (outBuffer != NULL) {
        // XMagic 输出的 pixelBuffer 生命周期归 SDK 内部缓存所有；
        // 我们 retain 一份返回给调用方，调用方使用完后必须 CFRelease。
        CFRetain(outBuffer);
    }
    [self.lock unlock];
    return outBuffer;
}

//return TextureId
-(int)getTextureId:(ITXCustomBeautyVideoFrame * _Nonnull)srcFrame{
    [self.lock lock];
    if (self.xMagicApi == nil) {
        [self buildBeautySDK:srcFrame.width and:srcFrame.height];
        self.heightF = srcFrame.height;
        self.widthF = srcFrame.width;
    }
    // 美颜处理暂停模式：跳过美颜处理，直接返回原始纹理
    if (self.isBeautyProcessPaused) {
        NSLog(@"getTextureId: isBeautyProcessPaused is YES");
        self.needRefreshOnResume = YES;
        [self.lock unlock];
        return srcFrame.textureId;
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
    // 恢复美颜时额外执行一次process，避免画面闪烁
    if (self.needRefreshOnResume) {
        self.needRefreshOnResume = NO;
        [self.xMagicApi process:input withOrigin:YtLightImageOriginTopLeft withOrientation:YtLightCameraRotation0];
    }
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

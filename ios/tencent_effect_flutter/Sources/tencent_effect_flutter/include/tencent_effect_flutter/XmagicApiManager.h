//
//  XmagicApiManager.h
//  tencent_effect_flutter
//
//  Created by tao yue on 2022/6/12.
//  Copyright (c) 2020 Tencent. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
@import TXCustomBeautyProcesserPlugin;

NS_ASSUME_NONNULL_BEGIN

typedef void(^initXmagicResCallback)(bool success);
typedef void(^setLicenseCallback)(NSInteger authresult, NSString *errorMsg);
typedef void (^eventAICallBlock)(id event);
typedef void (^eventTipsCallBlock)(id event);
typedef void (^eventYTDataCallBlock)(id event);

typedef void (^onXmagicApiCreated)();

@interface XmagicApiManager : NSObject

+ (instancetype)shareSingleton;

@property (nonatomic, copy) eventAICallBlock eventAICallBlock; 
@property (nonatomic, copy) eventTipsCallBlock eventTipsCallBlock;
@property (nonatomic, copy) eventYTDataCallBlock eventYTDataCallBlock; 


@property (nonatomic, copy) onXmagicApiCreated xmagicApiCreatedListener;

//init
-(void)initXmagicRes:(initXmagicResCallback)complete;

//auth
-(void)setLicense:(NSString *)licenseKey licenseUrl:(NSString *)licenseUrl completion:(setLicenseCallback)completion;

//get TextureId
-(int)getTextureId:(ITXCustomBeautyVideoFrame * _Nonnull)srcFrame;

/**
 * @brief 处理 CVPixelBuffer 数据并返回美颜后的 CVPixelBuffer。
 *
 * 适用于无 GL 上下文环境（如 TRTC iOS Metal 渲染管线 / AVCaptureSession 直采）。
 * - 首帧会按 (width,height) 自动初始化 XMagic（与 getTextureId 共用单例）。
 * - 线程安全：内部已加锁。
 * - 返回值：成功时返回 retain 过的 CVPixelBufferRef，**调用方负责 CFRelease**；
 *           失败 / 暂停 / API 未就绪时返回 NULL（此时调用方应使用原始 pixelBuffer 透传）。
 *
 * @param pixelBuffer 输入 BGRA CVPixelBuffer
 * @param width  纹理宽度
 * @param height 纹理高度
 * @return 处理后的 CVPixelBuffer（已 retain，需 CFRelease）；失败返回 NULL。
 */
-(CVPixelBufferRef _Nullable)processPixelBuffer:(CVPixelBufferRef _Nonnull)pixelBuffer
                                          width:(int)width
                                         height:(int)height CF_RETURNS_RETAINED;


-(void)updateProperty:(NSString *)json;

// Set the beauty effect (added in 3.5.0)
- (void)setEffect:(NSDictionary *)dic;

 
-(void)setXmagicLogLevel:(int)logLevel;

 
-(NSString *)isBeautyAuthorized:(NSString *)jsonString;


-(void)enableEnhancedMode;

 
-(void)setDowngradePerformance;

-(void)enableHighPerformance;

-(void)setTeEffectMode:(NSString *)modeType;

-(void)setAudioMute:(BOOL)mute;

-(int)getDeviceLevel;

- (void)setFeatureEnableDisable:(NSString *_Nonnull)featureName enable:(BOOL)enable;

- (void)setResourcePath:(NSString *)pathDir;

 
- (void)setImageOrientation:(int)orientation;

-(void)onPause;

-(void)onResume;

-(void)onDestroy;

// 清空所有缓存的待处理数据（包括effect、syncMode等）
-(void)cleanPendingData;

// 设置同步模式（参照Android端实现，支持API未创建时缓存）
-(void)setSyncMode:(BOOL)isSync syncFrameCount:(int)syncFrameCount;

// 设置美颜处理暂停状态：paused为YES时暂停美颜处理（展示原始画面），为NO时恢复美颜处理
-(void)setBeautyProcessPaused:(BOOL)paused;

-(void)setOutputTextureKeepRatio:(float)ratio;

@end

NS_ASSUME_NONNULL_END

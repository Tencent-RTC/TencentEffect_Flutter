//
//  XmagicApiManager.h
//  tencent_effect_flutter
//
//  Created by tao yue on 2022/6/12.
//  Copyright (c) 2020 Tencent. All rights reserved.

#import <Foundation/Foundation.h>
@import TXCustomBeautyProcesserPlugin;

NS_ASSUME_NONNULL_BEGIN

typedef void(^initXmagicResCallback)(bool success);
typedef void(^setLicenseCallback)(NSInteger authresult, NSString *errorMsg);
typedef void (^eventAICallBlock)(id event);
typedef void (^eventTipsCallBlock)(id event);
typedef void (^eventYTDataCallBlock)(id event);

@interface XmagicApiManager : NSObject

+ (instancetype)shareSingleton;

@property (nonatomic, copy) eventAICallBlock eventAICallBlock; 
@property (nonatomic, copy) eventTipsCallBlock eventTipsCallBlock;
@property (nonatomic, copy) eventYTDataCallBlock eventYTDataCallBlock; 

//init
-(void)initXmagicRes:(initXmagicResCallback)complete;

//auth
-(void)setLicense:(NSString *)licenseKey licenseUrl:(NSString *)licenseUrl completion:(setLicenseCallback)completion;

//get TextureId
-(int)getTextureId:(ITXCustomBeautyVideoFrame * _Nonnull)srcFrame;


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

@end

NS_ASSUME_NONNULL_END

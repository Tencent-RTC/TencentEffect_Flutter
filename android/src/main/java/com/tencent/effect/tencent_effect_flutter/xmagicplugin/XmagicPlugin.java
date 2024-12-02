package com.tencent.effect.tencent_effect_flutter.xmagicplugin;

import androidx.annotation.NonNull;


import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * tencent_effect_flutter
 * Created by kevinxlhua on 2022/8/12.
 * Copyright (c) 2020 Tencent. All rights reserved
 */


public interface XmagicPlugin {


    void setEventSink(EventChannel.EventSink eventSink);

    void setResourcePath(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void initXmagic(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void addAiMode(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void setLibPathAndLoad(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void setLicense(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void setXmagicLogLevel(@NonNull MethodCall call, @NonNull MethodChannel.Result result);


    void onResume(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void onPause(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    @Deprecated
    void updateProperty(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void setEffect(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void isBeautyAuthorized(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void isSupportBeauty(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void getDeviceAbilities(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void getPropertyRequiredAbilities(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void isDeviceSupport(@NonNull MethodCall call, @NonNull MethodChannel.Result result);
    void isDeviceSupportMotion(@NonNull MethodCall call, @NonNull MethodChannel.Result result);
    void enableEnhancedMode(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    @Deprecated
    void setDowngradePerformance(@NonNull MethodCall call, @NonNull MethodChannel.Result result);
    void enableHighPerformance(@NonNull MethodCall call, @NonNull MethodChannel.Result result);
    void setEffectMode(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void getDeviceLevel(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void setAudioMute(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void setFeatureEnableDisable(@NonNull MethodCall call, @NonNull MethodChannel.Result result);

    void setImageOrientation(@NonNull MethodCall call, @NonNull MethodChannel.Result result);
    void enableAIDataListener(@NonNull MethodCall call, @NonNull MethodChannel.Result result);
    void enableYTDataListener(@NonNull MethodCall call, @NonNull MethodChannel.Result result);
    void enableTipsListener(@NonNull MethodCall call, @NonNull MethodChannel.Result result);


}

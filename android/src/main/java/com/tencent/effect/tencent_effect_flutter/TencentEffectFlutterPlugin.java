package com.tencent.effect.tencent_effect_flutter;

import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.google.gson.Gson;
import com.tencent.effect.tencent_effect_flutter.utils.LogUtils;
import com.tencent.effect.tencent_effect_flutter.utils.RefInvoker;
import com.tencent.effect.tencent_effect_flutter.xmagicplugin.XmagicPlugin;
import com.tencent.effect.tencent_effect_flutter.xmagicplugin.XmagicPluginImp;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * tencent_effect_flutter
 * Created by kevinxlhua on 2022/8/12.
 * Copyright (c) 2020 Tencent. All rights reserved
 */

public class TencentEffectFlutterPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel toNativeChannel;
    private EventChannel toFlutterChannel;
    private EventChannel.EventSink mEventSink;
    private XmagicPlugin xmagicPlugin;

    private static String TAG = TencentEffectFlutterPlugin.class.getName();
    private Gson gson = new Gson();


    static final String CALL_NATIVE_NAME = "tencent_effect_methodChannel_call_native";
    static final String CALL_FLUTTER_NAME = "tencent_effect_methodChannel_call_flutter";
//    static final String CALL_PLATFORM_VIEW_NAME = "Xmagic_ImageView_PlatformView";


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        toNativeChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CALL_NATIVE_NAME);
        toNativeChannel.setMethodCallHandler(this);
        xmagicPlugin = new XmagicPluginImp(flutterPluginBinding);
        toFlutterChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), CALL_FLUTTER_NAME);
        toFlutterChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                mEventSink = eventSink;
                xmagicPlugin.setEventSink(mEventSink);
            }

            @Override
            public void onCancel(Object o) {

            }
        });


    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        String methodName = call.method;
        if (TextUtils.isEmpty(methodName)) {
            result.notImplemented();
        }
        LogUtils.d(TAG, methodName + "is call, parameter is  " + gson.toJson(call.arguments));
        RefInvoker.invokeMethod(xmagicPlugin,
                xmagicPlugin.getClass().getName(),
                methodName,
                new Class[]{MethodCall.class, Result.class},
                new Object[]{call, result});
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (toNativeChannel != null) {
            toNativeChannel.setMethodCallHandler(null);
        }
        if (mEventSink != null) {
            mEventSink.endOfStream();
            mEventSink = null;
        }
        if (toFlutterChannel != null) {
            toFlutterChannel.setStreamHandler(null);
        }
    }

}

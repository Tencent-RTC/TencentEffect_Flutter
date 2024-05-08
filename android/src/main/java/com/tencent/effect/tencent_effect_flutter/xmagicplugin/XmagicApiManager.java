package com.tencent.effect.tencent_effect_flutter.xmagicplugin;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.google.gson.Gson;
import com.tencent.effect.tencent_effect_flutter.res.XmagicResParser;
import com.tencent.effect.tencent_effect_flutter.utils.LogUtils;
import com.tencent.xmagic.XmagicApi;
import com.tencent.xmagic.XmagicApi.XmagicAIDataListener;
import com.tencent.xmagic.XmagicApi.XmagicTipsListener;
import com.tencent.xmagic.XmagicProperty;
import com.tencent.xmagic.avatar.AvatarData;
import com.tencent.xmagic.bean.TEBodyData;
import com.tencent.xmagic.bean.TEFaceData;
import com.tencent.xmagic.bean.TEHandData;
import com.tencent.xmagic.bean.TEImageOrientation;
import com.tencent.xmagic.listener.UpdatePropertyListener;
import com.tencent.xmagic.telicense.TELicenseCheck;
import com.tencent.xmagic.telicense.TELicenseCheck.TELicenseCheckListener;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;


/**
 * tencent_effect_flutter
 * Created by kevinxlhua on 2022/8/12.
 * Copyright (c) 2020 Tencent. All rights reserved
 */

public class XmagicApiManager implements SensorEventListener, XmagicAIDataListener, XmagicTipsListener {

    private static final String TAG = "XmagicApiManager";

    private XmagicApi xmagicApi;

    private SensorManager mSensorManager;
    private Sensor mAccelerometer;
    private Context mApplicationContext = null;
    private XmagicManagerListener managerListener;

    private int currentStreamType = XmagicApi.PROCESS_TYPE_CAMERA_STREAM;

    private int xMagicLogLevel = Log.WARN;


    private boolean isPerformance = false;


    private volatile boolean enableAiData = false;

    private volatile boolean enableYTData = false;

    private volatile boolean enableTipsListener = false;

    static class ClassHolder {
        static final XmagicApiManager INSTANCE = new XmagicApiManager();
    }

    public static XmagicApiManager getInstance() {
        return ClassHolder.INSTANCE;
    }


    /**
     *
     * @param context
     * @return
     */
    public void initModelResource(Context context, InitModelResourceCallBack callBack) {
        String resourceDir = XmagicResParser.getResPath();
        if (!new File(resourceDir).exists()) {
            new File(resourceDir).mkdirs();
        }
        new Thread(() -> {
            boolean result = XmagicResParser.copyRes(context.getApplicationContext());
            new Handler(Looper.getMainLooper()).post(() -> {
                if (callBack != null) {
                    callBack.onResult(result);
                }
            });
        }).start();
    }


    public static int addAiModeFiles(String inputDir, String resDir) {
        return XmagicApi.addAiModeFiles(inputDir, resDir);
    }

    public static boolean setLibPathAndLoad(String libPath) {
        return XmagicApi.setLibPathAndLoad(libPath);
    }

    public void setTELicense(Context context, String url, String key, TELicenseCheckListener licenseCheckListener) {
        TELicenseCheck.getInstance().setTELicense(context, url, key, (errorCode, msg) -> {
            LogUtils.d(TAG, "onLicenseCheckFinish: errorCode=" + errorCode + ",msg=" + msg);
            if (licenseCheckListener != null) {
                licenseCheckListener.onLicenseCheckFinish(errorCode, msg);
            }
        });
    }

    public void onCreateApi() {
        XmagicApi api = new XmagicApi(mApplicationContext, XmagicResParser.getResPath(), (s, i) -> {
            if (managerListener != null) {
                managerListener.onXmagicPropertyError(s, i);
            }
        });
        mSensorManager = (SensorManager) mApplicationContext.getSystemService(Context.SENSOR_SERVICE);
        mAccelerometer = mSensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        if (enableAiData || enableYTData) {
            api.setAIDataListener(this);
        }
        if (this.enableTipsListener) {
            api.setTipsListener(this);
        }
        api.setXmagicLogLevel(xMagicLogLevel);
        if (isPerformance) {
            api.setDowngradePerformance();
        }
        xmagicApi = api;
    }

    public void setXMagicStreamType(int type) {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "setXMagicStreamType: xmagicApi is null ");
            return;
        }
        xmagicApi.setXmagicStreamType(type);
    }

    public void setXmagicLogLevel(int level) {
        LogUtils.setLogLevel(level);
        xMagicLogLevel = level;
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "setXmagicLogLevel: xmagicApi is null ");
            return;
        }
        xmagicApi.setXmagicLogLevel(level);
    }

    public void onResume() {
        if (xmagicApi != null) {
            xmagicApi.onResume();
        } else {
            LogUtils.e(TAG, "onResume: xmagicApi is null ");
        }
        if (mSensorManager != null) {
            mSensorManager.registerListener(this, mAccelerometer, SensorManager.SENSOR_DELAY_NORMAL);
        } else {
            LogUtils.e(TAG, "onResume: mSensorManager is null ");
        }
    }

    public void onPause() {
        if (xmagicApi != null) {
            xmagicApi.onPause();
        } else {
            LogUtils.e(TAG, "onPause: xmagicApi is null ");
        }
        if (mSensorManager != null) {
            mSensorManager.unregisterListener(this);
        } else {
            LogUtils.e(TAG, "onPause: mSensorManager is null ");
        }
    }

    public void onDestroy() {
        enableAiData = false;
        enableYTData = false;
        enableTipsListener = false;
        isPerformance = false;
        currentStreamType = XmagicApi.PROCESS_TYPE_CAMERA_STREAM;
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "onDestroy: xmagicApi is null ");
            return;
        }
        xmagicApi.setTipsListener(null);
        xmagicApi.setAIDataListener(null);
        xmagicApi.onDestroy();
        xmagicApi = null;
    }

    @Deprecated
    public void updateProperty(XmagicProperty<XmagicProperty.XmagicPropertyValues> xmagicProperty) {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "updateProperty: xmagicApi is null ");
            return;
        }
        xmagicApi.updateProperty(xmagicProperty, new UpdatePropertyListener() {
            Gson gson = new Gson();

            @Override
            public void onAvatarCustomConfigParsingFailed(List<XmagicProperty<?>> list) {
                LogUtils.e(TAG, "updateProperty: onAvatarCustomConfigParsingFailed " + gson.toJson(list));
            }

            @Override
            public void onPropertyInvalid(List<XmagicProperty<?>> list) {
                LogUtils.e(TAG, "updateProperty: onPropertyInvalid " + gson.toJson(list));
            }

            @Override
            public void onPropertyNotSupport(List<XmagicProperty<?>> list) {
                LogUtils.e(TAG, "updateProperty: onPropertyNotSupport " + gson.toJson(list));
            }

            @Override
            public void onAvatarDataInvalid(List<AvatarData> list) {
                LogUtils.e(TAG, "updateProperty: onAvatarDataInvalid " + gson.toJson(list));
            }

            @Override
            public void onAssetLoadFinish(String s, boolean b) {
                LogUtils.e(TAG, "updateProperty: onAssetLoadFinish " + s + "  " + b);
            }
        });
    }

    public void setEffect(String effectName, int effectValue, String resourcePath, Map<String, String> extraInfo) {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "setEffect: xmagicApi is null ");
            return;
        }
        xmagicApi.setEffect(effectName, effectValue, resourcePath, extraInfo);
    }

    public int process(int textureId, int width, int height) {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "process: xmagicApi is null ");
            return textureId;
        }
        if (currentStreamType != XmagicApi.PROCESS_TYPE_CAMERA_STREAM) {
            currentStreamType = XmagicApi.PROCESS_TYPE_CAMERA_STREAM;
            setXMagicStreamType(currentStreamType);
        }
        return xmagicApi.process(textureId, width, height);
    }


    /**

     *
     * @param properties
     */
    public void isBeautyAuthorized(List<XmagicProperty<?>> properties) {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "isBeautyAuthorized: xmagicApi is null ");
            return;
        }
        xmagicApi.isBeautyAuthorized(properties);

    }

    /**

     *
     * @return
     */
    public boolean isSupportBeauty() {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "isSupportBeauty: xmagicApi is null ");
            return true;
        }
        return xmagicApi.isSupportBeauty();
    }

    /**
     *
     * @param assetsList
     */
    public void isDeviceSupport(List<XmagicProperty<?>> assetsList) {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "isDeviceSupport: xmagicApi is null ");
            return;
        }
        xmagicApi.isDeviceSupport(assetsList);
    }


    /**

     *
     * @param motionResPath
     */
    public boolean isDeviceSupport(String motionResPath) {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "isDeviceSupport: xmagicApi is null " + motionResPath);
            return false;
        }
        return xmagicApi.isDeviceSupport(motionResPath);
    }


    public Map<XmagicProperty<?>, ArrayList<String>> getPropertyRequiredAbilities(List<XmagicProperty<?>> assets) {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "getPropertyRequiredAbilities: xmagicApi is null ");
            return null;
        }
        return xmagicApi.getPropertyRequiredAbilities(assets);
    }


    public Map<String, Boolean> getDeviceAbilities() {
        if (xmagicApi == null) {
            return null;
        }
        return xmagicApi.getDeviceAbilities();
    }


    @Override
    public void onSensorChanged(SensorEvent event) {
        if (xmagicApi != null) {
            xmagicApi.sensorChanged(event, mAccelerometer);
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {

    }


    public void setApplicationContext(Context context) {
        mApplicationContext = context;
    }

    public Context getApplicationContext() {
        return mApplicationContext;
    }

    /**

     *
     * @return
     */
    public boolean xMagicApiIsNull() {
        return xmagicApi == null;
    }

    public void setManagerListener(XmagicManagerListener managerListener) {
        this.managerListener = managerListener;
    }

    public int getCurrentStreamType() {
        return currentStreamType;
    }


 
    public void enableEnhancedMode() {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "enableEnhancedMode: xmagicApi is null ");
            return;
        }
        xmagicApi.enableEnhancedMode();
    }


    
    public void setDowngradePerformance() {
        isPerformance = true;
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "setDowngradePerformance: xmagicApi is null ");
            return;
        }
        xmagicApi.setDowngradePerformance();
    }

   
    public void onPauseAudio() {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "onPauseAudio: xmagicApi is null ");
            return;
        }
        xmagicApi.onPauseAudio();
    }

   
    public void setAudioMute(boolean isMute) {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "setAudioMute: xmagicApi is null ");
            return;
        }
        xmagicApi.setAudioMute(isMute);
    }

    
    public void setFeatureEnableDisable(String featureName, boolean enable) {
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "setFeatureEnableDisable: xmagicApi is null ");
            return;
        }
        xmagicApi.setFeatureEnableDisable(featureName, enable);
    }


    
    public void setImageOrientation(int rotationType) {
        TEImageOrientation orientation = null;
        switch (rotationType) {
            case 0:
                orientation = TEImageOrientation.ROTATION_0;
                break;
            case 1:
                orientation = TEImageOrientation.ROTATION_90;
                break;
            case 2:
                orientation = TEImageOrientation.ROTATION_180;
                break;
            case 3:
                orientation = TEImageOrientation.ROTATION_270;
                break;
            default:
                LogUtils.e(TAG, "setImageOrientation: rotationType = " + rotationType);
                return;
        }
        if (xMagicApiIsNull()) {
            LogUtils.e(TAG, "setImageOrientation: xmagicApi is null ");
            return;
        }
        if (mSensorManager != null) {
            mSensorManager.unregisterListener(this);
            mSensorManager = null;
        }
        xmagicApi.setImageOrientation(orientation);
    }

    
    public void enableAIDataListener(boolean enable) {
        this.enableAiData = enable;
        if (this.xmagicApi != null) {
            if (enable) {
                this.xmagicApi.setAIDataListener(this);
            } else {
                this.xmagicApi.setAIDataListener(null);
            }
        }
        LogUtils.d(TAG, "enableAIDataListener: enable = " + enable);
    }

    
    public void enableYTDataListener(boolean enable) {
        this.enableYTData = enable;
        if (this.xmagicApi != null) {
            if (enable) {
                this.xmagicApi.setAIDataListener(this);
            } else {
                this.xmagicApi.setAIDataListener(null);
            }
        }
        LogUtils.d(TAG, "enableYTDataListener: enable = " + enable);
    }

     
    public void enableTipsListener(boolean enable) {
        this.enableTipsListener = enable;
        if (this.xmagicApi != null) {
            if (enable) {
                this.xmagicApi.setTipsListener(this);
            } else {
                this.xmagicApi.setTipsListener(null);
            }
        }
        LogUtils.d(TAG, "enableTipsListener: enable = " + enable);
    }


    @Override
    public void onFaceDataUpdated(List<TEFaceData> list) {
        if (!enableAiData || list == null || managerListener == null) {
            return;
        }
        managerListener.onFaceDataUpdated(new Gson().toJson(list));
    }

    @Override
    public void onHandDataUpdated(List<TEHandData> list) {
        if (!enableAiData || list == null || managerListener == null) {
            return;
        }
        managerListener.onHandDataUpdated(new Gson().toJson(list));
    }

    @Override
    public void onBodyDataUpdated(List<TEBodyData> list) {
        if (!enableAiData || list == null || managerListener == null) {
            return;
        }
        managerListener.onBodyDataUpdated(new Gson().toJson(list));
    }

    @Override
    public void onAIDataUpdated(String s) {
        if (enableYTData && managerListener != null) {
            managerListener.onYTDataUpdate(s);
        }
    }

    @Override
    public void tipsNeedShow(String tips, String tipsIcon, int type, int duration) {
        if (enableTipsListener && managerListener != null) {
            managerListener.tipsNeedShow(tips, tipsIcon, type, duration);
        }
    }

    @Override
    public void tipsNeedHide(String tips, String tipsIcon, int type) {
        if (enableTipsListener && managerListener != null) {
            managerListener.tipsNeedHide(tips, tipsIcon, type);
        }
    }

    interface InitModelResourceCallBack {
        void onResult(boolean isCopySuccess);
    }


}

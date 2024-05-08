// NOCA:CopyrightChecker
package com.tencent.effect.tencent_effect_flutter.res;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;

import com.tencent.effect.tencent_effect_flutter.utils.LogUtils;
import com.tencent.xmagic.XmagicApi;
import com.tencent.xmagic.util.FileUtil;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;


/**
 * tencent_effect_flutter
 * Created by kevinxlhua on 2022/8/12.
 * Copyright (c) 2020 Tencent. All rights reserved
 */


public class XmagicResParser {

    private static final String TAG = XmagicResParser.class.getSimpleName();

    /**
     * xmagic resource local path
     */
    private static String sResPath;


    /**
     * Direct use of such methods, need to pay attention to the order of use
     * 1. Call setResPath() to set the path for storing resources
     * 2. copyRes(Context context) Copy the resource file in the asset to the path set in the first step
     * 3. Call the parseRes() method to classify the resources
     * 4. Then you can use the methods of XmagicPanelView and XmagicPanelDataManager.getInstance() classes
     */
    private XmagicResParser() {/*nothing*/}

    /**

     * set the asset path
     *
     * @param path
     */
    public static void setResPath(String path) {
        if (!path.endsWith(File.separator)) {
            path = path + File.separator;
        }
        sResPath = path;
    }

    public static String getResPath() {
        ensureResPathAlreadySet();
        return sResPath;
    }

 
    public static boolean copyRes(Context context) {
        ensureResPathAlreadySet();

        if (TextUtils.isEmpty(sResPath)) {
            throw new IllegalStateException("resource path not set, call XmagicResParser.setResPath() first.");
        }
        int addResult = XmagicApi.addAiModeFilesFromAssets(context, sResPath);
        LogUtils.e(TAG, "add ai model files result = " + addResult);
        String lutDirName = "lut";
        boolean result = FileUtil.copyAssets(context, lutDirName, sResPath + "light_material" + File.separator + lutDirName);
        String motionResDirName = "MotionRes";
        boolean result2 = FileUtil.copyAssets(context, motionResDirName, sResPath + motionResDirName);
        return result && result2;
    }


    private static void ensureResPathAlreadySet() {
        if (TextUtils.isEmpty(sResPath)) {
            throw new IllegalStateException("resource path not set, call XmagicResParser.setResPath() first.");
        }
    }




}

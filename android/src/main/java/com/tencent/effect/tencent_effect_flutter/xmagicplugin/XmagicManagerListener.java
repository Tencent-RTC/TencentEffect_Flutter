package com.tencent.effect.tencent_effect_flutter.xmagicplugin;


/**
 * tencent_effect_flutter
 * Created by kevinxlhua on 2022/8/12.
 * Copyright (c) 2020 Tencent. All rights reserved
 */


public interface XmagicManagerListener {

   /**
      * Exception information callback method
      * @param errorMsg exception description
      * @param code error code, comparison table:
      * <li>-1: Unknown error. Unknown error</li>
      * <li>-100: 3D engine resource initialization failed. Failed to initialize the 3D engine resources </li>
      * <li>-200: GAN material is not supported. The GAN material is not supported</li>
      * <li>-300: The device does not support this material component. The device does not support this material component</li>
      * <li>-400: The template json content is empty. The JSON content in the template is empty</li>
      * <li>-500: The SDK version is too low. The SDK version is too low</li>
      // NOCA: InnerUsernameLeak (ignore reason)
      * <li>-600: Splitting is not supported. Head keying is not supported</li>
      * <li>-700: OpenGL is not supported. OpenGL is not supported</li>
      * <li>-800: Scripting is not supported. Script is not supported</li>
      * <li>5000: The resolution of the segmented background image exceeds 2160*3840. The resolution of the split background image exceeds 2160*3840</li>
      * <li>5001: Insufficient memory required to split the background image. Insufficient memory required to split the background image</li>
      * <li>5002: Parsing of segmented background video failed. Split background video parsing failed</li>
      * <li>5003: Split background video longer than 200 seconds. Split background video over 200 seconds</li>
      * <li>5004: Split background video format is not supported. Split background video format is not supported</li>
      * <li>9000: Some files in the application are missing and initialization failed. Some files in the application are lost, initialization failed</li>
      */
    void onXmagicPropertyError(String errorMsg, int code);

   /**
      * Show tips. Show the tip.
      * @param tips tips string. Tip's content
      * @param tipsIcon tips’ icon. Tip's icon
      * @param type tips category, 0 means both strings and icons are displayed, 1 means pag material only displays icons. tips category,
      * 0 means that both strings and icons are displayed,
      * 1 means that only the icon is displayed for the pag material
      * @param duration tips display duration, milliseconds. Tips display duration, milliseconds
      */
    void tipsNeedShow(String tips, String tipsIcon, int type, int duration);

   /**
      * Hide tips. Hide the tip.
      * @param tips tips string. Tip's content
      * @param tipsIcon tips’ icon. Tip's icon
      * @param type tips category, 0 means both strings and icons are displayed, 1 means pag material only displays icons.
      * tips category,
      * 0 means that both strings and icons are displayed,
      * 1 means that only the icon is displayed for the pag material
      */
    void tipsNeedHide(String tips, String tipsIcon, int type);

    void onFaceDataUpdated(String jsonData);
    void onHandDataUpdated(String jsonData);
    void onBodyDataUpdated(String jsonData);


    /**
     * Callback of Youtu AI data.
     * @param data String in JSON format.
     */
    void onYTDataUpdate(String data);
}

package com.tencent.effect.tencent_effect_flutter.xmagicplugin.view;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.view.View;
import android.widget.ImageView;

import androidx.annotation.NonNull;


import com.tencent.effect.tencent_effect_flutter.utils.LogUtils;

import io.flutter.plugin.platform.PlatformView;

/**
 * tencent_effect_flutter
 * Created by kevinxlhua on 2022/8/12.
 * Copyright (c) 2020 Tencent. All rights reserved
 */

public class XmagicImageView implements PlatformView {

    private static String TAG = XmagicImageView.class.getName();
    private ImageView imageView;
    private Bitmap bitmap;
    private int androidViewId;
    private DestroyViewListener destroyViewListener;

    XmagicImageView(int viewId, Context context, byte[] data, DestroyViewListener destroyViewListener) {
        this.androidViewId = viewId;
        this.destroyViewListener = destroyViewListener;
        imageView = new ImageView(context);
        if (data != null && data.length > 0) {
            bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);
            if (bitmap != null) {
                imageView.setImageBitmap(bitmap);
            }
        }
    }


    public Bitmap getBitmap() {
        return this.bitmap;
    }

    public void upDataBitmap(Bitmap bitmap) {
        if (imageView != null && bitmap != null) {
            imageView.setImageBitmap(bitmap);
        }
    }

    @Override
    public View getView() {
        return imageView;
    }

    @Override
    public void onFlutterViewAttached(@NonNull View flutterView) {
    }

    @Override
    public void onFlutterViewDetached() {
    }

    @Override
    public void dispose() {
        if (bitmap != null) {
            bitmap.recycle();
            bitmap = null;
        }
        if (destroyViewListener != null) {
            destroyViewListener.onDestroy(androidViewId);
        }
        LogUtils.d(TAG, "dispose method is invoke");
    }

    @Override
    public void onInputConnectionLocked() {
    }

    @Override
    public void onInputConnectionUnlocked() {
    }
}

package com.tencent.effect.tencent_effect_flutter.xmagicplugin.view;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

/**
 * tencent_effect_flutter
 * Created by kevinxlhua on 2022/8/12.
 * Copyright (c) 2020 Tencent. All rights reserved
 */

public class XmagicImageViewFactory extends PlatformViewFactory implements DestroyViewListener {

    private Map<Integer, XmagicImageView> mViewMap = new HashMap<>();


    public XmagicImageViewFactory() {
        super(StandardMessageCodec.INSTANCE);
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        byte[] data = null;
        if (args instanceof byte[]) {
            data = (byte[]) args;
        }
        XmagicImageView view = mViewMap.get(viewId);
        if (view == null) {
            view = new XmagicImageView(viewId, context, data, this);
            mViewMap.put(viewId, view);
        }
        return view;
    }

    public XmagicImageView getImageView(int viewId) {
        return mViewMap.get(viewId);
    }

    @Override
    public void onDestroy(int viewId) {
        if (mViewMap.containsKey(viewId)) {
            mViewMap.remove(viewId);
        }
    }
}

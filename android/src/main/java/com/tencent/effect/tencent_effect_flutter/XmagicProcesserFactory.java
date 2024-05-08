package com.tencent.effect.tencent_effect_flutter;

import android.os.Looper;
import android.util.Log;

import com.tencent.effect.tencent_effect_flutter.xmagicplugin.XmagicApiManager;
import com.tencent.live.beauty.custom.ITXCustomBeautyProcesser;
import com.tencent.live.beauty.custom.ITXCustomBeautyProcesserFactory;
import com.tencent.live.beauty.custom.TXCustomBeautyDef;
import com.tencent.live.beauty.custom.TXCustomBeautyDef.TXCustomBeautyVideoFrame;

/**
 * tencent_effect_flutter
 * Created by kevinxlhua on 2022/8/12.
 * Copyright (c) 2020 Tencent. All rights reserved
 */


public class XmagicProcesserFactory implements ITXCustomBeautyProcesserFactory {

    private static String TAG=XmagicProcesserFactory.class.getName();

    private XmagicProcesser processer;


    @Override
    public ITXCustomBeautyProcesser createCustomBeautyProcesser() {
        if (processer == null) {
            processer = new XmagicProcesser();
        }
        processer.create();
        Log.d(TAG,"createCustomBeautyProcesser  threadName = " + Thread.currentThread().getName());
        return processer;
    }

    @Override
    public void destroyCustomBeautyProcesser() {
        if(processer!=null){
            Log.d(TAG,"destroyCustomBeautyProcesser destroy xmagic  threadName = "
                    + Thread.currentThread().getName());
            if (Thread.currentThread() != Looper.getMainLooper().getThread()) { //
                processer.destroy();
            }
        }
    }

    public static class XmagicProcesser implements ITXCustomBeautyProcesser {


        void create() {
            XmagicApiManager.getInstance().onCreateApi();
        }

        void destroy() {
            XmagicApiManager.getInstance().onDestroy();
        }


        @Override
        public TXCustomBeautyDef.TXCustomBeautyPixelFormat getSupportedPixelFormat() {
            return TXCustomBeautyDef.TXCustomBeautyPixelFormat.TXCustomBeautyPixelFormatTexture2D;
        }

        @Override
        public TXCustomBeautyDef.TXCustomBeautyBufferType getSupportedBufferType() {
            return TXCustomBeautyDef.TXCustomBeautyBufferType.TXCustomBeautyBufferTypeTexture;
        }

        @Override
        public void onProcessVideoFrame(TXCustomBeautyVideoFrame srcFrame, TXCustomBeautyVideoFrame dstFrame) {
            dstFrame.texture.textureId = XmagicApiManager.getInstance()
                    .process(srcFrame.texture.textureId, srcFrame.width, srcFrame.height);
        }
    }
}

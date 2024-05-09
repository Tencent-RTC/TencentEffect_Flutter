简体中文  |  [English](https://github.com/Tencent-RTC/TencentEffect_Flutter/blob/main/README.md)

## 目录结构

```
├── android	//flutter plugin android目录
│   ├── gradle    //Android gradle
│   ├── libs      //存放xmagic的原生android sdk
│   └── src       //flutter plugin android 代码目录
├── demo	// demo 目录
│   ├── android   //demo android 目录
│   ├── ios       //demo 的 ios工程目录
├── ios	//flutter plugin ios目录
│   ├── Assets    // 资源
│   └── Classes   //flutter plugin ios 代码目录
└── lib	//flutter plugin dart 接口代码
```

## 快速集成

### `pubspec.yaml`配置

**推荐flutter sdk 版本 3.0.0 及以上**

集成TencentEffect_Flutter版本,在`pubspec.yaml`中增加配置

```
 tencent_effect_flutter:
       git:
         url: https://github.com/Tencent-RTC/TencentEffect_Flutter
```

然后更新依赖包

```
flutter packages get
```


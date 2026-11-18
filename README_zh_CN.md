简体中文  |  [English](https://github.com/Tencent-RTC/TencentEffect_Flutter/blob/main/README.md)

## 目录结构

```
├── android	//flutter plugin android目录
│   ├── gradle    //Android gradle
│   └── src       //flutter plugin android 代码目录
├── demo	// demo 目录
│   ├── android   //demo android 目录
│   ├── ios       //demo 的 ios工程目录
├── ios	//flutter plugin ios目录
│   ├── Assets    // 资源
│   └── tencent_effect_flutter          //flutter plugin ios 包目录
│       ├── Package.swift               //Swift Package Manager 清单
│       └── Sources/tencent_effect_flutter  //flutter plugin ios 代码目录
└── lib	//flutter plugin dart 接口代码
```

## 快速集成

### `pubspec.yaml`配置

**CocoaPods 集成：推荐 flutter sdk 版本 3.0.0 及以上**

**Swift Package Manager 集成：要求 flutter sdk 版本 3.44.0 及以上**

**iOS 系统最低版本：12.0**

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

### 套餐配置

在**宿主工程**的 `pubspec.yaml` 中指定所购买的套餐，Android 与 iOS 共用这一份配置（iOS 端的 CocoaPods 与 Swift Package Manager 两种集成方式也均以此为唯一配置来源）：

```yaml
TencentEffect:
  te_sub_spec: 'S1-07'
```

请将 `te_sub_spec` 配置为您实际购买的套餐。未配置或填写了非法值时，默认使用 `S1-07`。

> 注意：使用 Swift Package Manager 集成时，Xcode 会缓存依赖解析结果。修改 `te_sub_spec` 后如未生效，请在 Xcode 中执行 File → Packages → Reset Package Caches，然后重新构建。


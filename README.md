[简体中文](https://github.com/Tencent-RTC/TencentEffect_Flutter/blob/main/README_zh_CN.md)  |  English

## Directory Structure

```
├── android	//flutter plugin android dir
│   ├── gradle    //Android gradle
│   └── src       //flutter plugin android code
├── demo	// demo dir
│   ├── android   //demo android dir
│   ├── ios       //demo  ios
├── ios	//flutter plugin ios dir
│   ├── Assets    // resource
│   └── tencent_effect_flutter          //flutter plugin ios package dir
│       ├── Package.swift               //Swift Package Manager manifest
│       └── Sources/tencent_effect_flutter  //flutter plugin ios code
└── lib	//flutter plugin dart api
```

## Fast integration

### `pubspec.yaml` Configuration

**CocoaPods integration: flutter sdk 3.0.0 and above is recommended**

**Swift Package Manager integration: flutter sdk 3.44.0 or later is required**

**Minimum iOS version: 12.0**

Integrate TencentEffect_Flutter version and add configuration in `pubspec.yaml`

```
 tencent_effect_flutter:
       git:
         url: https://github.com/Tencent-RTC/TencentEffect_Flutter
```

Update the dependency packages

```
flutter packages get
```

### Sub-spec Configuration

Specify the sub-spec you purchased in the `pubspec.yaml` of your **host project**. Android and iOS share this single configuration (on iOS, it is also the only configuration source for both CocoaPods and Swift Package Manager integration):

```yaml
TencentEffect:
  te_sub_spec: 'S1-07'
```

Set `te_sub_spec` to the sub-spec you actually purchased. If it is not configured or the value is invalid, `S1-07` is used by default.

> Note: When integrating with Swift Package Manager, Xcode caches the dependency resolution result. If a change to `te_sub_spec` does not take effect, run File → Packages → Reset Package Caches in Xcode and rebuild.

## Directory Structure
```
├── android	//flutter plugin android dir
│   ├── gradle    //Android gradle
│   ├── libs      //xmagic android sdk
│   └── src       //flutter plugin android code
├── demo	// demo dir
│   ├── android   //demo android dir
│   ├── ios       //demo  ios
├── ios	//flutter plugin ios dir
│   ├── Assets    // resource
│   └── Classes   //flutter plugin ios code
└── lib	//flutter plugin dart api
```

## Fast integration

### `pubspec.yaml` Configuration

**Recommended flutter sdk version 3.0.0 and above**

Integrate TencentEffect_Flutter version and add configuration in `pubspec.yaml`

```
 tencent_effect_flutter:
       git:
         url: https://github.com/TencentCloud/tencenteffect-sdk-flutter
```

Update the dependency packages

```
flutter packages get
```

### 
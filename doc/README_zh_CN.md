# 如何跑通demo

更多文档可参考[官网](https://cloud.tencent.com/document/product/616)：

## 1. 环境要求

- Flutter 3.0.0 及以上版本（使用 Swift Package Manager 集成 iOS 时要求 3.44.0 及以上）。

| Android 端开发：                   | iOS & macOS 端开发：                   |
| ---------------------------------- | -------------------------------------- |
| Android Studio 3.5及以上版本。     | Xcode 15.0及以上版本。                 |
| App 要求 Android 5.0及以上版本设备 | App 要求 iOS 12.0 及以上版本设备       |
|                                    | 请确保您的项目已设置有效的开发者签名。 |

## 2. 运行

   在demo中找到main.dart类填写上您申请的licenseKey和licenseUrl信息。

| Android                                                      | iOS                                                          |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1.在demo下执行flutter pub get，然后使用Android studio 打开demo工程，直接点击run按钮。 | 1.首次运行ios demo，进入到demo/ios/Flutter文件夹中，如果有flutter_export_environment.sh、Generated.xcconfig这两个文件，则删掉。 |
|                                                              | 2.在demo下执行flutter pub get，然后进入到ios中执行pod install。 |
|                                                              | 3.打开demo/ios里面的Runner.xcworkspace，编译完成以后即可运行。 |

## 3. **常见问题**

1.Visual Studio Code运行iOS端时报错“iOS Observatory not discovered after 30 seconds. This is taking much longer than expected”，无法Hot Reload

解决办法：在xcode中的Build Seetings的FLUTTER_BUILD_MODE的值改成debug

2.demo与xcode断开连接的时候无法运行

解决办法：在xcode中的Build Seetings的FLUTTER_BUILD_MODE的值改成release

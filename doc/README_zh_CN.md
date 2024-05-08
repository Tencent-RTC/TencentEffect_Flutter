# 如何跑通demo

更多文档可参考[官网](https://cloud.tencent.com/document/product/616)：

## 1. 环境要求

- Flutter 3.0.0 及以上版本。

| Android 端开发：                   | iOS & macOS 端开发：                   |
| ---------------------------------- | -------------------------------------- |
| Android Studio 3.5及以上版本。     | Xcode 11.0及以上版本。                 |
| App 要求 Android 5.0及以上版本设备 | osx 系统版本要求 10.11 及以上版本      |
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

## 4. flutter SDK和Android&iOS SDK的对应关系

| flutter 版本   | Android 版本        | iOS版本             |
| -------------- | ------------------- | ------------------- |
| 0.3.5.0        | 3.5.0               | 3.5.0               |
| 0.3.1.1        | 3.3.0、3.2.0        | 3.3.0、3.2.0        |
| 0.3.0.1、0.3.0 | 3.1.0、3.0.0、3.0.1 | 3.1.0、3.0.0、3.0.1 |
|                |                     |                     |
|                |                     |                     |

## 5. 版本日志

### V0.3.5.0

- 适配美颜V3.5.0版本api。
- demo中的美颜面板进行改版，支持从JSON文件中进行配置美颜数据。
- 优化initXmagic接口，删除此接口中的路径参数，客户在使用时，一个版本只需成功调用一次即可，设置路径通过setResourcePath方法。
- 更新美颜属性可以通过setEffect方法。
- 废弃isDeviceSupport方法，增加isDeviceSupportMotion方法来检测是否支持此动效。

### V0.3.1.1

- 新增性能模式
- 新增静音、设置人脸画面方向、开启或关闭某些特性 接口
- flutter新增动态设置资源文件的路径以及动态设置so的方法

### V0.3.0.1

- 修复bug

### V0.3.0

- 适配美颜V3.0.0版本接口
- 增加开启增强模式接口
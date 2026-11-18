# How to Run a Demo



For more documentation, refer to the [official website](https://www.tencentcloud.com/document/product/1143):

## 1. Environment Requirements

- Flutter 3.0.0 or later (3.44.0 or later is required when integrating iOS with Swift Package Manager).

| Developing for Android:            | Developing for iOS & macOS:            |
| ---------------------------------- | -------------------------------------- |
| Android Studio 3.5 or later.      | Xcode 15.0 or later.                 |
| Devices with Android 5.0 or above | Devices with iOS 12.0 or above        |
|                                    | Ensure your project has a valid developer signature. |

## 2. Run

   In the demo, find the main.dart class and fill in the licenseKey and licenseUrl information you applied for.

| Android                                                      | iOS                                                          |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1. Execute flutter pub get in the demo, then open the demo project with Android Studio and directly click the Run button. | 1. For the first run of the iOS demo, go to the demo/ios/Flutter folder. If there are files named flutter_export_environment.sh and Generated.xcconfig, delete them. |
|                                                              | 2. Execute flutter pub get in the demo, then go to iOS and execute pod install. |
|                                                              | 3. Open Runner.xcworkspace inside demo/ios, after compilation it can be run. |

## 3. **FAQs**

1. When running the iOS side on Visual Studio Code, an error "iOS Observatory not discovered after 30 seconds. This is taking much longer than expected" appears, preventing Hot Reload

Solution: Change the value of FLUTTER_BUILD_MODE in Build Settings in Xcode to debug

2. The demo cannot run when disconnected from Xcode

Solution: Change the value of FLUTTER_BUILD_MODE in Build Settings in Xcode to release


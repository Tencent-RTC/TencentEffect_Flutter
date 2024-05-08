# How to Run a Demo



For more documentation, refer to the [official website](https://www.tencentcloud.com/document/product/1143):

## 1. Environment Requirements

- Flutter 3.0.0 or later.

| Developing for Android:            | Developing for iOS & macOS:            |
| ---------------------------------- | -------------------------------------- |
| Android Studio 3.5 or later.      | Xcode 11.0 or later.                 |
| Devices with Android 5.0 or above | macOS version 10.11 or later         |
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

## 4. Corresponding Relationship between flutter SDK and Android & iOS SDKs

| Flutter version   | Android version        | iOS version             |
| -------------- | ------------------- | ------------------- |
| 3.6.0        | 3.6.0.4               | 3.6.0.3               |
| 0.3.5.0        | 3.5.0               | 3.5.0               |
| 0.3.1.1        | 3.3.0,3.2.0        | 3.3.0,3.2.0        |
| 0.3.0.1,0.3.0 | 3.1.0,3.0.0,3.0.1 | 3.1.0,3.0.0,3.0.1 |
|                |                     |                     |
|                |                     |                     |

## 5. Version Log

### V0.3.5.0

- Adaptation to Beauty V3.5.0 API.
- Redesign of the beauty panel in the demo, supporting configuration of beauty data from a JSON file.
- Optimization of the initXmagic interface, removal of path parameters in this interface. Customers need to successfully call it only once per version, with path settings via the setResourcePath method.
- Updating beauty attributes can be done through the setEffect method.
- Deprecated isDeviceSupport method, added isDeviceSupportMotion method to check if this animation effect is supported.

### V0.3.1.1

- New performance mode
- New mute function, set the direction of the face image, turn on or off certain features interface
- Flutter adds dynamic setting of resource file path and dynamic setting of so method

### V0.3.0.1

- Fix bugs

### V0.3.0

- Adaptation to Beauty V3.0.0 API
- Add enable enhanced mode interface


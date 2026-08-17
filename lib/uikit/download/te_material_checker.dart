import 'dart:io';
import '../../utils/te_logs.dart';
import '../model/te_ui_property.dart';

/// 素材检查器 - 用于检查素材是否已下载
class TEMaterialChecker {
  /// 下载完成的标记文件名
  /// 在解压成功后会在目标目录下创建此文件，用于判断下载和解压是否真正完成
  static const String downloadCompleteMarker = '.te_download_complete';

  /// 检查 TEMotionDLModel 对应的素材是否已下载
  /// 不需要解压的文件扩展名列表
  static const List<String> _noExtractExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp'];

  /// 检查文件是否为不需要解压的单文件资源
  static bool _isNoExtractFile(String? fileName) {
    if (fileName == null || fileName.isEmpty) return false;
    final lowerName = fileName.toLowerCase();
    return _noExtractExtensions.any((ext) => lowerName.endsWith(ext));
  }

  static Future<bool> isDownloaded(TEMotionDLModel? dlModel) async {
    if (dlModel == null) {
      return false;
    }

    String dirPath = dlModel.localDir!;
    final separator = Platform.pathSeparator;
    if (!dirPath.endsWith(separator)) {
      dirPath = '$dirPath$separator';
    }

    final fileName = dlModel.fileName;

    // 判断是否为单文件资源（如 .png 等图片文件）
    if (_isNoExtractFile(fileName)) {
      // 单文件资源：直接检查文件是否存在
      final filePath = '$dirPath$fileName';
      final exists = await File(filePath).exists();
      TXLog.i('[TEMaterialChecker] single file: $fileName, exists=$exists');
      return exists;
    }

    // 压缩包资源：检查解压目录下的标记文件
    final extractedPath = '$dirPath${dlModel.getFileNameNoZip()}';
    final markerFilePath = '$extractedPath$separator$downloadCompleteMarker';
    final exists = await File(markerFilePath).exists();
    TXLog.i('[TEMaterialChecker] zip file: $fileName, downloaded=$exists');
    return exists;
  }
}

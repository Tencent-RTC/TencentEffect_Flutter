import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../uikit/download/te_download_task.dart';
import '../../uikit/download/te_download_state.dart';
import '../../uikit/download/te_material_checker.dart';
import '../../utils/te_logs.dart';

import '../model/te_ui_property.dart';

/// 解压参数封装
class _ExtractParams {
  final String localFilePath;
  final String localDir;
  final String extractedFilePath;
  final String markerFileName;

  _ExtractParams({
    required this.localFilePath,
    required this.localDir,
    required this.extractedFilePath,
    required this.markerFileName,
  });
}

/// 后台解压函数
Future<void> _isolateExtractZip(_ExtractParams params) async {
  final zipFile = File(params.localFilePath);

  if (!await zipFile.exists()) {
    throw Exception('Zip file not found');
  }

  final bytes = await zipFile.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  
  final separator = Platform.pathSeparator;
  // 确保localDir末尾没有分隔符，避免双斜杠问题
  String localDir = params.localDir;
  if (localDir.endsWith(separator)) {
    localDir = localDir.substring(0, localDir.length - 1);
  }
  for (final file in archive) {
    final filename = file.name;
    final filePath = '$localDir$separator$filename';

    if (file.isFile) {
      final outFile = File(filePath);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    } else {
      final outDir = Directory(filePath);
      await outDir.create(recursive: true);
    }
  }

  // 删除zip文件
  await zipFile.delete();

  // 创建下载完成标记文件
  String extractedPath = params.extractedFilePath;
  if (extractedPath.endsWith(separator)) {
    extractedPath = extractedPath.substring(0, extractedPath.length - 1);
  }
  final markerFilePath = '$extractedPath$separator${params.markerFileName}';
  final markerFile = File(markerFilePath);
  await markerFile.create(recursive: true);
  await markerFile.writeAsString('Download completed at: ${DateTime.now().toIso8601String()}');
}

/// 下载管理器 - 单例模式
class TEDownloadManager {
  static TEDownloadManager? _instance;

  /// 获取单例实例
  static TEDownloadManager get instance {
    _instance ??= TEDownloadManager._internal();
    return _instance!;
  }

  TEDownloadManager._internal();

  /// 最大并发下载数
  int maxConcurrentDownloads = 3;

  /// 当前下载任务队列
  final Map<String, TEDownloadTask> _taskMap = {};

  /// 等待队列
  final List<TEDownloadTask> _waitingQueue = [];

  /// 正在下载的任务数
  int _activeDownloads = 0;

  /// 全局进度监听
  final List<TEDownloadProgressCallback> _globalProgressListeners = [];

  /// 全局状态监听
  final List<TEDownloadStateCallback> _globalStateListeners = [];

  /// 添加全局进度监听
  void addProgressListener(TEDownloadProgressCallback listener) {
    _globalProgressListeners.add(listener);
  }

  /// 移除全局进度监听
  void removeProgressListener(TEDownloadProgressCallback listener) {
    _globalProgressListeners.remove(listener);
  }

  /// 添加全局状态监听
  void addStateListener(TEDownloadStateCallback listener) {
    _globalStateListeners.add(listener);
  }

  /// 移除全局状态监听
  void removeStateListener(TEDownloadStateCallback listener) {
    _globalStateListeners.remove(listener);
  }

  /// 下载 TEUIProperty 对应的素材
  ///
  /// [uiProperty] 要下载的UI属性（调用前需要确保 uiProperty.dlModel 已设置）
  /// [onProgress] 进度回调
  /// [onStateChanged] 状态变化回调
  ///
  /// 返回下载结果
  ///
  /// 注意：调用此方法前，应该先调用 TEMaterialChecker.checkMaterial() 检查是否需要下载
  Future<TEDownloadResult> downloadMaterial(
    TEUIProperty uiProperty, {
    TEDownloadProgressCallback? onProgress,
    TEDownloadStateCallback? onStateChanged,
  }) async {
    // 直接使用 uiProperty.dlModel（调用方已经通过 checkMaterial 确认需要下载）
    final dlModel = uiProperty.dlModel;
    if (dlModel == null) {
      TXLog.e('[TEDownloadManager] Error: dlModel is null');
      return TEDownloadResult.failure('Download model is null');
    }
    String url = dlModel.url!;
    // 先检查是否已有相同URL的下载任务，避免重复创建
    if (_taskMap.containsKey(url)) {
      final existingTask = _taskMap[url]!;
      if (existingTask.state == TEDownloadState.downloading ||
          existingTask.state == TEDownloadState.waiting ||
          existingTask.state == TEDownloadState.extracting) {
        // 已有下载任务正在进行，等待现有任务完成
        TXLog.d('[TEDownloadManager] Waiting for existing task: ${existingTask.state}');
        return await _waitForTask(existingTask);
      }
    }

    // 创建下载任务
    TXLog.i('[TEDownloadManager] Creating task: ${dlModel.fileName}');
    dlModel.localDir = dlModel.localDir!;
    final task = TEDownloadTask.fromDLModel(dlModel);
    task.onProgress = (url, received, total, progress) {
      onProgress?.call(url, received, total, progress);
      _notifyProgress(url, received, total, progress);
    };
    task.onStateChanged = (url, state) {
      TXLog.d('[TEDownloadManager] State: $state');
      onStateChanged?.call(url, state);
      _notifyStateChanged(url, state);
    };

    // 执行下载
    return await _executeDownload(task);
  }

  /// 执行下载任务
  Future<TEDownloadResult> _executeDownload(TEDownloadTask task) async {
    final url = task.url;

    // 检查是否已有相同URL的任务
    if (_taskMap.containsKey(url)) {
      final existingTask = _taskMap[url]!;
      if (existingTask.state == TEDownloadState.downloading || existingTask.state == TEDownloadState.waiting) {
        return await _waitForTask(existingTask);
      }
    }

    // 添加到任务队列
    _taskMap[url] = task;

    // 检查并发数
    if (_activeDownloads >= maxConcurrentDownloads) {
      TXLog.d('[TEDownloadManager] Max concurrent reached, queuing task');
      task.updateState(TEDownloadState.waiting);
      _waitingQueue.add(task);
      return await _waitForTask(task);
    }

    return await _startDownload(task);
  }

  /// 开始下载
  Future<TEDownloadResult> _startDownload(TEDownloadTask task) async {
    _activeDownloads++;
    TXLog.i('[TEDownloadManager] Start download: ${task.fileName}');
    task.updateState(TEDownloadState.downloading);

    try {
      // 确保目录存在
      final dir = Directory(task.localDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 下载文件
      final response = await _downloadFile(task);
      
      // 检查是否被取消
      if (task.state == TEDownloadState.cancelled) {
        TXLog.i('[TEDownloadManager] Download task cancelled: ${task.fileName}');
        return TEDownloadResult.cancelled();
      }

      if (!response) {
        throw Exception('Download failed');
      }

      // 如果是zip文件，进行解压
      if (task.isZipFile) {
        task.updateState(TEDownloadState.extracting);
        await _extractZip(task);
      }
      
      // 解压过程中也可能被取消，再次检查
      if (task.state == TEDownloadState.cancelled) {
         TXLog.i('[TEDownloadManager] Download task cancelled during extraction: ${task.fileName}');
         return TEDownloadResult.cancelled();
      }

      task.updateState(TEDownloadState.completed);
      TXLog.i('[TEDownloadManager] Download completed: ${task.fileName}');
      return TEDownloadResult.success(task.extractedFilePath);
    } catch (e) {
      // 如果已经是取消状态，就不视为失败
      if (task.state == TEDownloadState.cancelled) {
         return TEDownloadResult.cancelled();
      }
      
      TXLog.e('[TEDownloadManager] Download failed: ${task.fileName}, error=$e');
      task.errorMessage = e.toString();
      task.updateState(TEDownloadState.failed);
      return TEDownloadResult.failure(e.toString());
    } finally {
      _activeDownloads--;
      _taskMap.remove(task.url);
      _processWaitingQueue();
    }
  }

  /// 下载文件
  Future<bool> _downloadFile(TEDownloadTask task) async {
    final client = http.Client();
    IOSink? sink;
    try {
      final trimmedUrl = task.url.trim();
      final request = http.Request('GET', Uri.parse(trimmedUrl));
      // 发送请求，设置30秒超时
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 30));

      if (streamedResponse.statusCode != 200) {
        TXLog.e('[TEDownloadManager] Download failed, status=${streamedResponse.statusCode}');
        return false;
      }

      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;

      final file = File(task.localFilePath);
      sink = file.openWrite();

      await for (final chunk in streamedResponse.stream) {
        // 检查是否已取消
        if (task.state == TEDownloadState.cancelled) {
          TXLog.i('[TEDownloadManager] Download cancelled: ${task.fileName}');
          return false;
        }

        sink.add(chunk);
        receivedBytes += chunk.length;
        task.updateProgress(receivedBytes, totalBytes);
      }

      await sink.flush();
      return true;
    } catch (e) {
      TXLog.e('[TEDownloadManager] Download error: $e');
      return false;
    } finally {
      await sink?.close();
      client.close();
    }
  }

  /// 解压zip文件
  Future<void> _extractZip(TEDownloadTask task) async {
    TXLog.d('[TEDownloadManager] Starting extraction in isolate');
    
    final params = _ExtractParams(
      localFilePath: task.localFilePath,
      localDir: task.localDir,
      extractedFilePath: task.extractedFilePath,
      markerFileName: TEMaterialChecker.downloadCompleteMarker,
    );

    await compute(_isolateExtractZip, params);
    
    TXLog.d('[TEDownloadManager] Extraction completed');
  }

  /// 等待任务完成
  Future<TEDownloadResult> _waitForTask(TEDownloadTask task) async {
    // 如果任务已经完成，直接返回结果
    if (task.state == TEDownloadState.completed) {
      return TEDownloadResult.success(task.extractedFilePath);
    } else if (task.state == TEDownloadState.failed) {
      return TEDownloadResult.failure(task.errorMessage ?? 'Unknown error');
    } else if (task.state == TEDownloadState.cancelled) {
      return TEDownloadResult.cancelled();
    }

    final completer = Completer<TEDownloadResult>();

    void stateListener(String url, TEDownloadState state) {
      if (url == task.url) {
        if (state == TEDownloadState.completed) {
          if (!completer.isCompleted) {
            completer.complete(TEDownloadResult.success(task.extractedFilePath));
          }
        } else if (state == TEDownloadState.failed) {
          if (!completer.isCompleted) {
            completer.complete(TEDownloadResult.failure(task.errorMessage ?? 'Unknown error'));
          }
        } else if (state == TEDownloadState.cancelled) {
          if (!completer.isCompleted) {
            completer.complete(TEDownloadResult.cancelled());
          }
        }
      }
    }

    addStateListener(stateListener);

    try {
      return await completer.future;
    } finally {
      removeStateListener(stateListener);
    }
  }

  /// 处理等待队列
  void _processWaitingQueue() {
    while (_waitingQueue.isNotEmpty && _activeDownloads < maxConcurrentDownloads) {
      final task = _waitingQueue.removeAt(0);
      _startDownload(task);
    }
  }

  /// 取消下载
  void cancelDownload(String url) {
    final task = _taskMap[url];
    if (task != null) {
      task.updateState(TEDownloadState.cancelled);
      _taskMap.remove(url);
      _waitingQueue.remove(task);
    }
  }

  /// 取消所有下载
  void cancelAllDownloads() {
    for (final task in _taskMap.values) {
      task.updateState(TEDownloadState.cancelled);
    }
    _taskMap.clear();
    _waitingQueue.clear();
    _activeDownloads = 0;
  }

  /// 获取下载任务状态
  TEDownloadState? getTaskState(String url) {
    return _taskMap[url]?.state;
  }

  /// 获取下载任务进度
  double? getTaskProgress(String url) {
    return _taskMap[url]?.progress;
  }

  /// 是否正在下载
  bool isDownloading(String url) {
    final state = _taskMap[url]?.state;
    return state == TEDownloadState.downloading ||
        state == TEDownloadState.waiting ||
        state == TEDownloadState.extracting;
  }

  /// 通知进度变化
  void _notifyProgress(String url, int received, int total, double progress) {
    // 使用列表副本遍历，避免回调中修改列表导致异常
    final listeners = List<TEDownloadProgressCallback>.from(_globalProgressListeners);
    for (final listener in listeners) {
      listener(url, received, total, progress);
    }
  }

  /// 通知状态变化
  void _notifyStateChanged(String url, TEDownloadState state) {
    // 使用列表副本遍历，避免回调中修改列表导致异常
    final listeners = List<TEDownloadStateCallback>.from(_globalStateListeners);
    for (final listener in listeners) {
      listener(url, state);
    }
  }
}


import 'package:flutter/foundation.dart';

/// 日志级别枚举
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// TencentEffect Flutter 日志工具类
class TXLog {
  TXLog._();

  /// 默认日志标签
  static const String _defaultTag = 'TencentEffect';

  /// 当前日志级别，低于此级别的日志不会输出
  static LogLevel _logLevel = LogLevel.debug;

  /// 是否启用日志
  static bool _enabled = true;

  /// 设置日志级别
  static void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  /// 启用/禁用日志
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 通用日志输出方法
  static void printlog(String log, {String? tag}) {
    _log(LogLevel.debug, log, tag: tag);
  }

  /// Verbose 级别日志
  static void v(String message, {String? tag}) {
    _log(LogLevel.verbose, message, tag: tag);
  }

  /// Debug 级别日志
  static void d(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// Info 级别日志
  static void i(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Warning 级别日志
  static void w(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  /// Error 级别日志
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// 内部日志输出方法
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // 仅在 Debug 模式下输出日志
    if (!kDebugMode || !_enabled) {
      return;
    }

    // 检查日志级别
    if (level.index < _logLevel.index) {
      return;
    }

    final String logTag = tag ?? _defaultTag;
    final String levelStr = _getLevelString(level);
    final String timestamp = _formatTimestamp(DateTime.now());

    // 格式化日志输出
    final StringBuffer buffer = StringBuffer();
    buffer.write('$timestamp [$levelStr/$logTag] $message');

    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    if (stackTrace != null) {
      buffer.write('\n  StackTrace: $stackTrace');
    }

    // 根据日志级别使用不同的输出方式
    if (level == LogLevel.error) {
      debugPrint('\x1B[31m${buffer.toString()}\x1B[0m'); // 红色
    } else if (level == LogLevel.warning) {
      debugPrint('\x1B[33m${buffer.toString()}\x1B[0m'); // 黄色
    } else if (level == LogLevel.info) {
      debugPrint('\x1B[32m${buffer.toString()}\x1B[0m'); // 绿色
    } else {
      debugPrint(buffer.toString());
    }
  }

  /// 获取日志级别字符串
  static String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 'V';
      case LogLevel.debug:
        return 'D';
      case LogLevel.info:
        return 'I';
      case LogLevel.warning:
        return 'W';
      case LogLevel.error:
        return 'E';
    }
  }

  /// 格式化时间戳
  static String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}.'
        '${dateTime.millisecond.toString().padLeft(3, '0')}';
  }
}
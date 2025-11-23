import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// 录音状态枚举
enum RecordingStatus {
  /// 未开始录音
  idle,
  /// 正在录音
  recording,
  /// 已暂停录音
  paused,
  /// 录音已完成
  completed,
  /// 出错
  error,
}

/// 录音错误类
class RecordingException implements Exception {
  /// 错误消息
  final String message;

  /// 错误代码
  final String? code;

  const RecordingException(this.message, [this.code]);

  @override
  String toString() => 'RecordingException: $message${code != null ? ' (code: $code)' : ''}';
}

/// 录音数据类
class RecordingData {
  /// 录音文件路径
  final String filePath;

  /// 录音时长（毫秒）
  final int duration;

  /// 录音开始时间
  final DateTime startTime;

  /// 录音结束时间
  final DateTime? endTime;

  const RecordingData({
    required this.filePath,
    required this.duration,
    required this.startTime,
    this.endTime,
  });

  @override
  String toString() => 'RecordingData(filePath: $filePath, duration: $duration, startTime: $startTime, endTime: $endTime)';
}

/// 音频录制器类
class AudioRecorder {
  /// 方法通道
  static const MethodChannel _channel = MethodChannel('assistx/audio_recorder');

  /// 录音状态流控制器
  final StreamController<RecordingStatus> _statusController = StreamController.broadcast();

  /// 录音数据
  RecordingData? _recordingData;

  /// 当前状态
  RecordingStatus _status = RecordingStatus.idle;

  /// 计时器
  Timer? _timer;

  /// 录音开始时间
  DateTime? _startTime;

  /// 已录制时长（毫秒）
  int _duration = 0;

  /// 暂停开始时间
  DateTime? _pauseStartTime;

  /// 总暂停时长（毫秒）
  int _totalPauseDuration = 0;

  /// 获取录音状态流
  Stream<RecordingStatus> get statusStream => _statusController.stream;

  /// 获取当前状态
  RecordingStatus get status => _status;

  /// 获取当前录音时长（毫秒）
  int get duration => _duration;

  /// 获取录音数据
  RecordingData? get recordingData => _recordingData;

  /// 开始录音
  Future<void> startRecording() async {
    try {
      // 检查权限
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        // 尝试请求权限
        final requestedPermission = await requestPermission();
        if (!requestedPermission) {
          throw const RecordingException('录音权限被拒绝');
        }
      }

      // 如果正在暂停中，则恢复录音
      if (_status == RecordingStatus.paused) {
        await _resumeRecording();
        return;
      }

      // 如果已经在录音中，则不做处理
      if (_status == RecordingStatus.recording) {
        return;
      }

      // 重置状态
      _reset();

      // 创建录音文件
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // 使用临时文件路径（实际使用时需要在平台端处理存储位置）
      final filePath = 'recording_$timestamp.aac';

      // 调用原生方法开始录音
      await _channel.invokeMethod('startRecording', {'path': filePath});

      // 更新状态
      _startTime = DateTime.now();
      _recordingData = RecordingData(
        filePath: filePath,
        duration: 0,
        startTime: _startTime!,
      );

      await _setStatus(RecordingStatus.recording);

      // 开始计时
      _startTimer();
    } on PlatformException catch (e) {
      await _handleError(e);
    } catch (e) {
      await _setStatus(RecordingStatus.error);
      throw const RecordingException('开始录音失败');
    }
  }

  /// 暂停录音
  Future<void> pauseRecording() async {
    try {
      if (_status != RecordingStatus.recording) {
        return;
      }

      // 调用原生方法暂停录音
      await _channel.invokeMethod('pauseRecording');

      // 记录暂停开始时间
      _pauseStartTime = DateTime.now();

      // 停止计时器
      _stopTimer();

      await _setStatus(RecordingStatus.paused);
    } on PlatformException catch (e) {
      await _handleError(e);
    } catch (e) {
      await _setStatus(RecordingStatus.error);
      throw const RecordingException('暂停录音失败');
    }
  }

  /// 恢复录音
  Future<void> _resumeRecording() async {
    try {
      if (_status != RecordingStatus.paused || _pauseStartTime == null) {
        return;
      }

      // 计算暂停时长
      final pauseDuration = DateTime.now().difference(_pauseStartTime!).inMilliseconds;
      _totalPauseDuration += pauseDuration;
      _pauseStartTime = null;

      // 调用原生方法恢复录音
      await _channel.invokeMethod('resumeRecording');

      // 重新开始计时
      _startTimer();

      await _setStatus(RecordingStatus.recording);
    } on PlatformException catch (e) {
      await _handleError(e);
    } catch (e) {
      await _setStatus(RecordingStatus.error);
      throw const RecordingException('恢复录音失败');
    }
  }

  /// 停止录音
  Future<RecordingData> stopRecording() async {
    try {
      if (_status != RecordingStatus.recording && _status != RecordingStatus.paused) {
        throw const RecordingException('没有正在进行的录音');
      }

      // 停止计时器
      _stopTimer();

      // 处理暂停时间
      if (_pauseStartTime != null) {
        final pauseDuration = DateTime.now().difference(_pauseStartTime!).inMilliseconds;
        _totalPauseDuration += pauseDuration;
        _pauseStartTime = null;
      }

      // 调用原生方法停止录音
      await _channel.invokeMethod('stopRecording');

      // 更新录音数据
      final endTime = DateTime.now();
      final finalDuration = _startTime != null
          ? endTime.difference(_startTime!).inMilliseconds - _totalPauseDuration
          : _duration;

      final data = _recordingData?.copyWith(
        duration: finalDuration,
        endTime: endTime,
      );

      if (data == null) {
        throw const RecordingException('录音数据无效');
      }

      _recordingData = data;

      await _setStatus(RecordingStatus.completed);

      return data;
    } on PlatformException catch (e) {
      await _handleError(e);
      rethrow;
    } catch (e) {
      await _setStatus(RecordingStatus.error);
      throw const RecordingException('停止录音失败');
    }
  }

  /// 检查权限
  Future<bool> _checkPermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// 请求权限
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// 设置状态
  Future<void> _setStatus(RecordingStatus status) async {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// 处理错误
  Future<void> _handleError(PlatformException e) async {
    await _setStatus(RecordingStatus.error);
    throw RecordingException(e.message ?? '录音错误', e.code);
  }

  /// 开始计时
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_startTime != null && _status == RecordingStatus.recording) {
        final currentTime = DateTime.now();
        _duration = currentTime.difference(_startTime!).inMilliseconds - _totalPauseDuration;
      }
    });
  }

  /// 停止计时
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 重置状态
  void _reset() {
    _stopTimer();
    _recordingData = null;
    _startTime = null;
    _duration = 0;
    _pauseStartTime = null;
    _totalPauseDuration = 0;
  }

  /// 释放资源
  void dispose() {
    _stopTimer();
    _statusController.close();
  }
}

/// 为RecordingData添加复制方法扩展
extension RecordingDataCopyWith on RecordingData {
  RecordingData copyWith({
    String? filePath,
    int? duration,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return RecordingData(
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
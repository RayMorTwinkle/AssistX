import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:assistx/shared/themes/app_theme.dart';
import 'package:assistx/core/audio/audio_recorder.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordingControls extends StatefulWidget {
  const RecordingControls({super.key});

  @override
  State<RecordingControls> createState() => _RecordingControlsState();
}

class _RecordingControlsState extends State<RecordingControls> with SingleTickerProviderStateMixin {
  late final AudioRecorder _recorder;
  RecordingStatus _status = RecordingStatus.idle;
  int _duration = 0;
  Timer? _durationTimer;
  bool _isMounted = false;
  
  // 动画控制器
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _recorder = AudioRecorder();
    
    // 初始化脉冲动画
    _pulseController = AnimationController(
      vsync: this,
      duration: AppTheme.animationMedium,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // 设置动画循环
    _pulseAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed && _status == RecordingStatus.recording) {
        _pulseController.forward();
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _durationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
      // 提供震动反馈
      HapticFeedback.vibrate();
      
      if (_status == RecordingStatus.idle) {
        // 主动请求权限
        final hasPermission = await _recorder.requestPermission();
        if (!hasPermission) {
          // 权限被拒绝，显示引导对话框
          if (_isMounted && context.mounted) {
            _showPermissionDeniedDialog();
          }
          return;
        }
        
        // 开始录音
        await _recorder.startRecording();
        _startDurationTimer();
        _startPulseAnimation();
      } else if (_status == RecordingStatus.recording) {
        // 暂停录音
        await _recorder.pauseRecording();
        _stopDurationTimer();
        _stopPulseAnimation();
      } else if (_status == RecordingStatus.paused) {
        // 继续录音 - AudioRecorder没有resumeRecording方法，使用startRecording替代
        await _recorder.startRecording();
        _startDurationTimer();
        _startPulseAnimation();
      }
      
      // 更新状态
      setState(() {
        _status = _recorder.status;
      });
    } catch (e) {
      // 错误处理
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isMounted && context.mounted) {
          // 检查是否为权限相关错误
          if (e.toString().contains('录音权限被拒绝')) {
            _showPermissionDeniedDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('操作失败: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      });
    }
  }
  
  /// 显示权限被拒绝对话框，提供引导去设置
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('需要录音权限'),
        content: Text('请在设置中允许应用访问麦克风以进行录音操作。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 打开应用设置
              await openAppSettings();
            },
            child: Text('去设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRecording() async {
    try {
      // 提供震动反馈
    HapticFeedback.vibrate();
      
      _stopDurationTimer();
      _stopPulseAnimation();
      
      await _recorder.stopRecording();
      
      // 重置状态
      if (_isMounted) {
        setState(() {
          _status = _recorder.status;
          _duration = 0;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isMounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('录音已保存'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isMounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('停止录音失败: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isMounted) {
        setState(() {
          _duration++;
        });
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
  }

  void _startPulseAnimation() {
    if (!_pulseController.isAnimating) {
      _pulseController.forward();
    }
  }

  void _stopPulseAnimation() {
    _pulseController.stop();
    _pulseController.value = 1.0;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final isRecordingActive = _status == RecordingStatus.recording;
    final isRecordingStarted = _status != RecordingStatus.idle;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 录音时长显示
        if (isRecordingStarted)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              _formatDuration(_duration),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        
        // 录音按钮
        Stack(
          alignment: Alignment.center,
          children: [
            // 脉冲动画
            if (isRecordingActive)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 160 * _pulseAnimation.value,
                    height: 160 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.error.withAlpha(77),
                    ),
                  );
                },
              ),
            
            // 主按钮
            GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecordingActive
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  isRecordingActive
                      ? Icons.pause
                      : Icons.mic,
                  size: 64,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        
        // 停止按钮
        if (isRecordingStarted)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: ElevatedButton(
              onPressed: _stopRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: AppTheme.paddingM,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child: const Text('停止录音'),
            ),
          ),
        
        // 状态提示文本
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            _getStatusText(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179)
                ),
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    switch (_status) {
      case RecordingStatus.recording:
        return '正在录音...';
      case RecordingStatus.paused:
        return '录音已暂停';
      case RecordingStatus.idle:
      default:
        return '点击开始录音';
    }
  }
}
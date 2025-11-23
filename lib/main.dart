import 'dart:async';
import 'package:flutter/material.dart';
import 'package:assistx/shared/themes/app_theme.dart';
import 'package:assistx/shared/widgets/responsive_layout.dart';
import 'package:assistx/core/audio/audio_recorder.dart';

// 录音状态枚举 - 使用AudioRecorder中定义的枚举

void main() {
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssistX - 全天录音助手',
      theme: AppTheme.createTheme(),
      darkTheme: AppTheme.createTheme(isDarkMode: true),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final AudioRecorder _recorder;
  RecordingStatus _status = RecordingStatus.idle;
  int _duration = 0;
  Timer? _durationTimer;
  bool _isMounted = false;
  StreamSubscription<RecordingStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _recorder = AudioRecorder();
    
    // 监听录音状态变化
    _statusSubscription = _recorder.statusStream.listen((status) {
        if (_isMounted) {
          setState(() {
            _status = status;
          });
        }
      });
  }

  @override
  void dispose() {
    _isMounted = false;
    _statusSubscription?.cancel();
    _durationTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _handleRecordingAction() async {
    try {
      switch (_status) {
        case RecordingStatus.idle:
        case RecordingStatus.completed:
          // 请求权限
          final hasPermission = await _recorder.requestPermission();
          if (!hasPermission) {
            _showPermissionDeniedDialog();
            return;
          }
          await _recorder.startRecording();
          _showSnackBar('开始录音');
          _startDurationTimer();
          break;
        case RecordingStatus.recording:
          await _recorder.pauseRecording();
          _showSnackBar('暂停录音');
          _durationTimer?.cancel();
          break;
        case RecordingStatus.paused:
          await _recorder.startRecording(); // 恢复录音
          _showSnackBar('恢复录音');
          _startDurationTimer();
          break;
        default:
          break;
      }
    } catch (e) {
      _showSnackBar('操作失败: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    if (_status == RecordingStatus.recording || _status == RecordingStatus.paused) {
      try {
        _durationTimer?.cancel();
        final data = await _recorder.stopRecording();
        _showSnackBar('录音已保存: ${_formatDuration(data.duration)}');
        // 重置时长
        if (_isMounted) {
          setState(() {
            _duration = 0;
          });
        }
      } catch (e) {
        _showSnackBar('停止录音失败: ${e.toString()}');
      }
    }
  }

  void _showPermissionDeniedDialog() {
    if (!_isMounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('录音权限被拒绝'),
        content: const Text('请在设备设置中允许应用访问麦克风权限'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // 这里可以添加打开系统设置的逻辑
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!_isMounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted && Navigator.canPop(context)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (!_isMounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _duration += 1000;
        });
      },
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    String statusText;
    Color statusColor;

    switch (_status) {
      case RecordingStatus.recording:
        statusText = '🎤 正在录音';
        statusColor = Theme.of(context).colorScheme.error;
        break;
      case RecordingStatus.paused:
        statusText = '⏸️ 已暂停';
        statusColor = MediaQuery.of(context).platformBrightness == Brightness.light
            ? const Color(0xFFF59E0B)
            : const Color(0xFFFBBF24);
        break;
      case RecordingStatus.completed:
        statusText = '✅ 录音完成';
        statusColor = Theme.of(context).colorScheme.primary;
        break;
      default:
        statusText = '准备录音';
        statusColor = Theme.of(context).colorScheme.onSurface;
    }

    return Container(
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 26), // 0.1 * 255 = 26
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        padding: AppTheme.paddingM,
        child: ResponsiveText(
          text: statusText,
        mobileStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ) ?? const TextStyle(),
        tabletStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ) ?? const TextStyle(),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusIndicator(context),
        const SizedBox(height: 32),
        Text(
          _formatDuration(_duration),
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 48),
        Column(
          children: [
            ElevatedButton.icon(
              label: Text(
                _status == RecordingStatus.recording
                    ? '暂停'
                    : _status == RecordingStatus.paused
                        ? '继续'
                        : '开始录音',
                style: const TextStyle(fontSize: 18),
              ),
              icon: Icon(
                _status == RecordingStatus.recording
                    ? Icons.pause
                    : Icons.mic,
                size: 32,
              ),
              onPressed: _handleRecordingAction,
              style: ElevatedButton.styleFrom(
                padding: AppTheme.paddingL,
                minimumSize: const Size(200, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_status == RecordingStatus.recording || _status == RecordingStatus.paused)
              TextButton(
                onPressed: _stopRecording,
                style: TextButton.styleFrom(
                  padding: AppTheme.paddingM,
                ),
                child: const Text('停止录音'),
              ),
          ],
        ),
        const SizedBox(height: 32),
        const Text('点击开始录音，再次点击暂停/继续', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusIndicator(context),
        const SizedBox(height: 48),
        Text(
          _formatDuration(_duration),
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 64),
        Column(
          children: [
            ElevatedButton.icon(
              label: Text(
                _status == RecordingStatus.recording
                    ? '暂停'
                    : _status == RecordingStatus.paused
                        ? '继续'
                        : '开始录音',
                style: const TextStyle(fontSize: 24),
              ),
              icon: Icon(
                _status == RecordingStatus.recording
                    ? Icons.pause
                    : Icons.mic,
                size: 40,
              ),
              onPressed: _handleRecordingAction,
              style: ElevatedButton.styleFrom(
                padding: AppTheme.paddingXL,
                minimumSize: const Size(250, 80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_status == RecordingStatus.recording || _status == RecordingStatus.paused)
              TextButton(
                onPressed: _stopRecording,
                style: TextButton.styleFrom(
                  padding: AppTheme.paddingM,
                ),
                child: const Text('停止录音', style: TextStyle(fontSize: 18)),
              ),
          ],
        ),
        const SizedBox(height: 48),
        const Text('点击开始录音，再次点击暂停/继续', style: TextStyle(color: Colors.grey, fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AssistX - 全天录音助手'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ResponsiveLayout(
        mobileLayout: _buildMobileLayout(context),
        tabletLayout: _buildTabletLayout(context),
        centered: true,
      ),
    );
  }
}
